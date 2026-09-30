import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_mock_data.dart';
import '../models/schedule_room.dart';

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

final currentUserProfileProvider = Provider<CurrentUserProfile>((ref) {
  return const CurrentUserProfile(
    uid: '하루',
    name: '하루',
    icon: '🐥',
    colorHex: '#DFE7FD',
  );
});

/// 모임(Room) 그룹 목록 및 실시간 상태 관리 Notifier
class ScheduleRoomListNotifier extends Notifier<List<ScheduleRoom>> {
  @override
  List<ScheduleRoom> build() => mockScheduleRooms;

  /// 8~10자리 보안 랜덤 초대코드 생성
  String _generateSecurityCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final buffer = StringBuffer('HC-');
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// 1. 새 모임 방 생성
  ScheduleRoom createRoom({
    required String name,
    String? description,
    String categoryTag = '모임',
    required RoomMember hostMember,
  }) {
    final roomId = 'room-${DateTime.now().microsecondsSinceEpoch}';
    final inviteCode = _generateSecurityCode();

    final newRoom = ScheduleRoom(
      id: roomId,
      name: name,
      inviteCode: inviteCode,
      description: description,
      categoryTag: categoryTag,
      members: [hostMember.copyWith(isHost: true)],
      dates: {},
      events: const [],
      notices: const [],
      votes: const [],
      rounds: const [],
    );

    state = [newRoom, ...state];
    return newRoom;
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

  /// 3. 멤버 식별 컬러 & 이모티콘 변경
  void updateMemberCustomization({
    required String roomId,
    required String uid,
    String? name,
    String? icon,
    String? colorHex,
  }) {
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
                );
              }
              return m;
            }).toList(),
          )
        else
          room,
    ];
  }

  /// 4. 모임 공유 캘린더 일정 추가 / 삭제
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
  }

  /// 5. 공지사항 추가 / 핀 고정 / 삭제
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

  /// 6. 모임 투표 생성 및 참여
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
              if (v.id == voteId && !v.isClosed) {
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

  /// 7. 다차수 정산 저장
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

  /// 9. 날짜 확정
  void confirmDate(String roomId, String date) {
    state = [
      for (final room in state)
        if (room.id == roomId) room.copyWith(confirmedDate: date) else room,
    ];
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
