import 'package:flutter/material.dart';

/// 친구 프로필 아바타 타입 (방식 A/B/C)
enum BirthdayAvatarType {
  photo, // 방식 A: 갤러리/카메라 사진
  emoji, // 방식 B: OS 기본/캐릭터 이모티콘
  customAvatar; // 방식 C: 2D 커스텀 아바타

  String toJson() => name;
  static BirthdayAvatarType fromJson(String value) {
    return BirthdayAvatarType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BirthdayAvatarType.emoji,
    );
  }
}

/// 아기자기한 2D 커스텀 아바타 제작 속성 모델
@immutable
class CustomAvatarConfig {
  const CustomAvatarConfig({
    this.faceShape = 'round',
    this.skinColor = '#FFE0BD',
    this.hairStyle = 'short',
    this.hairColor = '#2C1D11',
    this.expression = 'smile',
    this.accessory = 'none',
    this.bgColor = '#FFE4E6',
  });

  final String faceShape; // round(둥근형), egg(달걀형), square(부드러운 사각)
  final String skinColor; // 피부 톤
  final String hairStyle; // short, long, wave, ponytail, bun, bangs, curly, dandy
  final String hairColor; // 머리 색상
  final String expression; // smile(미소), wink(윙크), sparkle(반짝), blush(발그레), cool(시크), peace(뿌듯)
  final String accessory; // none, glasses_round, glasses_square, ribbon, beret, party_hat, star, heart
  final String bgColor; // 배경 컬러

  CustomAvatarConfig copyWith({
    String? faceShape,
    String? skinColor,
    String? hairStyle,
    String? hairColor,
    String? expression,
    String? accessory,
    String? bgColor,
  }) {
    return CustomAvatarConfig(
      faceShape: faceShape ?? this.faceShape,
      skinColor: skinColor ?? this.skinColor,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      expression: expression ?? this.expression,
      accessory: accessory ?? this.accessory,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'faceShape': faceShape,
        'skinColor': skinColor,
        'hairStyle': hairStyle,
        'hairColor': hairColor,
        'expression': expression,
        'accessory': accessory,
        'bgColor': bgColor,
      };

  factory CustomAvatarConfig.fromJson(Map<String, dynamic> json) {
    return CustomAvatarConfig(
      faceShape: json['faceShape'] as String? ?? 'round',
      skinColor: json['skinColor'] as String? ?? '#FFE0BD',
      hairStyle: json['hairStyle'] as String? ?? 'short',
      hairColor: json['hairColor'] as String? ?? '#2C1D11',
      expression: json['expression'] as String? ?? 'smile',
      accessory: json['accessory'] as String? ?? 'none',
      bgColor: json['bgColor'] as String? ?? '#FFE4E6',
    );
  }
}

/// 친구 생일 프로필 모델
@immutable
class BirthdayProfile {
  const BirthdayProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    this.hasYear = true,
    this.isLunar = false,
    this.avatarType = BirthdayAvatarType.emoji,
    this.photoUrl,
    this.emoji = '🎂',
    this.avatarConfig,
    this.memo,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final bool hasYear; // 연도 미포함 토글 (false 시 월/일만)
  final bool isLunar; // 음력 생일 여부
  final BirthdayAvatarType avatarType;
  final String? photoUrl; // 사진 URL 또는 base64
  final String? emoji; // 이모티콘
  final CustomAvatarConfig? avatarConfig; // 2D 커스텀 아바타
  final String? memo;

  /// 다가오는 다음 생일 날짜 (당일 지나면 D-365 자동 롤링)
  DateTime nextBirthdayDate([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isLunar) {
      // 음력은 양력 근사치 또는 매년 양력 변환
      // 음력 날짜를 양력으로 변환할 때 통상 25~45일 정도 뒤에 위치
      var solarCandidate = _approximateLunarToSolar(today.year, birthDate.month, birthDate.day);
      if (solarCandidate.isBefore(today)) {
        solarCandidate = _approximateLunarToSolar(today.year + 1, birthDate.month, birthDate.day);
      }
      return solarCandidate;
    }

    var candidate = DateTime(today.year, birthDate.month, birthDate.day);
    if (candidate.isBefore(today)) {
      candidate = DateTime(today.year + 1, birthDate.month, birthDate.day);
    }
    return candidate;
  }

  /// 음력 -> 양력 변환 (한국 천문연구원 음양력 알고리즘 근사치)
  DateTime _approximateLunarToSolar(int year, int lunarMonth, int lunarDay) {
    // 윤달 및 음력 편차 보정 (+29일 기본 오프셋 기준 유효 날짜 계산)
    final base = DateTime(year, lunarMonth, lunarDay);
    final approxSolar = base.add(const Duration(days: 29));
    return DateTime(year, approxSolar.month, approxSolar.day);
  }

