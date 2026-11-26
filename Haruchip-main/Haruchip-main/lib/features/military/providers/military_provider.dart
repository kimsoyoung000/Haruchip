import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/local_store.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart'
    show dDayLabel, planItemsByCategoryProvider, planListProvider;
import '../data/military_mock_data.dart';
import '../models/military_rank.dart';
import '../models/military_service.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const String _kMilitaryStoreKey = 'haruchip.military.service.v2';
const String _kInviteChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateMilitaryInviteCode() {
  final rng = Random.secure();
  String part(int len) =>
      List.generate(len, (_) => _kInviteChars[rng.nextInt(_kInviteChars.length)])
          .join();
  return 'MIL-${part(4)}-${part(4)}';
}

/// 군대(곰신) 복무 정보 상태 — 로컬 영속화 + 출타/캘린더 연동 + 곰신 실시간 Firestore 양방향 동기화
class MilitaryServiceNotifier extends Notifier<MilitaryService> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _syncSub;
  bool _applyingRemote = false;

  @override
  MilitaryService build() {
    final store = ref.watch(localStoreProvider);
    ref.onDispose(() {
      _syncSub?.cancel();
      _syncSub = null;
    });

    listenSelf((_, next) {
      store.writeString(_kMilitaryStoreKey, jsonEncode(next.toJson()));
      if (!_applyingRemote) {
        _pushToSharedRoomIfConnected(next);
      }
    });

    final raw = store.readString(_kMilitaryStoreKey);
    MilitaryService initial = mockMilitaryService;
    if (raw != null && raw.isNotEmpty) {
      try {
        initial = MilitaryService.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {
        initial = mockMilitaryService;
      }
    }

    if (initial.connectedPartnerCode != null &&
        initial.connectedPartnerCode!.isNotEmpty) {
      Future.microtask(
        () => _attachFirestoreStream(initial.connectedPartnerCode!),
      );
    }

    return initial;
  }

  void setService({
    required DateTime enlistDate,
    required DateTime dischargeDate,
    MilitaryBranch? branch,
    int? totalVacationDays,
    int? usedVacationDays,
    String? soldierName,
    int? shortenedDays,
    int? totalRewardVacationDays,
  }) {
    state = state.copyWith(
      enlistDate: enlistDate,
      dischargeDate: dischargeDate,
      branch: branch,
      totalVacationDays: totalVacationDays,
      usedVacationDays: usedVacationDays,
      soldierName: soldierName,
      shortenedDays: shortenedDays,
      totalRewardVacationDays: totalRewardVacationDays,
    );
  }

  void setBranch(MilitaryBranch branch) {
    state = state.copyWith(branch: branch);
  }

  void setNextLeave(DateTime? date) {
    state = state.copyWith(
      nextLeaveDate: date,
      clearNextLeaveDate: date == null,
    );
  }

  void setVacationDays({required int total, required int used}) {
    state = state.copyWith(
      totalVacationDays: total,
      usedVacationDays: used,
    );
  }

  /// 출타(정기휴가·포상휴가·외박·외출·직접입력) 등록 + 칩 캘린더 연속 라벨 바 자동 연동
  void addLeave(MilitaryLeaveRecord record) {
    final updatedLeaves = [...state.leaves, record]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final nextUpcoming = _findNextUpcomingLeaveDate(updatedLeaves);
    state = state.copyWith(
      leaves: updatedLeaves,
      nextLeaveDate: nextUpcoming ?? state.nextLeaveDate,
    );
    _upsertLeaveToCalendar(record);
  }

  /// 출타 수정 + 칩 캘린더 동기화
  void updateLeave(MilitaryLeaveRecord record) {
    final updatedLeaves = state.leaves
        .map((l) => l.id == record.id ? record : l)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final nextUpcoming = _findNextUpcomingLeaveDate(updatedLeaves);
    state = state.copyWith(
      leaves: updatedLeaves,
      nextLeaveDate: nextUpcoming,
      clearNextLeaveDate: nextUpcoming == null,
    );
    _upsertLeaveToCalendar(record);
  }

  /// 출타 삭제 + 칩 캘린더 일정 제거
  void deleteLeave(String leaveId) {
    final updatedLeaves = state.leaves.where((l) => l.id != leaveId).toList();
    final nextUpcoming = _findNextUpcomingLeaveDate(updatedLeaves);
    state = state.copyWith(
      leaves: updatedLeaves,
      nextLeaveDate: nextUpcoming,
      clearNextLeaveDate: nextUpcoming == null,
    );
    try {
      ref.read(planListProvider.notifier).removeItem('mil-leave-$leaveId');
    } catch (_) {}
  }

  /// 내 난수 초대 코드 발급 (없으면 생성 후 저장)
  String ensureShareCode() {
    if (state.shareCode != null && state.shareCode!.isNotEmpty) {
      return state.shareCode!;
    }
    final code = generateMilitaryInviteCode();
    state = state.copyWith(shareCode: code);
    _pushToSharedRoom(code, state);
    return code;
  }

  /// 곰신-군인 공유 방 연결 (Firestore 실시간 Stream 양방향 바인딩)
  Future<void> connectPartnerRoom(String rawCode) async {
    final normalized = rawCode.trim().toUpperCase();
    if (normalized.isEmpty) return;
    state = state.copyWith(connectedPartnerCode: normalized);
    await _pushToSharedRoom(normalized, state);
    _attachFirestoreStream(normalized);
  }

  /// 곰신-군인 공유 연결 해제
  void disconnectPartnerRoom() {
    _syncSub?.cancel();
    _syncSub = null;
    state = state.copyWith(clearConnectedPartnerCode: true);
  }

  DateTime? _findNextUpcomingLeaveDate(List<MilitaryLeaveRecord> leaves) {
    final today = _dateOnly(DateTime.now());
    final upcoming = leaves
        .where((l) => !_dateOnly(l.endDate).isBefore(today))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.isNotEmpty ? upcoming.first.startDate : null;
  }

  void _upsertLeaveToCalendar(MilitaryLeaveRecord record) {
    try {
      final planId = 'mil-leave-${record.id}';
      final plan = PlanItem(
        id: planId,
        title: '${record.type.emoji} ${record.summaryLabel}',
        date: _dateOnly(record.startDate),
        endDate: _dateOnly(record.endDate),
        isAllDay: true,
        categoryKey: 'military',
        displayMode: DdayDisplayMode.dday,
      );
      final notifier = ref.read(planListProvider.notifier);
      final existing = ref
          .read(planListProvider)
          .any((item) => item.id == planId);
      if (existing) {
        notifier.updateItem(plan);
      } else {
        notifier.addItem(plan);
      }
    } catch (_) {
      // planListProvider 미초기화 환경에서도 안전 동작
    }
  }

  Future<void> _pushToSharedRoomIfConnected(MilitaryService data) async {
    final roomCode = data.connectedPartnerCode ?? data.shareCode;
    if (roomCode == null || roomCode.isEmpty) return;
    await _pushToSharedRoom(roomCode, data);
  }

  Future<void> _pushToSharedRoom(String roomCode, MilitaryService data) async {
    try {
      final payload = data.toJson();
      payload['updatedAt'] = DateTime.now().toIso8601String();
      await FirebaseFirestore.instance
          .collection('military_shared_rooms')
          .doc(roomCode)
          .set(payload, SetOptions(merge: true));
    } catch (_) {
      // 오프라인 또는 테스트 환경에서는 로컬 저장만 유지
    }
  }

  void _attachFirestoreStream(String roomCode) {
    _syncSub?.cancel();
    try {
      _syncSub = FirebaseFirestore.instance
          .collection('military_shared_rooms')
          .doc(roomCode)
          .snapshots()
          .listen((snapshot) {
        final data = snapshot.data();
        if (data == null) return;
        try {
          final remote = MilitaryService.fromJson(data);
          _applyingRemote = true;
          state = remote.copyWith(
            shareCode: state.shareCode ?? remote.shareCode,
            connectedPartnerCode: roomCode,
          );
          for (final leave in remote.leaves) {
            _upsertLeaveToCalendar(leave);
          }
        } catch (_) {
        } finally {
          _applyingRemote = false;
        }
      }, onError: (_) {});
    } catch (_) {
      // Firebase 미초기화 환경에서는 스트림 구독 생략
    }
  }
}

