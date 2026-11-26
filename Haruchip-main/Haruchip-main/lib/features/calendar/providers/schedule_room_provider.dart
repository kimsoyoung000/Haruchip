import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseException, FirebaseFirestore, SetOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/input_sanitizer.dart';
import '../../friends/models/battle_tag_user.dart';
import '../../friends/providers/friend_system_provider.dart';
import '../data/calendar_mock_data.dart';
import '../data/room_remote.dart';
import '../models/schedule_room.dart';

/// 받은 모임 초대 목록 (100% 친구 초대 수락 방식)
final pendingRoomInvitationsProvider =
    StateProvider<List<RoomInvitation>>((ref) => const []);

/// 내 고유 사용자 ID 코드 (로그인 시 자동 발급되는 영문+숫자 프로필 코드)
final myUserCodeProvider = Provider<String>((ref) => 'HC-7X9B2K');

/// 현재 사용자 기본 프로필 정보
class CurrentUserProfile {
  const CurrentUserProfile({
    required this.uid,
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  final String uid;
  final String name;
  final String icon;
  final String colorHex;
}

/// 로그인돼 있으면 Firebase 계정 uid + friendSystemProvider 최신 닉네임/아바타를 실시간 반영
final currentUserProfileProvider = Provider<CurrentUserProfile>((ref) {
  final user = ref.watch(roomAuthUserProvider).valueOrNull;
  final myBattleProfile = ref.watch(
    friendSystemProvider.select((s) => s.myProfile),
  );
  if (user != null) {
    return CurrentUserProfile(
      uid: user.uid,
      name: myBattleProfile.nickname.isNotEmpty
          ? myBattleProfile.nickname
          : user.displayName,
      icon: myBattleProfile.avatarIcon,
      colorHex: '#DFE7FD',
    );
  }
  return CurrentUserProfile(
    uid: '하루',
    name: myBattleProfile.nickname.isNotEmpty
        ? myBattleProfile.nickname
        : '하루',
    icon: myBattleProfile.avatarIcon,
    colorHex: '#DFE7FD',
  );
});

/// 모임(Room) 그룹 목록 및 실시간 상태 관리 Notifier
class ScheduleRoomListNotifier extends Notifier<List<ScheduleRoom>> {
  /// Firestore 동기화가 켜져 있고(앱) 로그인돼 있으면 내 방들을 실시간 구독한다.
  /// 그 외(테스트·로그인 전)에는 기존처럼 목업 데이터로 기기 안에서만 동작한다.
  @override
  List<ScheduleRoom> build() {
    final remote = ref.watch(roomRemoteProvider);
    if (remote == null) return mockScheduleRooms;
    final user = ref.watch(roomAuthUserProvider).valueOrNull;
    if (user == null) return const [];

    final sub = remote.watchMyRooms(user.uid).listen(
      (remoteRooms) => state = [for (final r in remoteRooms) _keepLocalOnly(r)],
      onError: (Object e) => _reportError(e),
    );
    ref.onDispose(sub.cancel);
    return const [];
  }

  /// 공지·투표·정산은 아직 서버에 없다 — 같은 방의 기기 로컬 값을 유지한다.
  ScheduleRoom _keepLocalOnly(ScheduleRoom remoteRoom) {
    final local = state.where((r) => r.id == remoteRoom.id);
    if (local.isEmpty) return remoteRoom;
    final l = local.first;
    return remoteRoom.copyWith(
      notices: l.notices,
      votes: l.votes,
      rounds: l.rounds,
      settlementHistory: l.settlementHistory,
      payments: l.payments,
      settlementConfirmedAt: l.settlementConfirmedAt,
    );
  }

  /// 원격 동기화 대상이면 (remote, 로그인 사용자) — 아니면 null.
  ({FirestoreRoomRemote remote, RoomUser user})? get _sync {
    final remote = ref.read(roomRemoteProvider);
    final user = remote == null ? null : ref.read(roomAuthUserProvider).valueOrNull;
    return (remote == null || user == null) ? null : (remote: remote, user: user);
  }

  void _reportError(Object e) {
    final msg = e is FirebaseException && e.code == 'permission-denied'
        ? '권한이 없어 저장하지 못했어요 (보안 규칙을 확인해주세요)'
        : '서버와 동기화하지 못했어요: $e';
    ref.read(roomSyncErrorProvider.notifier).state = msg;
  }

  /// 원격 쓰기 — 화면은 즉시(낙관적) 반영하고, 실패하면 오류를 알린다.
  void _push(Future<void> Function() write) {
    write().catchError((Object e) => _reportError(e));
  }

  /// 방 만들기 (화면용). 원격이면 Firestore에 만들고, 아니면 기존 [createRoom].
  Future<ScheduleRoom> createRoomSynced({
    required String name,
    String? description,
    String categoryTag = '모임',
    required RoomMember hostMember,
  }) async {
    final s = _sync;
    if (s == null) {
      return createRoom(name: name, description: description, categoryTag: categoryTag, hostMember: hostMember);
    }
    final room = await s.remote.createRoom(
      user: s.user,
      name: name,
      description: description,
      categoryTag: categoryTag,
      host: hostMember,
    );
    if (!state.any((r) => r.id == room.id)) state = [room, ...state];
    return room;
  }

  /// 초대코드로 참가 (화면용).
  Future<JoinRoomResult> joinRoomSynced(String inviteCode, RoomMember member) async {
    final s = _sync;
    if (s == null) {
      return joinRoomWithCode(inviteCode, member) ? JoinRoomResult.joined : JoinRoomResult.notFound;
    }
    return s.remote.joinWithCode(user: s.user, rawCode: inviteCode, me: member);
  }

  /// 암호학적 난수(CSPRNG) 기반 보안 모임 초대 코드 생성
  String _generateSecurityCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final buffer = StringBuffer('HC-');
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// 1. 새 모임 방 생성 (CSPRNG + SHA-256 내부 groupId 및 입력 살균 적용)
  ScheduleRoom createRoom({
    required String name,
    String? description,
    String categoryTag = '모임',
    required RoomMember hostMember,
  }) {
    final roomId = HaruInputSanitizer.generateSecureGroupId();
    final inviteCode = _generateSecurityCode();
    final safeName = HaruInputSanitizer.sanitizeText(name);
    final safeDesc = description != null
        ? HaruInputSanitizer.sanitizeText(description)
        : null;
    final safeTag = HaruInputSanitizer.sanitizeText(categoryTag);

    final newRoom = ScheduleRoom(
      id: roomId,
      name: safeName.isNotEmpty ? safeName : '새 모임',
      inviteCode: inviteCode,
      description: safeDesc,
      categoryTag: safeTag.isNotEmpty ? safeTag : '모임',
      members: [hostMember.copyWith(isHost: true)],
      dates: {},
      events: const [],
      notices: const [],
      votes: const [],
      rounds: const [],
      settlementHistory: const [],
    );

    state = [newRoom, ...state];
    return newRoom;
  }

  /// 부방장 지정 / 해제 (방장 전용)
  void toggleCoHost(String roomId, String targetUid) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            members: [
              for (final m in room.members)
                if (m.uid == targetUid && !m.isHost)
                  m.copyWith(isCoHost: !m.isCoHost)
                else
                  m,
            ],
          )
        else
          room,
    ];
  }

  /// 방장 권한 위임
  void delegateHost(String roomId, String newHostUid) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            members: [
              for (final m in room.members)
                if (m.uid == newHostUid)
                  m.copyWith(isHost: true, isCoHost: false)
                else if (m.isHost)
                  m.copyWith(isHost: false)
                else
                  m,
            ],
          )
        else
          room,
    ];
  }

  /// 멤버 내보내기 (강퇴)
  void kickMember(String roomId, String targetUid) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            members: room.members
                .where((m) => m.uid != targetUid || m.isHost)
                .toList(),
          )
        else
          room,
    ];
  }

  /// 친구 목록에서 다중 선택하여 모임에 초대 (즉시 멤버 합류)
  void inviteFriendsToRoom(String roomId, List<BattleTagUser> friends) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          () {
            final existingUids = room.members.map((m) => m.uid).toSet();
            final takenColors =
                room.members.map((m) => m.colorHex.toUpperCase()).toSet();
            final added = <RoomMember>[];
            for (final f in friends) {
              if (existingUids.contains(f.uid)) continue;
              final assignedColor = kPreset50PastelColors.firstWhere(
                (c) => !takenColors.contains(c.toUpperCase()),
                orElse: () => kPreset50PastelColors.first,
              );
              takenColors.add(assignedColor.toUpperCase());
              added.add(
                RoomMember(
                  uid: f.uid,
                  name: f.nickname,
                  icon: f.avatarIcon,
                  colorHex: assignedColor,
                ),
              );
            }
            return room.copyWith(members: [...room.members, ...added]);
          }()
        else
          room,
    ];
  }

  /// 모임 나가기 (방장이면서 다른 멤버가 남아 있으면 위임이 필요하므로 false 반환)
  bool leaveRoom(String roomId, String myUid) {
    final idx = state.indexWhere((r) => r.id == roomId);
    if (idx < 0) return false;
    final room = state[idx];
    final me = room.members.where((m) => m.uid == myUid).firstOrNull;
    if (me != null && me.isHost && room.members.length > 1) {
      return false; // 방장 위임 선행 필요
    }
    state = state.where((r) => r.id != roomId).toList();
    return true;
  }

  /// 모임 영구 삭제 (방장/부방장 전용)
  void deleteRoom(String roomId) {
    state = state.where((r) => r.id != roomId).toList();
  }

  /// 받은 모임 초대 수락 -> 모임 방 합류
  void acceptRoomInvitation(RoomInvitation invite, RoomMember me) {
    final exists = state.any((r) => r.id == invite.roomId);
    if (!exists) {
      final joined = ScheduleRoom(
        id: invite.roomId,
        name: invite.roomName,
        inviteCode: _generateSecurityCode(),
        categoryTag: invite.categoryTag,
        members: [
          RoomMember(
            uid: 'host_${invite.roomId}',
            name: invite.inviterName,
            icon: 'simple_bear',
            isHost: true,
          ),
          me.copyWith(isHost: false),
        ],
        dates: const {},
        events: const [],
        notices: const [],
        votes: const [],
        rounds: const [],
        settlementHistory: const [],
      );
      state = [joined, ...state];
    }
    ref.read(pendingRoomInvitationsProvider.notifier).state = ref
        .read(pendingRoomInvitationsProvider)
        .where((i) => i.id != invite.id)
        .toList();
  }

  /// 2. 초대 코드로 모임 방 참가
  bool joinRoomWithCode(String inviteCode, RoomMember member) {
    final trimmed = inviteCode.trim().toUpperCase();
    final index = state.indexWhere((r) => r.inviteCode.toUpperCase() == trimmed);
    if (index == -1) return false;

    final room = state[index];
    if (room.members.any((m) => m.uid == member.uid)) {
      return true; // Already joined
    }

    // 이미 선점된 색상인지 체크 후 자동 대체
    final takenColors = room.members.map((m) => m.colorHex.toUpperCase()).toSet();
    String assignedColor = member.colorHex;
    if (takenColors.contains(assignedColor.toUpperCase())) {
      final available = kPreset50PastelColors.where((c) => !takenColors.contains(c.toUpperCase())).toList();
      if (available.isNotEmpty) {
        assignedColor = available.first;
      }
    }

    final updatedRoom = room.copyWith(
      members: [...room.members, member.copyWith(colorHex: assignedColor, isHost: false)],
    );

    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) updatedRoom else state[i],
    ];
    return true;
  }

  /// 3. 멤버 식별 컬러 & 모임 전용 프로필/사진 변경 (1인 1색 중복 선택 방어 포함)
  /// 다른 멤버가 이미 선점한 컬러를 지정하면 false를 반환하고 변경을 차단한다.
  bool updateMemberCustomization({
    required String roomId,
    required String uid,
    String? name,
    String? icon,
    String? colorHex,
    bool? usesCustomProfile,
    String? customPhotoUrl,
    bool clearCustomPhotoUrl = false,
  }) {
    final targetRoom = state.where((r) => r.id == roomId).firstOrNull;
    if (targetRoom == null) return false;

    // 1인 1색 중복 선점 방어
    if (colorHex != null) {
      final upperColor = colorHex.toUpperCase();
      final takenByOther = targetRoom.members.any(
        (m) => m.uid != uid && m.colorHex.toUpperCase() == upperColor,
      );
      if (takenByOther) return false;
    }

    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            members: room.members.map((m) {
              if (m.uid == uid) {
                return m.copyWith(
                  name: name ?? m.name,
                  icon: icon ?? m.icon,
                  colorHex: colorHex ?? m.colorHex,
                  usesCustomProfile: usesCustomProfile ?? m.usesCustomProfile,
                  customPhotoUrl: customPhotoUrl,
                  clearCustomPhotoUrl: clearCustomPhotoUrl,
                );
              }
              return m;
            }).toList(),
          )
        else
          room,
    ];
    final s = _sync;
    // 규칙상 본인 멤버 정보만 바꿀 수 있다.
    if (s != null && s.user.uid == uid) {
      _push(
        () => s.remote.updateMyMember(
          roomId: roomId,
          uid: uid,
          name: name,
          icon: icon,
          colorHex: colorHex,
        ),
      );
    }
    return true;
  }

  /// 전역 기본 프로필(닉네임·아바타·사진) 변경 시 `usesCustomProfile == false`인 모든 모임 멤버 즉시 동기화
  void syncGlobalProfileToRooms({
    required String uid,
    required String name,
    required String icon,
    String? photoUrl,
  }) {
    state = [
      for (final room in state)
        room.copyWith(
          members: [
            for (final m in room.members)
              if (m.uid == uid && !m.usesCustomProfile)
                m.copyWith(
                  name: name,
                  icon: icon,
                  customPhotoUrl: photoUrl,
                  clearCustomPhotoUrl: photoUrl == null || photoUrl.isEmpty,
                )
              else
                m,
          ],
        ),
    ];
  }

  /// 4. 모임 공유 캘린더 일정 추가 / 다중 모임방 동시 Batch 연동 / 삭제
  void addRoomEvent(String roomId, RoomSharedEvent event) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            events: [event, ...room.events],
          )
        else
          room,
    ];
    final s = _sync;
    if (s != null) _push(() => s.remote.addEvent(roomId: roomId, event: event));
  }

  /// 다중 모임방 동시 일정 연동 (로컬 상태 즉시 반영 + Firestore WriteBatch 원자적 동기화)
  Future<void> addRoomEventToMultipleRooms({
    required List<String> roomIds,
    required RoomSharedEvent baseEvent,
  }) async {
    final uniqueRoomIds = roomIds.where((id) => id.isNotEmpty).toSet();
    if (uniqueRoomIds.isEmpty) return;

    // 1) 로컬 상태 즉시 반영 (중복 id 방지)
    state = [
      for (final room in state)
        if (uniqueRoomIds.contains(room.id))
          room.copyWith(
            events: [
              baseEvent.copyWith(roomId: room.id),
              ...room.events.where((e) => e.id != baseEvent.id),
            ],
          )
        else
          room,
    ];

    // 2) 온라인 환경: Firestore WriteBatch 원자적 일괄 기록
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      for (final rid in uniqueRoomIds) {
        final ev = baseEvent.copyWith(roomId: rid);
        final docRef = db
            .collection('rooms')
            .doc(rid)
            .collection('events')
            .doc(ev.id);
        batch.set(docRef, ev.toJson());
      }
      await batch.commit();
    } catch (_) {
      // 오프라인/테스트 환경에서는 로컬 상태만 안전하게 유지
    }
  }

  void removeRoomEvent(String roomId, String eventId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            events: room.events.where((e) => e.id != eventId).toList(),
          )
        else
          room,
    ];
    final s = _sync;
    if (s != null) _push(() => s.remote.removeEvent(roomId: roomId, eventId: eventId));
  }

  /// 5. 공지사항 추가 / 핀 고정 / 수정 / 확인 체크 / 댓글 / 삭제
  void addRoomNotice(String roomId, RoomNotice notice) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            notices: [notice, ...room.notices],
          )
        else
          room,
    ];
  }

  void updateRoomNotice(String roomId, RoomNotice updatedNotice) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            notices: room.notices.map((n) => n.id == updatedNotice.id ? updatedNotice : n).toList(),
          )
        else
          room,
    ];
  }

  void togglePinNotice(String roomId, String noticeId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            notices: room.notices.map((n) {
              if (n.id == noticeId) {
                return n.copyWith(isPinned: !n.isPinned);
              }
              return n;
            }).toList(),
          )
        else
          room,
    ];
  }

  void toggleNoticeRead(String roomId, String noticeId, String memberUid) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            notices: room.notices.map((n) {
              if (n.id == noticeId) {
                final list = List<String>.from(n.confirmedMemberUids);
                if (list.contains(memberUid)) {
                  list.remove(memberUid);
                } else {
                  list.add(memberUid);
                }
                return n.copyWith(confirmedMemberUids: list);
              }
              return n;
            }).toList(),
          )
        else
          room,
    ];
  }

  void addNoticeComment(String roomId, String noticeId, NoticeComment comment) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            notices: room.notices.map((n) {
              if (n.id == noticeId) {
                return n.copyWith(comments: [...n.comments, comment]);
              }
              return n;
            }).toList(),
          )
        else
          room,
    ];
  }

  void deleteRoomNotice(String roomId, String noticeId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            notices: room.notices.where((n) => n.id != noticeId).toList(),
          )
        else
          room,
    ];
  }

  /// 6. 모임 투표 생성, 수정, 참여, 재투표, 마감, 삭제
  void createRoomVote(String roomId, RoomVote vote) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            votes: [vote, ...room.votes],
          )
        else
          room,
    ];
  }

  void updateRoomVote(String roomId, RoomVote updatedVote) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            votes: room.votes.map((v) => v.id == updatedVote.id ? updatedVote : v).toList(),
          )
        else
          room,
    ];
  }

  void closeRoomVote(String roomId, String voteId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            votes: room.votes.map((v) {
              if (v.id == voteId) {
                return v.copyWith(isClosed: true);
              }
              return v;
            }).toList(),
          )
        else
          room,
    ];
  }

  void reVote(String roomId, String voteId, String voterUid) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            votes: room.votes.map((v) {
              if (v.id == voteId && !v.isExpiredOrClosed) {
                final cleanedOptions = v.options.map((opt) {
                  final list = List<String>.from(opt.voterUids)..remove(voterUid);
                  return opt.copyWith(voterUids: list);
                }).toList();
                return v.copyWith(options: cleanedOptions);
              }
              return v;
            }).toList(),
          )
        else
          room,
    ];
  }

  void deleteRoomVote(String roomId, String voteId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            votes: room.votes.where((v) => v.id != voteId).toList(),
          )
        else
          room,
    ];
  }

  void castVote({
    required String roomId,
    required String voteId,
    required String optionId,
    required String voterUid,
  }) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            votes: room.votes.map((v) {
              if (v.id == voteId && !v.isExpiredOrClosed) {
                final updatedOptions = <VoteOption>[];
                for (final opt in v.options) {
                  final voters = List<String>.from(opt.voterUids);
                  if (opt.id == optionId) {
                    if (voters.contains(voterUid)) {
                      voters.remove(voterUid);
                    } else {
                      voters.add(voterUid);
                    }
                  } else if (!v.allowMultiple) {
                    voters.remove(voterUid);
                  }
                  updatedOptions.add(opt.copyWith(voterUids: voters));
                }
                return v.copyWith(options: updatedOptions);
              }
              return v;
            }).toList(),
          )
        else
          room,
    ];
  }

  /// 7. 정산 아카이브(누적 장부) 및 송금 상태 추적
  void addSettlementRecord(String roomId, SettlementRecord record) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            settlementHistory: [record, ...room.settlementHistory],
            rounds: record.rounds,
            settlementConfirmedAt: DateTime.now(),
          )
        else
          room,
    ];
  }

  void updateSettlementRecord(String roomId, SettlementRecord updatedRecord) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            settlementHistory: room.settlementHistory
                .map((r) => r.id == updatedRecord.id ? updatedRecord : r)
                .toList(),
          )
        else
          room,
    ];
  }

  void toggleTransferStatus(String roomId, String recordId, String memberUid) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            settlementHistory: room.settlementHistory.map((r) {
              if (r.id == recordId) {
                final map = Map<String, bool>.from(r.transferStatus);
                final current = map[memberUid] ?? false;
                map[memberUid] = !current;
                return r.copyWith(transferStatus: map);
              }
              return r;
            }).toList(),
          )
        else
          room,
    ];
  }

  void deleteSettlementRecord(String roomId, String recordId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            settlementHistory: room.settlementHistory.where((r) => r.id != recordId).toList(),
          )
        else
          room,
    ];
  }

  void restoreSettlementRecord(String roomId, SettlementRecord record) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            settlementHistory: [record, ...room.settlementHistory.where((r) => r.id != record.id)],
          )
        else
          room,
    ];
  }

  /// 과거 다차수 정산 호환용
  void saveMultiRoundSettlement(String roomId, List<SettlementRound> rounds) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            rounds: rounds,
            settlementConfirmedAt: DateTime.now(),
          )
        else
          room,
    ];
  }

  /// 8. 일정 조율 토글
  void toggleAvailability(String roomId, String date, String myUid) {
    state = [
      for (final room in state)
        if (room.id == roomId) _toggle(room, date, myUid) else room,
    ];
  }

  ScheduleRoom _toggle(ScheduleRoom room, String date, String myUid) {
    final updatedDates = <String, List<String>>{
      for (final entry in room.dates.entries)
        entry.key: List<String>.from(entry.value),
    };
    final members = updatedDates.putIfAbsent(date, () => []);
    if (members.contains(myUid)) {
      members.remove(myUid);
    } else {
      members.add(myUid);
    }
    return room.copyWith(dates: updatedDates);
  }

  /// 8-1. 내 가능 날짜를 한 번에 저장 ("저장하기" 버튼). [myDates]에 없는
  /// 날짜에서는 내 uid가 빠지고, 있는 날짜에는 들어간다.
  void setMyAvailability(String roomId, String myUid, Set<String> myDates) {
    state = [
      for (final room in state)
        if (room.id == roomId) _withMyDates(room, myUid, myDates) else room,
    ];
    final s = _sync;
    if (s != null) _push(() => s.remote.setMyAvailability(roomId: roomId, uid: myUid, dates: myDates));
  }

  ScheduleRoom _withMyDates(ScheduleRoom room, String myUid, Set<String> myDates) {
    final updated = <String, List<String>>{};
    for (final entry in room.dates.entries) {
      final uids = entry.value.where((u) => u != myUid).toList();
      if (uids.isNotEmpty) updated[entry.key] = uids;
    }
    for (final d in myDates) {
      updated.putIfAbsent(d, () => []).add(myUid);
    }
    return room.copyWith(dates: updated);
  }

  /// 9. 날짜 확정 (방장)
  void confirmDate(String roomId, String date) {
    state = [
      for (final room in state)
        if (room.id == roomId) room.copyWith(confirmedDate: date) else room,
    ];
    final s = _sync;
    if (s != null) _push(() => s.remote.confirmDate(roomId: roomId, date: date));
  }

  /// 9-1. 확정된 모임 일정에 댓글 달기
  void addMeetingComment(String roomId, NoticeComment comment) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(meetingComments: [...room.meetingComments, comment])
        else
          room,
    ];
    final s = _sync;
    if (s != null) _push(() => s.remote.addMeetingComment(roomId: roomId, comment: comment));
  }

  /// 기존 payments 갱신 및 확정
  void updatePayments(String roomId, Map<String, int> payments) {
    state = [
      for (final room in state)
        if (room.id == roomId) room.copyWith(payments: payments) else room,
    ];
  }

  void recordSettlementConfirmation(String roomId) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(settlementConfirmedAt: DateTime.now())
        else
          room,
    ];
  }

  /// 모임의 '공통 모임 대표 컬러' 갱신 (2인 이상 공통 참여 일정 및 확정 모임 일정 라벨에 적용)
  void updateRoomSharedEventColor({
    required String roomId,
    required String colorHex,
  }) {
    final normalized = colorHex.startsWith('#') ? colorHex : '#$colorHex';
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(sharedEventColorHex: normalized)
        else
          room,
    ];
    final s = _sync;
    if (s != null) {
      _push(() async {
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).set(
          {'sharedEventColorHex': normalized},
          SetOptions(merge: true),
        );
      });
    }
  }
}

final scheduleRoomsProvider =
    NotifierProvider<ScheduleRoomListNotifier, List<ScheduleRoom>>(
  ScheduleRoomListNotifier.new,
);

/// 최다 인원 가능일 계산 헬퍼
({String? date, int count}) bestDateFor(ScheduleRoom room) {
  String? bestDate;
  var bestCount = 0;
  final sortedDates = room.dates.keys.toList()..sort();
  for (final date in sortedDates) {
    final count = room.dates[date]!.length;
    if (count > bestCount) {
      bestCount = count;
      bestDate = date;
    }
  }
  return (date: bestDate, count: bestCount);
}
