import 'package:flutter/material.dart' show TimeOfDay;

/// 결혼 준비 6대 주요 진행 단계 (기존 데이터 모델 100% 호환 유지)
enum WeddingStage {
  hallAndPlanner('상견례 및 웨딩홀/플래너', '🏛️', 1),
  studimeAndRing('스드메 및 웨딩밴드', '💍', 2),
  studioShoot('스튜디오 촬영 및 셀렉', '📸', 3),
  houseAndLiving('신혼집 및 혼수/가전/가구', '🛋️', 4),
  invitationAndGuest('청첩장 및 하객 준비', '💌', 5),
  finalCheckAndCeremony('본식 최종 점검 및 예식', '👰', 6);

  const WeddingStage(this.labelKo, this.emoji, this.order);

  final String labelKo;
  final String emoji;
  final int order;
}

/// 준비 영역별 5대 도메인 분류 (스마트 추천 피커용 — 메인 리스트는 D-Day 임박순 단일 리스트)
enum WeddingDomainGroup {
  hallAndCeremony('웨딩홀 & 본식', 1),
  studimeAndShoot('스드메 & 촬영', 2),
  ringAndSuit('예물 & 예복', 3),
  honeymoonAndHome('신혼여행 & 신혼집', 4),
  beautyAndCare('뷰티 & 케어', 5);

  const WeddingDomainGroup(this.labelKo, this.order);

  final String labelKo;
  final int order;

  static WeddingDomainGroup fromName(String? raw) {
    return WeddingDomainGroup.values.firstWhere(
      (g) => g.name == raw,
      orElse: () => WeddingDomainGroup.hallAndCeremony,
    );
  }

  /// 항목 제목과 기존 단계(stage)를 기반으로 가장 적합한 도메인 그룹을 자동 매핑
  static WeddingDomainGroup infer(String title, WeddingStage stage) {
    final t = title.toLowerCase();
    if (t.contains('피부') ||
        t.contains('다이어트') ||
        t.contains('네일') ||
        t.contains('염색') ||
        t.contains('헤어라인') ||
        t.contains('관리') ||
        t.contains('케어') ||
        t.contains('경락') ||
        t.contains('치아') ||
        t.contains('왁싱') ||
        t.contains('에스테틱')) {
      return WeddingDomainGroup.beautyAndCare;
    }
    if (t.contains('신혼여행') ||
        t.contains('항공') ||
        t.contains('숙소') ||
        t.contains('신혼집') ||
        t.contains('가전') ||
        t.contains('가구') ||
        t.contains('혼수') ||
        t.contains('이사') ||
        t.contains('입주') ||
        t.contains('여권') ||
        t.contains('환전')) {
      return WeddingDomainGroup.honeymoonAndHome;
    }
    if (t.contains('반지') ||
        t.contains('웨딩밴드') ||
        t.contains('예물') ||
        t.contains('예복') ||
        t.contains('수제화') ||
        t.contains('예단') ||
        (t.contains('한복') && !t.contains('혼주'))) {
      return WeddingDomainGroup.ringAndSuit;
    }
    if (t.contains('스드메') ||
        t.contains('플래너') ||
        t.contains('드레스') ||
        t.contains('스튜디오') ||
        t.contains('촬영') ||
        t.contains('셀렉') ||
        t.contains('메이크업') ||
        t.contains('부케') ||
        t.contains('헬퍼') ||
        t.contains('가봉') ||
        t.contains('모바일 청첩장 사진')) {
      return WeddingDomainGroup.studimeAndShoot;
    }
    if (t.contains('웨딩홀') ||
        t.contains('본식') ||
        t.contains('스냅') ||
        t.contains('dvd') ||
        t.contains('사회자') ||
        t.contains('축가') ||
        t.contains('주례') ||
        t.contains('혼주') ||
        t.contains('상견례') ||
        t.contains('부모님') ||
        t.contains('식권') ||
        t.contains('가방순이') ||
        t.contains('청첩장') ||
        t.contains('답례')) {
      return WeddingDomainGroup.hallAndCeremony;
    }

    switch (stage) {
      case WeddingStage.hallAndPlanner:
      case WeddingStage.invitationAndGuest:
      case WeddingStage.finalCheckAndCeremony:
        return WeddingDomainGroup.hallAndCeremony;
      case WeddingStage.studimeAndRing:
      case WeddingStage.studioShoot:
        return WeddingDomainGroup.studimeAndShoot;
      case WeddingStage.houseAndLiving:
        return WeddingDomainGroup.honeymoonAndHome;
    }
  }
}

