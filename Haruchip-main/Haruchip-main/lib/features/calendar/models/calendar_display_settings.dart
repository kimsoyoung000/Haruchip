import 'package:flutter/material.dart';

/// 칩 캘린더 글꼴 크기 단계
enum CalendarFontSize {
  xs('매우 작게', 0.85),
  sm('작게', 0.92),
  md('중간', 1.0),
  lg('크게', 1.12),
  xl('매우 크게', 1.24);

  const CalendarFontSize(this.labelKo, this.scale);
  final String labelKo;
  final double scale;

  static CalendarFontSize fromName(String? name) {
    return CalendarFontSize.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CalendarFontSize.md,
    );
  }
}

/// 칩 캘린더 글자 굵기 단계
enum CalendarFontWeight {
  thin('가늘게', FontWeight.w400),
  light('라이트', FontWeight.w500),
  regular('보통', FontWeight.w600),
  bold('굵게', FontWeight.w800);

  const CalendarFontWeight(this.labelKo, this.weight);
  final String labelKo;
  final FontWeight weight;

  static CalendarFontWeight fromName(String? name) {
    return CalendarFontWeight.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CalendarFontWeight.regular,
    );
  }
}

/// 월별 캘린더 넘겨 보기 방향
enum CalendarScrollDirection {
  horizontal('가로 스크롤'),
  vertical('세로 스크롤');

  const CalendarScrollDirection(this.labelKo);
  final String labelKo;

  static CalendarScrollDirection fromName(String? name) {
    return CalendarScrollDirection.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CalendarScrollDirection.horizontal,
    );
  }
}

/// 칩 캘린더 테마 색상 프리셋
class CalendarThemePreset {
  const CalendarThemePreset({
    required this.name,
    required this.accentColor,
    required this.selectedBgColor,
    required this.selectedBorderColor,
  });

  final String name;
  final Color accentColor;
  final Color selectedBgColor;
  final Color selectedBorderColor;

  static const List<CalendarThemePreset> presets = [
    CalendarThemePreset(
      name: '포테이토 칩',
      accentColor: Color(0xFFD99B26),
      selectedBgColor: Color(0xFFFFF8E6),
      selectedBorderColor: Color(0xFFF2C97D),
    ),
    CalendarThemePreset(
      name: '심플 블루',
      accentColor: Color(0xFF476A92),
      selectedBgColor: Color(0xFFEFF6FF),
      selectedBorderColor: Color(0xFF93C5FD),
    ),
    CalendarThemePreset(
      name: '소프트 핑크',
      accentColor: Color(0xFFE86A82),
      selectedBgColor: Color(0xFFFFF1F2),
      selectedBorderColor: Color(0xFFFDA4AF),
    ),
    CalendarThemePreset(
      name: '세이지 그린',
      accentColor: Color(0xFF3E8E63),
      selectedBgColor: Color(0xFFECFDF5),
      selectedBorderColor: Color(0xFF6EE7B7),
    ),
    CalendarThemePreset(
      name: '라벤더',
      accentColor: Color(0xFF7C5CBF),
      selectedBgColor: Color(0xFFF5F3FF),
      selectedBorderColor: Color(0xFFC4B5FD),
    ),
  ];

  static CalendarThemePreset byName(String? name) {
    return presets.firstWhere(
      (p) => p.name == name,
      orElse: () => presets.first,
    );
  }
}

/// 칩 캘린더 표시 설정 상태 모델
class CalendarDisplaySettings {
  const CalendarDisplaySettings({
    this.fontSize = CalendarFontSize.md,
    this.fontWeight = CalendarFontWeight.regular,
    this.showTime = false,
    this.compactTimeEvent = false,
    this.showLunar = false,
    this.startOnMonday = false,
    this.scrollDirection = CalendarScrollDirection.horizontal,
    this.themeColorName = '포테이토 칩',
    this.hasSeenOnboarding = false,
  });

  final CalendarFontSize fontSize;
  final CalendarFontWeight fontWeight;
  final bool showTime;
  final bool compactTimeEvent;
  final bool showLunar;
  final bool startOnMonday;
  final CalendarScrollDirection scrollDirection;
  final String themeColorName;
  final bool hasSeenOnboarding;

  CalendarThemePreset get themePreset =>
      CalendarThemePreset.byName(themeColorName);

  CalendarDisplaySettings copyWith({
    CalendarFontSize? fontSize,
    CalendarFontWeight? fontWeight,
    bool? showTime,
    bool? compactTimeEvent,
    bool? showLunar,
    bool? startOnMonday,
    CalendarScrollDirection? scrollDirection,
    String? themeColorName,
    bool? hasSeenOnboarding,
  }) {
    return CalendarDisplaySettings(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      showTime: showTime ?? this.showTime,
      compactTimeEvent: compactTimeEvent ?? this.compactTimeEvent,
      showLunar: showLunar ?? this.showLunar,
      startOnMonday: startOnMonday ?? this.startOnMonday,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      themeColorName: themeColorName ?? this.themeColorName,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize.name,
        'fontWeight': fontWeight.name,
        'showTime': showTime,
        'compactTimeEvent': compactTimeEvent,
        'showLunar': showLunar,
        'startOnMonday': startOnMonday,
        'scrollDirection': scrollDirection.name,
        'themeColorName': themeColorName,
        'hasSeenOnboarding': hasSeenOnboarding,
      };

  factory CalendarDisplaySettings.fromJson(Map<String, dynamic> json) {
    return CalendarDisplaySettings(
      fontSize: CalendarFontSize.fromName(json['fontSize'] as String?),
      fontWeight: CalendarFontWeight.fromName(json['fontWeight'] as String?),
      showTime: json['showTime'] as bool? ?? false,
      compactTimeEvent: json['compactTimeEvent'] as bool? ?? false,
      showLunar: json['showLunar'] as bool? ?? false,
      startOnMonday: json['startOnMonday'] as bool? ?? false,
      scrollDirection: CalendarScrollDirection.fromName(
        json['scrollDirection'] as String?,
      ),
      themeColorName: json['themeColorName'] as String? ?? '포테이토 칩',
      hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? false,
    );
  }
}
