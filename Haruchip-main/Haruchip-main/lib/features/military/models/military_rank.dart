import 'package:flutter/foundation.dart';

/// 군종 — 핸드오프 문서(카테고리&디데이 §5.3) 신규 규정 데이터.
///
/// [MilitaryService.branch]가 참조한다. 병장 구간(전역까지 잔여 기간)만
/// 군종별로 다르고(육군/해병 4개월, 해군 6개월, 공군 7개월), 그 앞
/// 진급 시점(이병→일병→상병→병장, 2/8/14개월차)은 군종 공통이다.
enum MilitaryBranch {
  army,
  marines,
  navy,
  airForce,
  publicService;

  String get labelKo => switch (this) {
        MilitaryBranch.army => '육군',
        MilitaryBranch.marines => '해병대',
        MilitaryBranch.navy => '해군',
        MilitaryBranch.airForce => '공군',
        MilitaryBranch.publicService => '사회복무요원',
      };

  static MilitaryBranch fromName(String? raw) {
    return MilitaryBranch.values.firstWhere(
      (b) => b.name == raw,
      orElse: () => MilitaryBranch.army,
    );
  }
}

/// 군종별 총 복무기간(개월) — §5.3.
const Map<MilitaryBranch, int> totalServiceMonths = {
  MilitaryBranch.army: 18,
  MilitaryBranch.marines: 18,
  MilitaryBranch.navy: 20,
  MilitaryBranch.airForce: 21,
  MilitaryBranch.publicService: 21,
};

const int monthsToPrivateFirstClass = 2; // 이병 → 일병
const int monthsToCorporal = 8; // 일병 → 상병
const int monthsToSergeant = 14; // 상병 → 병장(이후는 전역까지 병장 구간)

/// 계급 — 이병/일병/상병/병장(장교·부사관 등 특수 케이스는 범위 밖, §5.3).
enum MilitaryRank {
  private,
  privateFirstClass,
  corporal,
  sergeant;

  String get labelKo => switch (this) {
        MilitaryRank.private => '이병',
        MilitaryRank.privateFirstClass => '일병',
        MilitaryRank.corporal => '상병',
        MilitaryRank.sergeant => '병장',
      };
}

/// [date]에 [months]개월을 더한다. 말일을 넘어가면(예: 1/31 + 1개월)
/// 해당 월의 마지막 날로 보정한다 — `DateTime(year, month + 1, day)`를
/// 그대로 쓰면 다음 달로 밀려버리는 걸 막기 위함.
DateTime _addMonths(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final day = date.day > daysInMonth ? daysInMonth : date.day;
  return DateTime(year, month, day);
}

/// 진급 시점 1건 — [rank]가 시작되는 날짜.
@immutable
class RankMilestone {
  const RankMilestone({required this.rank, required this.startDate});

  final MilitaryRank rank;
  final DateTime startDate;
}

/// [enlistDate] 기준 이병→일병→상병→병장 진급 시작일 목록(군종 공통
/// 규정, §5.3). 병장은 14개월차에 시작해 전역일까지 이어진다 — 별도
/// 종료일을 두지 않는다("병장 구간: 전역까지 잔여 기간 전부").
List<RankMilestone> rankMilestones(DateTime enlistDate) {
  return [
    RankMilestone(rank: MilitaryRank.private, startDate: enlistDate),
    RankMilestone(
      rank: MilitaryRank.privateFirstClass,
      startDate: _addMonths(enlistDate, monthsToPrivateFirstClass),
    ),
    RankMilestone(
      rank: MilitaryRank.corporal,
      startDate: _addMonths(enlistDate, monthsToCorporal),
    ),
    RankMilestone(
      rank: MilitaryRank.sergeant,
      startDate: _addMonths(enlistDate, monthsToSergeant),
    ),
  ];
}

