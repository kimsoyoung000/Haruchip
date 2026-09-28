import 'package:flutter/foundation.dart';
import '../models/dday_model.dart';

/// 이별 / 재회 공백기 단락
@immutable
class BreakupPeriod {
  const BreakupPeriod({
    required this.breakDate,
    this.reunionDate,
  });

  final DateTime breakDate;
  final DateTime? reunionDate;

  /// 공백기 일수 (reunionDate가 없으면 relativeTo/현재날짜까지)
  int durationInDays([DateTime? relativeTo]) {
    final end = reunionDate ?? (relativeTo ?? DateTime.now());
    final d1 = DateTime(breakDate.year, breakDate.month, breakDate.day);
    final d2 = DateTime(end.year, end.month, end.day);
    return d2.difference(d1).inDays;
  }

  Map<String, dynamic> toJson() => {
        'breakDate': breakDate.toIso8601String(),
        'reunionDate': reunionDate?.toIso8601String(),
      };

  factory BreakupPeriod.fromJson(Map<String, dynamic> json) {
    return BreakupPeriod(
      breakDate: DateTime.parse(json['breakDate'] as String),
      reunionDate: json['reunionDate'] != null
          ? DateTime.parse(json['reunionDate'] as String)
          : null,
    );
  }
}

/// 커플 카테고리 특화 비즈니스 로직 및 컨트롤러
class CoupleCategoryController {
  const CoupleCategoryController();

  /// 1. 순수 만난 날짜 계산:
  /// 총 경과일 = (현재날짜 - startDate) - SUM(각 breakPeriod의 reunionDate - breakDate)
  int calculatePureDays({
    required DateTime startDate,
    required List<BreakupPeriod> breakups,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);

    final totalElapsedDays = today.difference(start).inDays;
    final totalBreakupDays = breakups.fold<int>(
      0,
      (sum, period) => sum + period.durationInDays(now),
    );

    final pureDays = totalElapsedDays - totalBreakupDays;
    return pureDays < 0 ? 0 : pureDays;
  }

  /// 2. 주요 기념일 자동 예측 목록 생성 (100, 200, ..., 1000일 및 1~50주년)
  List<DDayModel> generatePredictiveAnniversaries({
    required String categoryId,
    required DateTime startDate,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final result = <DDayModel>[];

    // 100일 단위 (100일 ~ 1000일)
    for (var n = 100; n <= 1000; n += 100) {
      final target = start.add(Duration(days: n));
      if (!target.isBefore(today)) {
        result.add(
          DDayModel(
            id: 'couple-anniv-$n',
            categoryId: categoryId,
            categoryKey: 'couple',
            title: '$n일',
            targetDate: target,
            displayType: DDayDisplayType.dday,
            isPredictiveListed: true,
            typeSpecificData: {
              'milestoneType': 'days',
              'milestoneValue': n,
            },
          ),
        );
      }
    }

    // 주년 단위 (1주년 ~ 50주년)
    for (var years = 1; years <= 50; years++) {
      final target = DateTime(start.year + years, start.month, start.day);
      if (!target.isBefore(today)) {
        result.add(
          DDayModel(
            id: 'couple-anniv-${years}y',
            categoryId: categoryId,
            categoryKey: 'couple',
            title: '$years주년',
            targetDate: target,
            displayType: DDayDisplayType.dday,
            isPredictiveListed: true,
            typeSpecificData: {
              'milestoneType': 'years',
              'milestoneValue': years,
            },
          ),
        );
      }
    }

    result.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return result;
  }
}
