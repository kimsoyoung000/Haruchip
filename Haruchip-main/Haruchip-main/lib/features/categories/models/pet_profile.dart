import 'dart:convert';
import 'package:flutter/material.dart';

/// 1단계 대분류 및 2단계 세부 품종 데이터 구조
class PetCategoryOption {
  const PetCategoryOption({
    required this.categoryKey,
    required this.label,
    required this.icon,
    required this.subBreeds,
  });

  final String categoryKey;
  final String label;
  final String icon;
  final List<String> subBreeds;

  String get categoryName => label;
  List<String> get breeds => subBreeds;
}

const List<PetCategoryOption> kPetCategories = [
  PetCategoryOption(
    categoryKey: 'dog',
    label: '강아지',
    icon: '🐶',
    subBreeds: [
      '말티즈',
      '푸들',
      '포메라니안',
      '비숑 프리제',
      '시바견',
      '진돗개',
      '골든 리트리버',
      '닥스훈트',
      '치와와',
      '프렌치 불독',
      '믹스견',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'cat',
    label: '고양이',
    icon: '🐱',
    subBreeds: [
      '코리안 숏헤어',
      '페르시안',
      '러시안 블루',
      '샴',
      '브리티시 숏헤어',
      '랙돌',
      '스코티시 폴드',
      '노르웨이 숲',
      '벵갈',
      '터키시 앙고라',
      '믹스묘',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'rabbit',
    label: '토끼',
    icon: '🐰',
    subBreeds: [
      '드워프 토끼',
      '롭이어',
      '라이언헤드',
      '렉스',
      '네덜란드 드워프',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'hamster',
    label: '햄스터',
    icon: '🐹',
    subBreeds: [
      '골든 햄스터',
      '드워프 햄스터(정글리안/펄/푸딩)',
      '로보로브스키',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'bird',
    label: '앵무새',
    icon: '🦜',
    subBreeds: [
      '사랑앵무(세키세이)',
      '모란앵무',
      '왕관앵무',
      '코뉴어',
      '카카리키',
      '회색앵무',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'reptile',
    label: '파충류/양서류',
    icon: '🦎',
    subBreeds: [
      '크레스티드 게코',
      '레오파드 게코',
      '비어디드 드래곤',
      '거북이',
      '뱀',
      '개구리/팩맨',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'fish',
    label: '물고기(관상어)',
    icon: '🐠',
    subBreeds: [
      '구피',
      '베타',
      '금붕어',
      '네온 테트라',
      '엔젤피쉬',
      '디스커스',
      '시클리드',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'hedgehog',
    label: '고슴도치',
    icon: '🦔',
    subBreeds: [
      '플라티나',
      '스탠다드',
      '화이트초코',
      '스노우샴페인',
      '알비노',
      '기타 (직접 입력)',
    ],
  ),
  PetCategoryOption(
    categoryKey: 'other',
    label: '기타/소동물',
    icon: '🐾',
    subBreeds: [
      '페럿',
      '친칠라',
      '슈가글라이더',
      '기니피그',
      '다람쥐',
      '기타 (직접 입력)',
    ],
  ),
];

// 하위 호환용 alias
typedef PetIconOption = PetCategoryOption;
const List<PetCategoryOption> kPetIconOptions = kPetCategories;

/// 프로필 이미지 로더 (base64 data URL, http URL, asset 지원)
ImageProvider? getPetAvatarImageProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('data:image')) {
    try {
      final base64String = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
      return MemoryImage(base64Decode(base64String));
    } catch (_) {
      return null;
    }
  } else if (photoUrl.startsWith('http')) {
    return NetworkImage(photoUrl);
  } else {
    return AssetImage(photoUrl);
  }
}


/// 반려동물 패밀리 프로필 데이터 모델
@immutable
class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    this.species = '강아지',
    this.icon = '🐶',
    this.photoUrl,
    this.personality = '',
    required this.adoptionDate,
    this.birthDate,
    this.isBirthUnknown = false,
    this.approxAgeText = '',
    this.colorHex,
  });

  final String id;
  final String name;
  final String species;
  final String icon;
  final String? photoUrl;
  final String personality;
  final DateTime adoptionDate;
  final DateTime? birthDate;
  final bool isBirthUnknown;
  final String approxAgeText;
  final String? colorHex;

  /// 함께한 지 N일째 (데려온 날부터 오늘까지의 일수)
  int get daysTogether {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(adoptionDate.year, adoptionDate.month, adoptionDate.day);
    final diff = today.difference(start).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  /// 태어난 지 N일째 (생일부터 오늘까지의 일수)
  int? get daysSinceBirth {
    if (birthDate == null || isBirthUnknown) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bDay = DateTime(birthDate!.year, birthDate!.month, birthDate!.day);
    final diff = today.difference(bDay).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  /// 다가오는 다음 생일 날짜 (매년 롤링 계산)
  /// 당일(D-Day)이 지나면(D+1) 자동으로 내년 생일 기준으로 롤링 계산
  DateTime? get nextUpcomingBirthday {
    if (birthDate == null || isBirthUnknown) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisYearBirthday = DateTime(today.year, birthDate!.month, birthDate!.day);

    if (thisYearBirthday.isBefore(today)) {
      return DateTime(today.year + 1, birthDate!.month, birthDate!.day);
    }
    return thisYearBirthday;
  }

  /// 다가오는 다음 생일까지 남은 D-Day (D-0 -> D-Day, D-N 등)
  int? get daysUntilNextBirthday {
    final nextBday = nextUpcomingBirthday;
    if (nextBday == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextBday.difference(today).inDays;
  }

  /// 생일 D-Day 텍스트 라벨 (예: D-Day, D-120 등)
  String? get nextBirthdayDDayLabel {
    final days = daysUntilNextBirthday;
    if (days == null) return null;
    if (days == 0) return 'D-day';
    return 'D-$days';
  }

  /// 나이 포맷 텍스트 (예: '2살 3개월', '추정 3살')
  String get formattedAge {
    if (isBirthUnknown) {
      return approxAgeText.isNotEmpty ? '추정 $approxAgeText' : '생일 모름';
    }
    if (birthDate == null) return '생일 모름';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bDay = DateTime(birthDate!.year, birthDate!.month, birthDate!.day);

    var years = today.year - bDay.year;
    var months = today.month - bDay.month;
    if (today.day < bDay.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years <= 0) {
      return months <= 0 ? '1개월 미만' : '$months개월';
    }
    if (months == 0) {
      return '$years살';
    }
    return '$years살 $months개월';
  }

  PetProfile copyWith({
    String? id,
    String? name,
    String? species,
    String? icon,
    String? photoUrl,
    String? personality,
    DateTime? adoptionDate,
    DateTime? birthDate,
    bool? isBirthUnknown,
    String? approxAgeText,
    String? colorHex,
  }) {
    return PetProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      icon: icon ?? this.icon,
      photoUrl: photoUrl ?? this.photoUrl,
      personality: personality ?? this.personality,
      adoptionDate: adoptionDate ?? this.adoptionDate,
      birthDate: birthDate ?? this.birthDate,
      isBirthUnknown: isBirthUnknown ?? this.isBirthUnknown,
      approxAgeText: approxAgeText ?? this.approxAgeText,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'icon': icon,
        'photoUrl': photoUrl,
        'personality': personality,
        'adoptionDate': adoptionDate.toIso8601String(),
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
        'isBirthUnknown': isBirthUnknown,
        'approxAgeText': approxAgeText,
        'colorHex': colorHex,
      };

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: json['id'] as String? ?? 'pet_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '댕댕이',
      species: json['species'] as String? ?? '강아지',
      icon: json['icon'] as String? ?? '🐶',
      photoUrl: json['photoUrl'] as String?,
      personality: json['personality'] as String? ?? '',
      adoptionDate: json['adoptionDate'] != null
          ? DateTime.parse(json['adoptionDate'] as String)
          : DateTime.now().subtract(const Duration(days: 200)),
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      isBirthUnknown: json['isBirthUnknown'] as bool? ?? false,
      approxAgeText: json['approxAgeText'] as String? ?? '',
      colorHex: json['colorHex'] as String?,
    );
  }
}
