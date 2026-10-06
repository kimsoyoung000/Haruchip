import 'package:flutter/foundation.dart';

/// 솔로 카테고리 모드 유형
enum SoloMode {
  selfCare, // 나를 위한 시간 (싱글/이별/새출발/비혼)
  crush; // 마음 진행 중 (짝사랑/썸/연락)

  String get labelKo => switch (this) {
        SoloMode.selfCare => '나를 위한 시간',
        SoloMode.crush => '마음 진행 중',
      };

  String get cardTitlePrefix => switch (this) {
        SoloMode.selfCare => '나에게 집중한 지',
        SoloMode.crush => '설레기 시작한 지',
      };

  String get emoji => switch (this) {
        SoloMode.selfCare => '🌱',
        SoloMode.crush => '💌',
      };

  String toJson() => name;

  static SoloMode fromJson(String? value) {
    return SoloMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SoloMode.selfCare,
    );
  }
}

/// 솔로 카테고리 프로필 및 상태 모델
@immutable
class SoloProfile {
  const SoloProfile({
    this.mode = SoloMode.selfCare,
    required this.selfCareStartDate,
    required this.crushStartDate,
    this.showTopCard = true,
    this.tags = const [
      '나홀로여행',
      '바디프로필',
      '취미/운동',
      '새출발',
      '데이트/소개팅',
    ],
  });

  final SoloMode mode;
  final DateTime selfCareStartDate;
  final DateTime crushStartDate;
  final bool showTopCard;
  final List<String> tags;

  /// 현재 활성화된 모드의 시작일
  DateTime get activeStartDate =>
      mode == SoloMode.selfCare ? selfCareStartDate : crushStartDate;

  /// 현재 모드 기준 N일째 계산 (당일 = 1일째)
  int daysCount([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      activeStartDate.year,
      activeStartDate.month,
      activeStartDate.day,
    );
    final diff = today.difference(start).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  SoloProfile copyWith({
    SoloMode? mode,
    DateTime? selfCareStartDate,
    DateTime? crushStartDate,
    bool? showTopCard,
    List<String>? tags,
  }) {
    return SoloProfile(
      mode: mode ?? this.mode,
      selfCareStartDate: selfCareStartDate ?? this.selfCareStartDate,
      crushStartDate: crushStartDate ?? this.crushStartDate,
      showTopCard: showTopCard ?? this.showTopCard,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.toJson(),
        'selfCareStartDate': selfCareStartDate.toIso8601String(),
        'crushStartDate': crushStartDate.toIso8601String(),
        'showTopCard': showTopCard,
        'tags': tags,
      };

  factory SoloProfile.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final legacySoloStart = json['soloStartDate'] != null
        ? DateTime.parse(json['soloStartDate'] as String)
        : null;

    final selfCareDate = json['selfCareStartDate'] != null
        ? DateTime.parse(json['selfCareStartDate'] as String)
        : (legacySoloStart ?? now.subtract(const Duration(days: 30)));

    final crushDate = json['crushStartDate'] != null
        ? DateTime.parse(json['crushStartDate'] as String)
        : now.subtract(const Duration(days: 7));

    return SoloProfile(
      mode: SoloMode.fromJson(json['mode'] as String?),
      selfCareStartDate: selfCareDate,
      crushStartDate: crushDate,
      showTopCard: json['showTopCard'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            '나홀로여행',
            '바디프로필',
            '취미/운동',
            '새출발',
            '데이트/소개팅',
          ],
    );
  }
}