/// 시기별 웨딩 타임라인 5대 그룹 (하위 호환 유지)
enum WeddingTimelineGroup {
  d1Year('D-1년 전', 300, 1),
  d6Months('D-6개월', 180, 2),
  d3Months('D-3개월', 90, 3),
  d1Month('D-1개월', 30, 4),
  weddingWeek('본식 주', 7, 5);

  const WeddingTimelineGroup(this.labelKo, this.defaultOffsetDays, this.order);

  final String labelKo;
  final int defaultOffsetDays;
  final int order;

  static WeddingTimelineGroup fromOffsetDays(int offsetDays) {
    if (offsetDays >= 210) return WeddingTimelineGroup.d1Year;
    if (offsetDays >= 120) return WeddingTimelineGroup.d6Months;
    if (offsetDays >= 45) return WeddingTimelineGroup.d3Months;
    if (offsetDays >= 8) return WeddingTimelineGroup.d1Month;
    return WeddingTimelineGroup.weddingWeek;
  }
}

/// 일정 담당자 (공동 / 신랑 / 신부)
enum WeddingAssignee {
  joint('공동'),
  groom('신랑'),
  bride('신부');

  const WeddingAssignee(this.labelKo);

  final String labelKo;

  static WeddingAssignee fromName(String? raw) {
    return WeddingAssignee.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => WeddingAssignee.joint,
    );
  }
}

/// 한글 초성 추출 및 키워드/초성 통합 매칭 헬퍼 (예: 'ㅅㄴ' -> '본식 스냅 계약')
const List<String> _kHangulChosung = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

