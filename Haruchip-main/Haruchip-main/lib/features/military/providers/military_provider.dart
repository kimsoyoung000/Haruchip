import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../plan/providers/plan_provider.dart' show dDayLabel, planItemsByCategoryProvider;
import '../data/military_mock_data.dart';
import '../models/military_rank.dart';
import '../models/military_service.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 군대(곰신) 복무 정보 상태 — 핸드오프 문서 §5.3.
///
/// [CoupleNotifier]와 같은 구조: mock으로 시작하고, "설정" 다이얼로그가
/// [setService]/[setBranch]/[setNextLeave]로 갱신한다.
class MilitaryServiceNotifier extends Notifier<MilitaryService> {
  @override
  MilitaryService build() => mockMilitaryService;

  void setService({
    required DateTime enlistDate,
    required DateTime dischargeDate,
    MilitaryBranch? branch,
    int? totalVacationDays,
    int? usedVacationDays,
  }) {
    state = state.copyWith(
      enlistDate: enlistDate,
      dischargeDate: dischargeDate,
      branch: branch,
      totalVacationDays: totalVacationDays,
      usedVacationDays: usedVacationDays,
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
  final discharge = _dateOnly(service.dischargeDate);
  final today = _dateOnly(DateTime.now());

  final totalDays = discharge.difference(enlist).inDays;
  if (totalDays <= 0) return 0;
  final elapsedDays = today.difference(enlist).inDays;
  return (elapsedDays / totalDays).clamp(0.0, 1.0);
});

/// 전역 D-day 라벨('D-n'/'D-day'/'D+n') — [dDayLabel] 재사용.
final militaryDischargeDdayProvider = Provider<String>((ref) {
  final service = ref.watch(militaryServiceProvider);
  return dDayLabel(service.dischargeDate);
});

/// 가장 가까운 다음 휴가 날짜(DateTime?) — 등록된 군대 플랜 항목 및 service.nextLeaveDate 통합
final militaryNextLeaveDateProvider = Provider<DateTime?>((ref) {
  final service = ref.watch(militaryServiceProvider);
  final militaryItems = ref.watch(planItemsByCategoryProvider('military'));
  final today = _dateOnly(DateTime.now());

  // 군대 플랜 항목 중 '휴가', '외박', '외출', '포상', '정기' 포함 항목 검색
  final leaveItems = militaryItems.where((i) {
    final title = i.title.toLowerCase();
    final isLeave = title.contains('휴가') ||
        title.contains('외박') ||
        title.contains('외출') ||
        title.contains('포상') ||
        title.contains('정기');
    final itemDate = _dateOnly(i.date);
    return isLeave && !itemDate.isBefore(today);
  }).toList();

  leaveItems.sort((a, b) => a.date.compareTo(b.date));

  if (leaveItems.isNotEmpty) {
    return leaveItems.first.date;
  }

  if (service.nextLeaveDate != null && !_dateOnly(service.nextLeaveDate!).isBefore(today)) {
    return service.nextLeaveDate;
  }

  return service.nextLeaveDate;
});

/// 다음 휴가 D-day — 설정 안 했으면 null.
final militaryLeaveDdayProvider = Provider<String?>((ref) {
  final nextDate = ref.watch(militaryNextLeaveDateProvider);
  if (nextDate == null) return null;
  return dDayLabel(nextDate);
});

/// 잔여 휴가 일수 (남은 총 휴가 개수)
final militaryRemainingVacationDaysProvider = Provider<int>((ref) {
  final service = ref.watch(militaryServiceProvider);
  final militaryItems = ref.watch(planItemsByCategoryProvider('military'));
  
  // 플랜 아이템에 명시된 휴가 항목이 있으면 합산 계산
  final scheduledVacations = militaryItems.where((i) => i.title.contains('휴가') || i.title.contains('외박')).length;
  final effectiveUsed = service.usedVacationDays > 0 ? service.usedVacationDays : scheduledVacations;
  
  return (service.totalVacationDays - effectiveUsed).clamp(0, 999).toInt();
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
