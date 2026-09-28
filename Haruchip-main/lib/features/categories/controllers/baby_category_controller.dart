import 'package:flutter/foundation.dart';
import '../data/baby_milestones.dart';

/// 아기 성장 마일스톤 정보
@immutable
class BabyMilestoneInfo {
  const BabyMilestoneInfo({
    required this.targetDays,
    required this.label,
    required this.targetDate,
    required this.daysLeft,
    required this.checklist,
    required this.isReached,
  });

  final int targetDays;
  final String label;
  final DateTime targetDate;
  final int daysLeft;
  final List<String> checklist;
  final bool isReached;
}

/// 아기 탄생일 카테고리 컨트롤러 (성장 기록형 UI & X개월 Y일째 변환)
class BabyCategoryController {
  const BabyCategoryController();

  /// 1. N일째 외에 'X개월 Y일째' 형태로 자동 변환하여 표시
  /// 예: '125일째 (4개월 5일째)'
  String formatBabyAgeDetailed(DateTime birthDate, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    final totalDays = today.difference(birth).inDays;
    if (totalDays < 0) return '출생 전';

    var months = (today.year - birth.year) * 12 + (today.month - birth.month);
    if (today.day < birth.day) months -= 1;
    if (months < 0) months = 0;

    final anchorDate = DateTime(birth.year, birth.month + months, birth.day);
    final remainderDays = today.difference(anchorDate).inDays;

    return '$totalDays일째 ($months개월 ${remainderDays < 0 ? 0 : remainderDays}일째)';
  }

  /// 2. 100일, 돌(365일) 등 주요 성장 마일스톤 카드 목록 생성
  List<BabyMilestoneInfo> getGrowthMilestones(DateTime birthDate, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    final totalDays = today.difference(birth).inDays;
    final result = <BabyMilestoneInfo>[];

    for (final milestone in kBabyMilestones) {
      final targetDate = birth.add(Duration(days: milestone.day));
      final daysLeft = milestone.day - totalDays;

      result.add(
        BabyMilestoneInfo(
          targetDays: milestone.day,
          label: milestone.label,
          targetDate: targetDate,
          daysLeft: daysLeft < 0 ? 0 : daysLeft,
          checklist: milestone.checklist,
          isReached: totalDays >= milestone.day,
        ),
      );
    }

    return result;
  }
}