String extractKoreanChosung(String input) {
  final buffer = StringBuffer();
  for (final codeUnit in input.codeUnits) {
    if (codeUnit >= 0xAC00 && codeUnit <= 0xD7A3) {
      final chosungIndex = (codeUnit - 0xAC00) ~/ 588;
      buffer.write(_kHangulChosung[chosungIndex]);
    } else {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}

bool matchesKoreanQuery(String source, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;
  final normalizedSource = source.toLowerCase();
  if (normalizedSource.contains(query)) return true;

  // 공백 제거 일반 매칭
  final compactQuery = query.replaceAll(' ', '');
  final compactSource = normalizedSource.replaceAll(' ', '');
  if (compactSource.contains(compactQuery)) return true;

  // 초성 매칭
  final sourceChosung = extractKoreanChosung(compactSource);
  final queryChosung = extractKoreanChosung(compactQuery);
  return sourceChosung.contains(queryChosung);
}

/// 단일 결혼 준비 체크리스트 항목 모델 (1:1 개별 분리)
class WeddingItem {
  WeddingItem({
    required this.id,
    required this.orderIndex,
    required this.title,
    required this.standardOffsetDays,
    required this.stage,
    this.targetDate,
    this.deadlineTime,
    this.isCompleted = false,
    this.completedAt,
    this.location = '',
    this.memo = '',
    this.budget,
    this.actualCost,
    this.isWeekdayPreferred = false,
    this.weekdayNotice,
    this.syncedPlanId,
    this.assignee = WeddingAssignee.joint,
    this.domainGroupOverride,
  });

  final String id;
  final int orderIndex;
  final String title;
  final int standardOffsetDays;
  final WeddingStage stage;
  final DateTime? targetDate;
  final TimeOfDay? deadlineTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final String location;
  final String memo;
  final int? budget;
  final int? actualCost;
  final bool isWeekdayPreferred;
  final String? weekdayNotice;
  final String? syncedPlanId;
  final WeddingAssignee assignee;
  final WeddingDomainGroup? domainGroupOverride;

  /// 준비 영역별 5대 도메인 그룹 반환
  WeddingDomainGroup get domainGroup =>
      domainGroupOverride ?? WeddingDomainGroup.infer(title, stage);

  /// 시기별 아코디언/추천 그룹 반환 (하위 호환)
  WeddingTimelineGroup get timelineGroup =>
      WeddingTimelineGroup.fromOffsetDays(standardOffsetDays);

  WeddingItem copyWith({
    String? id,
    int? orderIndex,
    String? title,
    int? standardOffsetDays,
    WeddingStage? stage,
    DateTime? targetDate,
    TimeOfDay? deadlineTime,
    bool? isCompleted,
    DateTime? completedAt,
    String? location,
    String? memo,
    int? budget,
    int? actualCost,
    bool? isWeekdayPreferred,
    String? weekdayNotice,
    String? syncedPlanId,
    WeddingAssignee? assignee,
    WeddingDomainGroup? domainGroupOverride,
    bool clearDate = false,
    bool clearTime = false,
  }) {
    return WeddingItem(
      id: id ?? this.id,
      orderIndex: orderIndex ?? this.orderIndex,
      title: title ?? this.title,
      standardOffsetDays: standardOffsetDays ?? this.standardOffsetDays,
      stage: stage ?? this.stage,
      targetDate: clearDate ? null : (targetDate ?? this.targetDate),
      deadlineTime: clearTime ? null : (deadlineTime ?? this.deadlineTime),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      budget: budget ?? this.budget,
      actualCost: actualCost ?? this.actualCost,
      isWeekdayPreferred: isWeekdayPreferred ?? this.isWeekdayPreferred,
      weekdayNotice: weekdayNotice ?? this.weekdayNotice,
      syncedPlanId: syncedPlanId ?? this.syncedPlanId,
      assignee: assignee ?? this.assignee,
      domainGroupOverride: domainGroupOverride ?? this.domainGroupOverride,
    );
  }

  /// 실시간 D-Day 및 당일 시간 잔여 카운트다운 텍스트 계산
  String dDayLabel({DateTime? relativeNow}) {
    if (targetDate == null) return '날짜 미정';

    final now = relativeNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);

    final diffDays = target.difference(today).inDays;

    if (diffDays > 0) {
      return 'D-$diffDays';
    } else if (diffDays < 0) {
      return 'D+${diffDays.abs()}';
    } else {
      // 당일 도달 시 실시간 잔여 시간 계산
      if (deadlineTime != null) {
        final targetDateTime = DateTime(
          target.year,
          target.month,
          target.day,
          deadlineTime!.hour,
          deadlineTime!.minute,
        );
        final diffMinutes = targetDateTime.difference(now).inMinutes;

        if (diffMinutes > 0) {
          final hours = diffMinutes ~/ 60;
          final mins = diffMinutes % 60;
          if (hours > 0) {
            return 'D-Day (${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} 남음)';
          } else {
            return 'D-Day ($mins분 남음)';
          }
        } else {
          return '시간 경과 (완료 체크 권장)';
        }
      }
      return 'D-Day';
    }
  }

  /// 슬림 1줄 타일용 짧은 D-Day 뱃지 텍스트
  String compactDdayBadge({DateTime? relativeNow}) {
    if (targetDate == null) return '미정';
    final now = relativeNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    final diffDays = target.difference(today).inDays;
    if (diffDays > 0) return 'D-$diffDays';
    if (diffDays < 0) return 'D+${diffDays.abs()}';
    return 'D-Day';
  }

  /// 체크리스트 타일 우측 표기 규격:
  /// - 날짜 미지정: '미정'
  /// - 날짜 지정: '2026.05.14(목) · D-35'
  String formattedDateWithWeekdayAndDday({DateTime? relativeNow}) {
    if (targetDate == null) return '미정';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final d = targetDate!;
    final wd = weekdays[(d.weekday - 1).clamp(0, 6)];
    final dateStr =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}($wd)';
    final dday = compactDdayBadge(relativeNow: relativeNow);
    return '$dateStr · $dday';
  }

  /// 포맷된 날짜/시간 문자열 (ex. "2026.05.16 14:00" 또는 "2026.05.16")
  String get formattedDateTime {
    if (targetDate == null) return '일정 미지정';
    final dateStr =
        '${targetDate!.year}.${targetDate!.month.toString().padLeft(2, '0')}.${targetDate!.day.toString().padLeft(2, '0')}';
    if (deadlineTime != null) {
      final hourStr = deadlineTime!.hour.toString().padLeft(2, '0');
      final minuteStr = deadlineTime!.minute.toString().padLeft(2, '0');
      return '$dateStr $hourStr:$minuteStr';
    }
    return dateStr;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderIndex': orderIndex,
      'title': title,
      'standardOffsetDays': standardOffsetDays,
      'stage': stage.name,
      'targetDate': targetDate?.toIso8601String(),
      'deadlineTime': deadlineTime != null
          ? {'hour': deadlineTime!.hour, 'minute': deadlineTime!.minute}
          : null,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'location': location,
      'memo': memo,
      'budget': budget,
      'actualCost': actualCost,
      'isWeekdayPreferred': isWeekdayPreferred,
      'weekdayNotice': weekdayNotice,
      'syncedPlanId': syncedPlanId,
      'assignee': assignee.name,
      if (domainGroupOverride != null)
        'domainGroupOverride': domainGroupOverride!.name,
    };
  }

  factory WeddingItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedTime;
    if (json['deadlineTime'] != null) {
      final map = Map<String, dynamic>.from(json['deadlineTime'] as Map);
      parsedTime = TimeOfDay(
        hour: map['hour'] as int? ?? 0,
        minute: map['minute'] as int? ?? 0,
      );
    }

    return WeddingItem(
      id: json['id'] as String,
      orderIndex: json['orderIndex'] as int? ?? 1,
      title: json['title'] as String,
      standardOffsetDays: json['standardOffsetDays'] as int? ?? 0,
      stage: WeddingStage.values.firstWhere(
        (s) => s.name == json['stage'],
        orElse: () => WeddingStage.hallAndPlanner,
      ),
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      deadlineTime: parsedTime,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      location: json['location'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      budget: json['budget'] as int?,
      actualCost: json['actualCost'] as int?,
      isWeekdayPreferred: json['isWeekdayPreferred'] as bool? ?? false,
      weekdayNotice: json['weekdayNotice'] as String?,
      syncedPlanId: json['syncedPlanId'] as String?,
      assignee: WeddingAssignee.fromName(json['assignee'] as String?),
      domainGroupOverride: json['domainGroupOverride'] != null
          ? WeddingDomainGroup.fromName(json['domainGroupOverride'] as String?)
          : null,
    );
  }
}

