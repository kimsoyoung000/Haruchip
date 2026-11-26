import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/input_sanitizer.dart';
import '../../../services/storage/local_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../models/battle_tag_user.dart';

const String _kFriendSystemStoreKey = 'haruchip.friends.system.v1';

/// 오프라인/테스트 환경에서도 `닉네임#TAG` 검색 및 접두사 자동완성을 검증할 수 있는 기본 디렉토리
const List<BattleTagUser> kDiscoverableSampleUsers = [
  BattleTagUser(
    uid: 'user_soyoung_7f2k',
    nickname: '소영',
    tag: '7F2K',
    avatarIcon: 'simple_rabbit',
  ),
  BattleTagUser(
    uid: 'user_yong_9a4m',
    nickname: '용이',
    tag: '9A4M',
    avatarIcon: 'simple_bear',
  ),
  BattleTagUser(
    uid: 'user_minji_3c8p',
    nickname: '민지',
    tag: '3C8P',
    avatarIcon: 'simple_cat',
  ),
  BattleTagUser(
    uid: 'user_harubyeol_abcd',
    nickname: '하루별',
    tag: 'ABCD',
    avatarIcon: 'simple_chick',
  ),
  BattleTagUser(
    uid: 'user_harumaru_1234',
    nickname: '하루마루',
    tag: '1234',
    avatarIcon: 'simple_puppy',
  ),
  BattleTagUser(
    uid: 'user_haruko_5678',
    nickname: '하루코',
    tag: '5678',
    avatarIcon: 'simple_hamster',
  ),
];

/// 배틀태그(`닉네임#TAG`) 친구 관리 & 커플·군대·결혼 1:1 실시간 파트너 동기화 Notifier
class FriendSystemNotifier extends Notifier<FriendSystemState> {
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _partnerSubs = {};

  @override
  FriendSystemState build() {
    final store = ref.watch(localStoreProvider);
    final authUser = ref.watch(currentUserProvider);

    ref.onDispose(() {
      for (final sub in _partnerSubs.values) {
        sub.cancel();
      }
      _partnerSubs.clear();
    });

    listenSelf((_, next) {
      store.writeString(_kFriendSystemStoreKey, jsonEncode(next.toJson()));
    });

    final raw = store.readString(_kFriendSystemStoreKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final restored = FriendSystemState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        for (final entry in restored.partnerLinks.entries) {
          Future.microtask(
            () => _attachPartnerSyncStream(entry.key, entry.value.roomId),
          );
        }
        return restored;
      } catch (_) {}
    }

    final uid = authUser?.uid ?? 'local_user_self';
    final nickname = (authUser?.displayName != null &&
            authUser!.displayName!.trim().isNotEmpty)
        ? authUser.displayName!.trim()
        : '하루칩 여행자';

    final initialProfile = BattleTagUser(
      uid: uid,
      nickname: nickname,
      tag: generateBattleTag(),
      avatarIcon: 'simple_chick',
    );
    Future.microtask(() => _syncMyProfileToFirestore(initialProfile));