  /// 남은 일수 계산
  int dDay([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = nextBirthdayDate(now);
    final targetOnly = DateTime(target.year, target.month, target.day);
    return targetOnly.difference(today).inDays;
  }

  /// D-Day 라벨 (당일 지나면 D-365 롤링)
  String dDayLabel([DateTime? relativeTo]) {
    final diff = dDay(relativeTo);
    if (diff == 0) return 'D-Day';
    return 'D-$diff';
  }

  /// 생년월일 포맷팅 텍스트 (YYYY.MM.DD 또는 MM.DD)
  String formattedBirthDate() {
    final m = birthDate.month.toString().padLeft(2, '0');
    final d = birthDate.day.toString().padLeft(2, '0');
    final lunarBadge = isLunar ? ' (음력)' : '';

    if (!hasYear) {
      return '$m.$d$lunarBadge';
    }
    return '${birthDate.year}.$m.$d$lunarBadge';
  }

  /// 만 나이 계산
  String? formattedAge([DateTime? relativeTo]) {
    if (!hasYear) return null;
    final now = relativeTo ?? DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? '만 $age세' : null;
  }

  BirthdayProfile copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    bool? hasYear,
    bool? isLunar,
    BirthdayAvatarType? avatarType,
    String? photoUrl,
    String? emoji,
    CustomAvatarConfig? avatarConfig,
    String? memo,
  }) {
    return BirthdayProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      hasYear: hasYear ?? this.hasYear,
      isLunar: isLunar ?? this.isLunar,
      avatarType: avatarType ?? this.avatarType,
      photoUrl: photoUrl ?? this.photoUrl,
      emoji: emoji ?? this.emoji,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'hasYear': hasYear,
        'isLunar': isLunar,
        'avatarType': avatarType.toJson(),
        'photoUrl': photoUrl,
        'emoji': emoji,
        'avatarConfig': avatarConfig?.toJson(),
        'memo': memo,
      };

  factory BirthdayProfile.fromJson(Map<String, dynamic> json) {
    return BirthdayProfile(
      id: json['id'] as String? ?? 'bday-${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '친구',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime(2000, 1, 1),
      hasYear: json['hasYear'] as bool? ?? true,
      isLunar: json['isLunar'] as bool? ?? false,
      avatarType: BirthdayAvatarType.fromJson(json['avatarType'] as String? ?? 'emoji'),
      photoUrl: json['photoUrl'] as String?,
      emoji: json['emoji'] as String? ?? '🎂',
      avatarConfig: json['avatarConfig'] != null
          ? CustomAvatarConfig.fromJson(Map<String, dynamic>.from(json['avatarConfig'] as Map))
          : null,
      memo: json['memo'] as String?,
    );
  }
}

/// 기본 목업 친구 목록 (최초 진입 시)
final List<BirthdayProfile> kDefaultMockBirthdayFriends = [
  BirthdayProfile(
    id: 'bday-mock-1',
    name: '엄마 🌸',
    birthDate: DateTime(1972, 10, 12),
    hasYear: true,
    isLunar: false,
    avatarType: BirthdayAvatarType.customAvatar,
    avatarConfig: const CustomAvatarConfig(
      faceShape: 'egg',
      skinColor: '#FFE0BD',
      hairStyle: 'wave',
      hairColor: '#5C3A21',
      expression: 'smile',
      accessory: 'ribbon',
      bgColor: '#FFE4E6',
    ),
  ),
  BirthdayProfile(
    id: 'bday-mock-2',
    name: '베프 지민',
    birthDate: DateTime(2001, 11, 4),
    hasYear: true,
    isLunar: false,
    avatarType: BirthdayAvatarType.customAvatar,
    avatarConfig: const CustomAvatarConfig(
      faceShape: 'round',
      skinColor: '#FFE0BD',
      hairStyle: 'ponytail',
      hairColor: '#2C1D11',
      expression: 'wink',
      accessory: 'glasses_round',
      bgColor: '#FEF08A',
    ),
  ),
  BirthdayProfile(
    id: 'bday-mock-3',
    name: '민수',
    birthDate: DateTime(2003, 5, 20),
    hasYear: true,
    isLunar: false,
    avatarType: BirthdayAvatarType.emoji,
    emoji: '👦',
  ),
  BirthdayProfile(
    id: 'bday-mock-4',
    name: '하은 언니',
    birthDate: DateTime(1998, 8, 15),
    hasYear: true,
    isLunar: false,
    avatarType: BirthdayAvatarType.customAvatar,
    avatarConfig: const CustomAvatarConfig(
      faceShape: 'round',
      skinColor: '#F5D0A9',
      hairStyle: 'bun',
      hairColor: '#8B5A2B',
      expression: 'sparkle',
      accessory: 'heart',
      bgColor: '#F3E8FF',
    ),
  ),
];