/// [today](기본값 오늘) 시점의 현재 계급. 입대 전이면 이병으로 clamp.
MilitaryRank currentRank(DateTime enlistDate, {DateTime? today}) {
  final now = today ?? DateTime.now();
  var rank = MilitaryRank.private;
  for (final milestone in rankMilestones(enlistDate)) {
    if (!now.isBefore(milestone.startDate)) {
      rank = milestone.rank;
    }
  }
  return rank;
}

/// 다음 진급 시점 — 이미 병장이면(더 이상 진급 없음, §5.3) null.
RankMilestone? nextRankMilestone(DateTime enlistDate, {DateTime? today}) {
  final now = today ?? DateTime.now();
  for (final milestone in rankMilestones(enlistDate)) {
    if (now.isBefore(milestone.startDate)) return milestone;
  }
  return null;
}

/// 군종 기본 전역 예정일(입대일 + 총 복무기간) — 설정 다이얼로그가 군종을
/// 고르면 이 값으로 전역일 입력을 미리 채운다. 휴가·연장복무 등 예외가
/// 있을 수 있어 사용자가 이후에도 전역일을 직접 수정할 수 있게 강제하지
/// 않는다(그대로 편집 가능한 필드로 남겨둠).
DateTime defaultDischargeDate(DateTime enlistDate, MilitaryBranch branch) {
  return _addMonths(enlistDate, totalServiceMonths[branch]!);
}