final militaryServiceProvider =
    NotifierProvider<MilitaryServiceNotifier, MilitaryService>(
  MilitaryServiceNotifier.new,
);

/// 진급 게이지 — §5.3 "(오늘-입대일)/(전역일-입대일)*100%". 전역일이
/// 지났거나 입대 전이어도 0.0~1.0 범위로 clamp한다.
final militaryProgressProvider = Provider<double>((ref) {
  final service = ref.watch(militaryServiceProvider);
  final enlist = _dateOnly(service.enlistDate);
  final discharge = _dateOnly(service.effectiveDischargeDate);
  final today = _dateOnly(DateTime.now());

  final totalDays = discharge.difference(enlist).inDays;
  if (totalDays <= 0) return 0;
  final elapsedDays = today.difference(enlist).inDays;
  return (elapsedDays / totalDays).clamp(0.0, 1.0);
});

/// 전역 D-day 라벨('D-n'/'D-day'/'D+n') — [dDayLabel] 재사용.
final militaryDischargeDdayProvider = Provider<String>((ref) {
  final service = ref.watch(militaryServiceProvider);
  return dDayLabel(service.effectiveDischargeDate);
});

/// 가장 가까운 다음 휴가 날짜(DateTime?) — 등록된 출타 리스트 + 군대 플랜 항목 + nextLeaveDate 통합
final militaryNextLeaveDateProvider = Provider<DateTime?>((ref) {
  final service = ref.watch(militaryServiceProvider);
  final militaryItems = ref.watch(planItemsByCategoryProvider('military'));
  final today = _dateOnly(DateTime.now());

  final upcomingDates = <DateTime>[];

  for (final leave in service.leaves) {
    final s = _dateOnly(leave.startDate);
    if (!s.isBefore(today)) {
      upcomingDates.add(s);
    }
  }

  for (final i in militaryItems) {
    final title = i.title.toLowerCase();
    final isLeave = title.contains('휴가') ||
        title.contains('외박') ||
        title.contains('외출') ||
        title.contains('포상') ||
        title.contains('정기');
    final itemDate = _dateOnly(i.date);
    if (isLeave && !itemDate.isBefore(today)) {
      upcomingDates.add(itemDate);
    }
  }

  if (service.nextLeaveDate != null &&
      !_dateOnly(service.nextLeaveDate!).isBefore(today)) {
    upcomingDates.add(_dateOnly(service.nextLeaveDate!));
  }

  if (upcomingDates.isNotEmpty) {
    upcomingDates.sort((a, b) => a.compareTo(b));
    return upcomingDates.first;
  }

  return service.nextLeaveDate;
});