/// 현재 날짜 기준 D-Day 임박순(가장 가까운 순서) 정렬 비교자
/// - 일정 지정 항목 우선 배치 (미래/오늘 임박순 -> 지난 일정 순)
/// - 일정 미지정 항목들은 하단(뒤쪽)에 정돈 배치
int compareWeddingItemsByCloseness(WeddingItem a, WeddingItem b, [DateTime? relativeNow]) {
  // 1. 일정 지정 유무 (날짜 지정 우선, 미지정 하단)
  if (a.targetDate == null && b.targetDate == null) {
    return a.orderIndex.compareTo(b.orderIndex);
  }
  if (a.targetDate == null) return 1;
  if (b.targetDate == null) return -1;

  final now = relativeNow ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final aDate = DateTime(a.targetDate!.year, a.targetDate!.month, a.targetDate!.day);
  final bDate = DateTime(b.targetDate!.year, b.targetDate!.month, b.targetDate!.day);

  final aDiff = aDate.difference(today).inDays;
  final bDiff = bDate.difference(today).inDays;

  final aIsPast = aDiff < 0;
  final bIsPast = bDiff < 0;

  // 미래/오늘 일정이 지난 일정보다 우선
  if (aIsPast != bIsPast) {
    return aIsPast ? 1 : -1;
  }

  // 미래 일정: D-Day가 가장 가까운 순(임박순: D-Day, D-1, D-2 ...)
  if (!aIsPast) {
    if (aDiff != bDiff) return aDiff.compareTo(bDiff);
  } else {
    // 지난 일정: 최근 지난 순(내림차순, 예: D+1이 D+10보다 앞)
    if (aDiff != bDiff) return bDiff.compareTo(aDiff);
  }

  // 시간이 지정되어 있는 경우 시간순 비교
  if (a.deadlineTime != null && b.deadlineTime != null) {
    final aMins = a.deadlineTime!.hour * 60 + a.deadlineTime!.minute;
    final bMins = b.deadlineTime!.hour * 60 + b.deadlineTime!.minute;
    if (aMins != bMins) return aMins.compareTo(bMins);
  } else if (a.deadlineTime != null) {
    return -1;
  } else if (b.deadlineTime != null) {
    return 1;
  }

  return a.orderIndex.compareTo(b.orderIndex);
}
