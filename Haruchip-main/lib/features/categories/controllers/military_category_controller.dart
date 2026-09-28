import 'package:flutter/foundation.dart';
import '../../military/models/military_rank.dart';

/// 휴가 정보
@immutable
class VacationPeriod {
  const VacationPeriod({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.deductFromService = false,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// 복무 기간 차감 계산 옵션
  final bool deductFromService;

  int get daysCount {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'deductFromService': deductFromService,
      };

  factory VacationPeriod.fromJson(Map<String, dynamic> json) {
    return VacationPeriod(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '휴가',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      deductFromService: json['deductFromService'] as bool? ?? false,
    );
  }
}

/// 계급별 D-Day 정보
@immutable
class RankDDayInfo {
  const RankDDayInfo({
    required this.rank,
    required this.promotionDate,
    required this.dDayLabel,
    required this.isPassed,
  });

  final MilitaryRank rank;
  final DateTime promotionDate;
  final String dDayLabel;
  final bool isPassed;
}

/// 군대 카테고리 컨트롤러 (진급 게이지 바 & 휴가 스케줄러 & 계급 D-Day)
class MilitaryCategoryController {
  const MilitaryCategoryController();

  /// 1. 진급 게이지 바: 전체 복무 기간 대비 현재 일수의 진행률(%) 계산
  double calculateProgressPercentage({
    required DateTime enlistmentDate,
    required DateTime dischargeDate,
    List<VacationPeriod> vacations = const [],
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(enlistmentDate.year, enlistmentDate.month, enlistmentDate.day);
    var end = DateTime(dischargeDate.year, dischargeDate.month, dischargeDate.day);

    // 복무 기간 차감 옵션이 켜진 휴가 일수 총합 계산
    final deductedVacationDays = vacations
        .where((v) => v.deductFromService)
        .fold<int>(0, (sum, v) => sum + v.daysCount);

    if (deductedVacationDays > 0) {
      end = end.subtract(Duration(days: deductedVacationDays));
    }

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 100.0;

    final servedDays = today.difference(start).inDays;
    if (servedDays <= 0) return 0.0;
    if (servedDays >= totalDays) return 100.0;

    final progress = (servedDays / totalDays) * 100.0;
    return double.parse(progress.toStringAsFixed(1));
  }

  /// 2. 계급별 D-Day 자동 계산 리스트업
  List<RankDDayInfo> calculateRankDDays({
    required DateTime enlistmentDate,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final milestones = rankMilestones(enlistmentDate);

    final result = <RankDDayInfo>[];
    for (final m in milestones) {
      final pDate = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
      final diff = pDate.difference(today).inDays;

      String label;
      if (diff == 0) {
        label = 'D-day';
      } else if (diff > 0) {
        label = 'D-$diff';
      } else {
        label = 'D+${diff.abs()}';
      }

      result.add(
        RankDDayInfo(
          rank: m.rank,
          promotionDate: pDate,
          dDayLabel: label,
          isPassed: diff < 0,
        ),
      );
    }

    return result;
  }

  /// 3. 다음 휴가 D-Day 계산
  int? calculateVacationDDay(VacationPeriod vacation, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(vacation.startDate.year, vacation.startDate.month, vacation.startDate.day);
    final diff = start.difference(today).inDays;
    return diff;
  }
}
