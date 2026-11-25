import 'package:flutter/material.dart';

/// 하루칩 캘린더 화면에 표시되는 일정 한 건 (CLAUDE.md §7-4).
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.time,
    required this.source,
    required this.colorHex,
    this.categoryKey = 'plan',
    this.isPublic = false,
    this.endDate,
    this.fillLabelBackground = false,
    this.planItemId,
  });

  final String id;
  final DateTime date;
  final String title;

  /// 'HH:mm' 형식 텍스트. 종일 일정이면 null.
  final String? time;

  /// 'personal' | 'google' | 'naver'
  final String source;

  /// '#RRGGBB' 형식. 항상 `AppColors.proto*` 토큰에서 파생시켜서 채운다.
  final String colorHex;

  /// 카테고리 키 ('plan' | 'couple' | 'solo' | 'fandom' | 'group' | 'exam' | 'birthday' | 'baby' | 'pet' | 'military')
  final String categoryKey;

  /// 공개/비공개 토글 상태 (기본 비공개 — CLAUDE.md §7-4).
  final bool isPublic;

  /// 다일(Multi-day) 일정의 종료일. 단일 일정이면 null.
  final DateTime? endDate;

  /// 카테고리별 [캘린더 라벨 배경 채우기] 옵션 (false: 투명 + 좌측 세로 바 / true: 파스텔 배경 채움)
  final bool fillLabelBackground;

  /// 원본 PlanItem ID (하단 일정 탭 시 수정 모달 바인딩용)
  final String? planItemId;

  DateTime get startDateOnly => DateTime(date.year, date.month, date.day);

  DateTime get effectiveEndDate {
    final e = endDate ?? date;
    final endOnly = DateTime(e.year, e.month, e.day);
    return endOnly.isBefore(startDateOnly) ? startDateOnly : endOnly;
  }

  /// 시작일과 종료일이 다른 다일(Multi-day) 연속 일정 여부
  bool get isMultiDay => effectiveEndDate.isAfter(startDateOnly);
}

/// 캘린더 라벨 텍스트 공통 다크 컬러 (구글/네이버 캘린더 동기화 정합성)
const Color kCalendarLabelDarkText = Color(0xFF2C2C2E);

/// 카테고리 고유 색상을 은은한 파스텔 배경색으로 자동 매핑
///
/// - 연파랑/블루 계열 → #E3F2FD
/// - 핑크/로즈 계열 → #FCE4EC
/// - 옐로우/앰버 계열 → #FFF8E1
/// - 블랙/그레이(저채도) 계열 → #F5F5F5
/// - 그 외 컬러 → 흰색과 18% 블렌딩한 소프트 파스텔 톤
Color resolveCalendarLabelPastelBg(Color baseColor) {
  final hsl = HSLColor.fromColor(baseColor);
  if (hsl.saturation < 0.14 || hsl.lightness < 0.14) {
    return const Color(0xFFF5F5F5);
  }
  final hue = hsl.hue;
  if (hue >= 190 && hue <= 245) {
    return const Color(0xFFE3F2FD);
  }
  if (hue >= 315 || hue <= 12) {
    return const Color(0xFFFCE4EC);
  }
  if (hue >= 36 && hue <= 66) {
    return const Color(0xFFFFF8E1);
  }
  return Color.lerp(Colors.white, baseColor, 0.18) ?? const Color(0xFFF5F5F5);
}
