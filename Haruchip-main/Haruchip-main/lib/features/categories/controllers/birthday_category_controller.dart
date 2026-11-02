import '../models/dday_model.dart';

/// 생일 카테고리 특화 컨트롤러 (자동 매년 반복 & 인물 이모티콘)
class BirthdayCategoryController {
  const BirthdayCategoryController();

  /// 생일 기본 디데이 생성 (repeatType = yearly 기본값)
  DDayModel createBirthdayDDay({
    required String id,
    required String categoryId,
    required String name,
    required DateTime birthDate,
    String personEmoji = '🎂',
    Map<String, dynamic>? additionalData,
  }) {
    final nextTarget = calculateNextBirthdayDate(birthDate);

    return DDayModel(
      id: id,
      categoryId: categoryId,
      categoryKey: 'birthday',
      title: '$name 생일',
      targetDate: nextTarget,
      displayType: DDayDisplayType.dday,
      repeatType: DDayRepeatType.yearly, // 기본 매년 반복
      isPredictiveListed: true,
      typeSpecificData: {
        'birthDate': birthDate.toIso8601String(),
        'personName': name,
        'personEmoji': personEmoji,
        ...?additionalData,
      },
    );
  }

  /// 매년 다가오는 다음 생일 날짜 계산
  DateTime calculateNextBirthdayDate(DateTime birthDate, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    var candidate = DateTime(now.year, birthDate.month, birthDate.day);

    if (candidate.isBefore(todayOnly)) {
      candidate = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }
    return candidate;
  }

  /// 실시간 D-Day 계산 (예: D-12)
  String calculateBirthdayDDayLabel(DateTime birthDate, [DateTime? relativeTo]) {
    final nextTarget = calculateNextBirthdayDate(birthDate, relativeTo);
    final now = relativeTo ?? DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final diff = nextTarget.difference(todayOnly).inDays;

    if (diff == 0) return 'D-day';
    return 'D-$diff';
  }
}