/// 실시간 정밀 복무율(0.0 ~ 1.0) — 소수점 6자리까지 흐르는 실시간 게이지용
double calculateExactServiceProgress({
  required DateTime enlistDate,
  required DateTime dischargeDate,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final start = DateTime(enlistDate.year, enlistDate.month, enlistDate.day);
  final end = DateTime(dischargeDate.year, dischargeDate.month, dischargeDate.day);
  final totalUs = end.difference(start).inMicroseconds;
  if (totalUs <= 0) return 1.0;
  final elapsedUs = current.difference(start).inMicroseconds;
  return (elapsedUs / totalUs).clamp(0.0, 1.0);
}

/// 현재 호봉 및 다음 호봉 승급 정보
@immutable
class HobongInfo {
  const HobongInfo({
    required this.currentRank,
    required this.currentHobong,
    required this.nextHobong,
    required this.nextHobongDate,
    required this.dDay,
    required this.progress,
  });

  final MilitaryRank currentRank;
  final int currentHobong;
  final int nextHobong;
  final DateTime nextHobongDate;
  final int dDay;
  final double progress;
}

/// 현재 계급의 호봉 및 다음 호봉 승급 진행률 계산
/// [customNextHobongDate]가 지정되면 해당 날짜를 다음 호봉 승급일로 우선 적용한다.
HobongInfo calculateHobongInfo(
  DateTime enlistDate, {
  DateTime? now,
  DateTime? customNextHobongDate,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final milestones = rankMilestones(enlistDate);

  RankMilestone active = milestones.first;
  for (final m in milestones) {
    if (!today.isBefore(DateTime(m.startDate.year, m.startDate.month, m.startDate.day))) {
      active = m;
    }
  }

  final monthsInRank = ((today.year - active.startDate.year) * 12 +
          (today.month - active.startDate.month))
      .clamp(0, 12);
  final currentHobong = monthsInRank + 1;

  final DateTime periodStart;
  final DateTime targetDate;
  if (customNextHobongDate != null) {
    targetDate = DateTime(
      customNextHobongDate.year,
      customNextHobongDate.month,
      customNextHobongDate.day,
    );
    periodStart = _addMonths(targetDate, -1);
  } else {
    periodStart = DateTime(today.year, today.month, 1);
    targetDate = DateTime(today.year, today.month + 1, 1);
  }

  final totalUs = targetDate.difference(periodStart).inMicroseconds;
  final elapsedUs = current.difference(periodStart).inMicroseconds;
  final progress = totalUs > 0 ? (elapsedUs / totalUs).clamp(0.0, 1.0) : 1.0;
  final dDay = targetDate.difference(today).inDays.clamp(0, 9999);

  return HobongInfo(
    currentRank: active.rank,
    currentHobong: currentHobong,
    nextHobong: currentHobong + 1,
    nextHobongDate: targetDate,
    dDay: dDay,
    progress: progress,
  );
}

/// 계급 진급 진행률 정보
@immutable
class RankPromotionProgress {
  const RankPromotionProgress({
    required this.currentRank,
    required this.nextRank,
    required this.targetDate,
    required this.dDay,
    required this.progress,
  });

  final MilitaryRank currentRank;
  final MilitaryRank? nextRank; // 병장일 경우 null (전역 기준)
  final DateTime targetDate;
  final int dDay;
  final double progress;
}

/// 현재 계급 시작일 → 다음 계급 진급일(병장은 전역일) 진행률 계산
/// [customNextRankDate]가 지정되면 해당 날짜를 진급 목표로 우선 적용한다.
RankPromotionProgress calculateRankPromotionProgress(
  DateTime enlistDate,
  DateTime dischargeDate, {
  DateTime? now,
  DateTime? customNextRankDate,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final milestones = rankMilestones(enlistDate);

  RankMilestone active = milestones.first;
  RankMilestone? next;
  for (final m in milestones) {
    final mDate = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
    if (!today.isBefore(mDate)) {
      active = m;
    } else {
      next ??= m;
    }
  }

  final start = DateTime(active.startDate.year, active.startDate.month, active.startDate.day);
  final end = customNextRankDate != null
      ? DateTime(
          customNextRankDate.year,
          customNextRankDate.month,
          customNextRankDate.day,
        )
      : (next != null
          ? DateTime(next.startDate.year, next.startDate.month, next.startDate.day)
          : DateTime(dischargeDate.year, dischargeDate.month, dischargeDate.day));

  final totalUs = end.difference(start).inMicroseconds;
  final elapsedUs = current.difference(start).inMicroseconds;
  final progress = totalUs > 0 ? (elapsedUs / totalUs).clamp(0.0, 1.0) : 1.0;
  final dDay = end.difference(today).inDays.clamp(0, 9999);

  return RankPromotionProgress(
    currentRank: active.rank,
    nextRank: next?.rank,
    targetDate: end,
    dDay: dDay,
    progress: progress,
  );
}

/// 대한민국 주요 양력 법정 공휴일 (월-일)
const Set<(int, int)> _kKoreanFixedHolidays = {
  (1, 1), // 신정
  (3, 1), // 삼일절
  (5, 5), // 어린이날
  (6, 6), // 현충일
  (8, 15), // 광복절
  (10, 3), // 개천절
  (10, 9), // 한글날
  (12, 25), // 성탄절
};

/// 남은 일과일 계산: 남은 복무일 - (주말 토·일 + 공휴일 + 등록된 개인 휴가 평일 일수)
int calculateRemainingWorkdays({
  required DateTime dischargeDate,
  List<({DateTime startDate, DateTime endDate})> leaveRanges = const [],
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(dischargeDate.year, dischargeDate.month, dischargeDate.day);
  if (!end.isAfter(start)) return 0;

  // 등록된 휴가 날짜 집합 (평일 중복 차감 방지)
  final leaveDays = <DateTime>{};
  for (final range in leaveRanges) {
    final s = DateTime(range.startDate.year, range.startDate.month, range.startDate.day);
    final e = DateTime(range.endDate.year, range.endDate.month, range.endDate.day);
    for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      leaveDays.add(d);
    }
  }

  int workdays = 0;
  for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      continue;
    }
    if (_kKoreanFixedHolidays.contains((d.month, d.day))) {
      continue;
    }
    if (leaveDays.contains(d)) {
      continue;
    }
    workdays++;
  }
  return workdays;
}