/// 다음 휴가 D-day — 설정 안 했으면 null.
final militaryLeaveDdayProvider = Provider<String?>((ref) {
  final nextDate = ref.watch(militaryNextLeaveDateProvider);
  if (nextDate == null) return null;
  return dDayLabel(nextDate);
});

/// 잔여 정기휴가 일수
final militaryRemainingVacationDaysProvider = Provider<int>((ref) {
  final service = ref.watch(militaryServiceProvider);
  return service.remainingVacationDays;
});

/// 현재 계급 — §5.3 규정(이병→일병 2개월/상병 8개월/병장 14개월)을
/// [military_rank.dart]의 [currentRank]로 계산한다.
final militaryCurrentRankProvider = Provider<MilitaryRank>((ref) {
  final enlist = ref.watch(militaryServiceProvider).enlistDate;
  return currentRank(enlist);
});

/// 다음 진급 시점 — 이미 병장이면 null(더 이상 진급 없음).
final militaryNextRankMilestoneProvider = Provider<RankMilestone?>((ref) {
  final enlist = ref.watch(militaryServiceProvider).enlistDate;
  return nextRankMilestone(enlist);
});

/// 다음 진급 D-day 라벨 — 병장이면 null.
final militaryNextRankDdayProvider = Provider<String?>((ref) {
  final milestone = ref.watch(militaryNextRankMilestoneProvider);
  if (milestone == null) return null;
  return dDayLabel(milestone.startDate);
});
