import 'package:flutter/material.dart';

/// 계획(업무/프로젝트) 카테고리 컨트롤러 (칸반 보드 & 중요도 컬러 라벨 & 마감 시간 D-Time)
class PlanCategoryController {
  const PlanCategoryController();

  /// 마감 시간 D-Time 라벨 계산 (예: 14:30 마감까지 D-0 2시간 15분 남음)
  String calculateDTimeLabel({
    required DateTime targetDate,
    required TimeOfDay? deadlineTime,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final target = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      deadlineTime?.hour ?? 23,
      deadlineTime?.minute ?? 59,
    );

    final diff = target.difference(now);
    if (diff.isNegative) {
      return '마감 지남';
    }

    if (diff.inDays > 0) {
      return 'D-${diff.inDays} (${deadlineTime != null ? _formatTime(deadlineTime) : '마감'})';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return 'D-Time: $hours시간 $minutes분 남음';
    }
    return 'D-Time: $minutes분 남음';
  }

  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