    return FriendSystemState(myProfile: initialProfile);
  }

  /// 내 닉네임 / 4자리 태그 / 아바타 / 사진 수정 (`users/{uid}` 즉시 상태 갱신 + 동기화)
  bool updateMyProfile({
    String? nickname,
    String? tag,
    String? avatarIcon,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    final nextNick =
        nickname != null && nickname.trim().isNotEmpty
            ? nickname.trim()
            : state.myProfile.nickname;
    var nextTag = state.myProfile.tag;
    if (tag != null && tag.trim().isNotEmpty) {
      final upper = tag.trim().toUpperCase();
      if (!isValidBattleTag(upper)) return false;
      nextTag = upper;
    }
    final updated = state.myProfile.copyWith(
      nickname: nextNick,
      tag: nextTag,
      avatarIcon: avatarIcon ?? state.myProfile.avatarIcon,
      photoUrl: photoUrl,
      clearPhotoUrl: clearPhotoUrl,
    );
    state = state.copyWith(myProfile: updated);
    _syncMyProfileToFirestore(updated);
    return true;
  }

  /// 닉네임 유효성(2~10자 + 금칙어/예약어 차단) + 글로벌 `fullHandle` 유니크 중복 검증 및 자동 난수 재생성
  Future<({bool ok, String? error, BattleTagUser? profile, bool tagRegenerated})>
      updateMyProfileValidated({
    required String nickname,
    String? tag,
    String? avatarIcon,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) async {
    final trimmedNick = HaruInputSanitizer.sanitizeText(nickname);
    final nickErr = HaruInputSanitizer.validateNickname(trimmedNick);
    if (nickErr != null) {
      return (ok: false, error: nickErr, profile: null, tagRegenerated: false);
    }

    var candidateTag = (tag != null && tag.trim().isNotEmpty)
        ? tag.trim().toUpperCase()
        : state.myProfile.tag;
    if (!isValidBattleTag(candidateTag)) {
      return (
        ok: false,
        error: '영문 대문자 또는 숫자 4자리 태그를 입력해 주세요.',
        profile: null,
        tagRegenerated: false,
      );
    }

    // 글로벌 fullHandle 중복 사전 검증 — 충돌 시 자동으로 다른 4자리 난수 태그 재생성
    var regenerated = false;
    for (var attempt = 0; attempt < 12; attempt++) {
      final handle = '$trimmedNick#$candidateTag';
      final taken = await _isFullHandleTakenByOther(handle);
      if (!taken) break;
      candidateTag = generateBattleTag();
      regenerated = true;
    }

    final updated = state.myProfile.copyWith(
      nickname: trimmedNick,
      tag: candidateTag,
      avatarIcon: avatarIcon ?? state.myProfile.avatarIcon,
      photoUrl: photoUrl,
      clearPhotoUrl: clearPhotoUrl,
    );

    // Riverpod 상태 즉시 강제 갱신 + Firestore users/{uid} 반영
    state = state.copyWith(myProfile: updated);
    await _syncMyProfileToFirestore(updated);

    return (
      ok: true,
      error: null,
      profile: updated,
      tagRegenerated: regenerated,
    );
  }

  Future<bool> _isFullHandleTakenByOther(String fullHandle) async {
    final lower = fullHandle.toLowerCase();
    // 1) 로컬 디렉토리 중복 검사
    for (final u in kDiscoverableSampleUsers) {
      if (u.uid != state.myProfile.uid &&
          u.fullHandle.toLowerCase() == lower) {
        return true;
      }
    }
    // 2) Firestore `users` 컬렉션 글로벌 fullHandle 유니크 검사
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('fullHandle', isEqualTo: fullHandle)
          .limit(2)
          .get();
      for (final doc in snap.docs) {
        if (doc.id != state.myProfile.uid) {
          return true;
        }
      }
    } catch (_) {
      // 오프라인/테스트 환경에서는 로컬 검사 결과만 사용
    }
    return false;
  }

  /// 친구별 로컬 별명(별칭) 설정 (빈 값 전달 시 별명 해제)
  void setFriendAlias(String uid, String? rawAlias) {
    final next = Map<String, String>.from(state.friendAliases);
    final cleaned =
        rawAlias != null ? HaruInputSanitizer.sanitizeText(rawAlias) : '';
    if (cleaned.isEmpty) {
      next.remove(uid);
    } else {
      next[uid] = cleaned;
    }
    state = state.copyWith(friendAliases: next);
  }

  /// 친구 검색 실시간 자동완성 추천 (최소 2글자 이상, 접두사·태그 포함 일치 상위 4명)
  Future<List<BattleTagUser>> suggestUsersByPrefix(
    String rawQuery, {
    int limit = 4,
  }) async {
    final cleaned = HaruInputSanitizer.normalizeBattleTag(rawQuery);
    final compact = cleaned.replaceAll(' ', '');
    if (compact.length < 2) return const [];

    final queryLower = cleaned.toLowerCase();
    final hasHash = queryLower.contains('#');
    final nickPrefix = hasHash ? queryLower.split('#').first : queryLower;
    final tagPrefix = hasHash ? queryLower.split('#').last : '';

    final pool = <String, BattleTagUser>{};

    // 1) 로컬 디렉토리 + 현재 친구 목록 수집
    for (final u in [...kDiscoverableSampleUsers, ...state.friends]) {
      if (u.uid == state.myProfile.uid || state.isBlocked(u.uid)) continue;
      pool[u.uid] = u;
    }

    // 2) Firestore `users` 접두사 쿼리 (온라인 환경)
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: nickPrefix)
          .where('nickname', isLessThan: '$nickPrefix\uf8ff')
          .limit(12)
          .get();
      for (final doc in snap.docs) {
        if (doc.id == state.myProfile.uid || state.isBlocked(doc.id)) continue;
        final user = BattleTagUser.fromJson({...doc.data(), 'uid': doc.id});
        pool[user.uid] = user;
      }
    } catch (_) {}

    bool matches(BattleTagUser u) {
      final nLower = u.nickname.toLowerCase();
      final tLower = u.tag.toLowerCase();
      final hLower = u.fullHandle.toLowerCase();
      if (hasHash) {
        return nLower.startsWith(nickPrefix) &&
            (tagPrefix.isEmpty || tLower.startsWith(tagPrefix));
      }
      return nLower.startsWith(queryLower) || hLower.startsWith(queryLower);
    }

    final matched = pool.values.where(matches).toList()
      ..sort((a, b) {
        final aExact = a.fullHandle.toLowerCase() == queryLower ? 0 : 1;
        final bExact = b.fullHandle.toLowerCase() == queryLower ? 0 : 1;
        if (aExact != bExact) return aExact.compareTo(bExact);
        return a.fullHandle.compareTo(b.fullHandle);
      });

    return matched.take(limit).toList();
  }

  /// `닉네임#태그` 정확 일치 검색 (공백 자동 정규화 + 인젝션 차단 + Firestore `users` 조회 + 로컬 디렉토리 폴백)
  Future<BattleTagUser?> searchByFullHandle(String rawQuery) async {
    final normalizedHandle = HaruInputSanitizer.normalizeBattleTag(rawQuery);
    if (normalizedHandle.isEmpty || !normalizedHandle.contains('#')) {
      return null;
    }

    if (normalizedHandle == state.myProfile.fullHandle) return null;

    // 1) Firestore `users` 컬렉션에서 `fullHandle` 유니크 인덱스 조회
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('fullHandle', isEqualTo: normalizedHandle)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final found = BattleTagUser.fromJson({
          ...data,
          'uid': snap.docs.first.id,
        });
        if (!state.isBlocked(found.uid)) return found;
      }
    } catch (_) {
      // 오프라인/테스트 환경 폴백
    }

    // 2) 로컬 검색 가능 디렉토리 폴백
    for (final candidate in kDiscoverableSampleUsers) {
      if (candidate.fullHandle.toLowerCase() == normalizedHandle.toLowerCase() &&
          !state.isBlocked(candidate.uid)) {
        return candidate;
      }
    }
    return null;
  }

  /// 친구 요청 전송
  Future<void> sendFriendRequest(BattleTagUser target) async {
    if (target.uid == state.myProfile.uid) return;
    if (state.isFriend(target.uid) || state.isBlocked(target.uid)) return;

    state = state.copyWith(
      sentRequestUids: {...state.sentRequestUids, target.uid},
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(target.uid)
          .collection('friend_requests')
          .doc(state.myProfile.uid)
          .set({
        'id': state.myProfile.uid,
        'fromUser': state.myProfile.toJson(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// 받은 친구 요청 추가 (실시간 수신 또는 테스트용)
  void receiveFriendRequest(FriendRequestItem request) {
    if (state.isBlocked(request.fromUser.uid) ||
        state.isFriend(request.fromUser.uid)) {
      return;
    }
    if (state.incomingRequests.any((r) => r.id == request.id)) return;
    state = state.copyWith(
      incomingRequests: [...state.incomingRequests, request],
    );
  }

  /// 친구 요청 수락
  void acceptFriendRequest(String requestId) {
    final idx = state.incomingRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final req = state.incomingRequests[idx];
    final nextRequests =
        state.incomingRequests.where((r) => r.id != requestId).toList();
    final nextFriends = state.isFriend(req.fromUser.uid)
        ? state.friends
        : [...state.friends, req.fromUser];
    state = state.copyWith(
      incomingRequests: nextRequests,
      friends: nextFriends,
    );
  }

  /// 친구 요청 거절
  void rejectFriendRequest(String requestId) {
    state = state.copyWith(
      incomingRequests:
          state.incomingRequests.where((r) => r.id != requestId).toList(),
    );
  }

  /// 친구 삭제 (연결된 카테고리 파트너 링크도 함께 해제)
  void removeFriend(String uid) {
    final nextFriends = state.friends.where((f) => f.uid != uid).toList();
    final nextLinks = Map<String, CategoryPartnerLink>.from(state.partnerLinks)
      ..removeWhere((_, link) => link.partner.uid == uid);
    state = state.copyWith(
      friends: nextFriends,
      partnerLinks: nextLinks,
    );
  }

  /// 유저 차단 (친구/요청 목록에서 제거 후 차단 목록으로 이동)
  void blockUser(BattleTagUser user) {
    final nextFriends = state.friends.where((f) => f.uid != user.uid).toList();
    final nextRequests = state.incomingRequests
        .where((r) => r.fromUser.uid != user.uid)
        .toList();
    final nextBlocked = state.isBlocked(user.uid)
        ? state.blockedUsers
        : [...state.blockedUsers, user];
    final nextLinks = Map<String, CategoryPartnerLink>.from(state.partnerLinks)
      ..removeWhere((_, link) => link.partner.uid == user.uid);
    state = state.copyWith(
      friends: nextFriends,
      incomingRequests: nextRequests,
      blockedUsers: nextBlocked,
      partnerLinks: nextLinks,
    );
  }

  /// 차단 해제
  void unblockUser(String uid) {
    state = state.copyWith(
      blockedUsers: state.blockedUsers.where((b) => b.uid != uid).toList(),
    );
  }

  /// 커플·군대·결혼 카테고리 1:1 파트너 연결 & 양측 `partnerUid` 상호 등록 + 실시간 동기화
  Future<void> connectCategoryPartner({
    required String categoryKey,
    required BattleTagUser partner,
  }) async {
    final uids = [state.myProfile.uid, partner.uid]..sort();
    final roomId = '${categoryKey}_${uids.join('_')}';
    final link = CategoryPartnerLink(
      categoryKey: categoryKey,
      partner: partner,
      roomId: roomId,
      connectedAt: DateTime.now(),
    );

    final nextLinks = Map<String, CategoryPartnerLink>.from(state.partnerLinks)
      ..[categoryKey] = link;
    state = state.copyWith(partnerLinks: nextLinks);

    // 로컬 카테고리 문서에 `partnerUid` 저장
    _updateCategoryPartnerMetadata(
      categoryKey: categoryKey,
      partnerUid: partner.uid,
      partnerRoomId: roomId,
    );

    // Firestore 공유 방 문서 생성/동기화
    try {
      await FirebaseFirestore.instance
          .collection('category_partner_rooms')
          .doc(roomId)
          .set({
        'categoryKey': categoryKey,
        'memberUids': uids,
        'partnerUid': partner.uid,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}

    _attachPartnerSyncStream(categoryKey, roomId);
  }

  /// 카테고리 파트너 연결 해제
  void disconnectCategoryPartner(String categoryKey) {
    _partnerSubs[categoryKey]?.cancel();
    _partnerSubs.remove(categoryKey);

    final nextLinks = Map<String, CategoryPartnerLink>.from(state.partnerLinks)
      ..remove(categoryKey);
    state = state.copyWith(partnerLinks: nextLinks);

    _updateCategoryPartnerMetadata(
      categoryKey: categoryKey,
      partnerUid: null,
      partnerRoomId: null,
    );
  }

  void _updateCategoryPartnerMetadata({
    required String categoryKey,
    required String? partnerUid,
    required String? partnerRoomId,
  }) {
    try {
      final categories = ref.read(categoryListProvider);
      final matching =
          categories.where((c) => c.categoryKey == categoryKey).toList();

      // 상대방 수락 시 해당 카테고리(커플/군대/웨딩)가 대시보드에 없으면 자동 생성
      if (matching.isEmpty && partnerUid != null) {
        final (name, emoji, colorHex) = switch (categoryKey) {
          'couple' => ('커플', 'simple_heart', '#FF8DA1'),
          'military' => ('군대 (곰신)', 'simple_medal', '#A3E635'),
          'wedding' => ('결혼 준비', 'simple_ring', '#FDA4AF'),
          _ => ('공유 카테고리', 'simple_star', '#FFE699'),
        };
        final created = ref.read(categoryListProvider.notifier).addCategory(
              categoryKey: categoryKey,
              name: name,
              emoji: emoji,
              colorHex: colorHex,
            );
        ref.read(categoryListProvider.notifier).updateCategory(
              created.copyWith(
                metadata: {
                  'isInitialized': true,
                  'partnerUid': partnerUid,
                  'partnerRoomId': partnerRoomId,
                  'coEditors': [state.myProfile.uid, partnerUid],
                },
              ),
            );
        return;
      }

      for (final cat in matching) {
        final meta = Map<String, dynamic>.from(cat.metadata ?? {});
        if (partnerUid == null) {
          meta.remove('partnerUid');
          meta.remove('partnerRoomId');
          meta.remove('coEditors');
        } else {
          meta['partnerUid'] = partnerUid;
          meta['partnerRoomId'] = partnerRoomId;
          meta['coEditors'] = [state.myProfile.uid, partnerUid];
        }
        ref
            .read(categoryListProvider.notifier)
            .updateCategory(cat.copyWith(metadata: meta));
      }
    } catch (_) {}
  }

  /// 양측 공동 작업자(Co-Editor) 변경 사항을 Firestore 공유 방으로 즉시 푸시
  Future<void> pushSharedCategoryUpdate({
    required String categoryKey,
    required Map<String, dynamic> sharedMetadata,
  }) async {
    final link = state.partnerFor(categoryKey);
    if (link == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('category_partner_rooms')
          .doc(link.roomId)
          .set({
        'sharedMetadata': sharedMetadata,
        'updatedBy': state.myProfile.uid,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _syncMyProfileToFirestore(BattleTagUser profile) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  void _attachPartnerSyncStream(String categoryKey, String roomId) {
    _partnerSubs[categoryKey]?.cancel();
    try {
      _partnerSubs[categoryKey] = FirebaseFirestore.instance
          .collection('category_partner_rooms')
          .doc(roomId)
          .snapshots()
          .listen((snapshot) {
        final data = snapshot.data();
        if (data == null) return;
        final remoteMeta = data['sharedMetadata'];
        if (remoteMeta is Map) {
          try {
            final categories = ref.read(categoryListProvider);
            for (final cat in categories) {
              if (cat.categoryKey == categoryKey) {
                final merged = Map<String, dynamic>.from(cat.metadata ?? {})
                  ..addAll(Map<String, dynamic>.from(remoteMeta));
                ref
                    .read(categoryListProvider.notifier)
                    .updateCategory(cat.copyWith(metadata: merged));
              }
            }
          } catch (_) {}
        }
      }, onError: (_) {});
    } catch (_) {}
  }
}

final friendSystemProvider =
    NotifierProvider<FriendSystemNotifier, FriendSystemState>(
  FriendSystemNotifier.new,
);

/// Firestore `users/{uid}` 실시간 문서 구독 스트림 (오프라인/테스트 환경에서는 안전 폴백)
Stream<DocumentSnapshot<Map<String, dynamic>>>? watchUserProfileDocument(
  String uid,
) {
  if (uid.isEmpty || uid == 'local_user_self') return null;
  try {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  } catch (_) {
    return null;
  }
}
