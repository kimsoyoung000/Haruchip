import 'package:flutter/foundation.dart';
import '../models/dday_model.dart';

/// 반려동물 종류
enum PetSpecies {
  dog,
  cat,
  hamster,
  rabbit,
  parrot,
  other;

  String get icon => switch (this) {
        PetSpecies.dog => '🐶',
        PetSpecies.cat => '🐱',
        PetSpecies.hamster => '🐹',
        PetSpecies.rabbit => '🐰',
        PetSpecies.parrot => '🦜',
        PetSpecies.other => '🐾',
      };

  String get labelKo => switch (this) {
        PetSpecies.dog => '강아지',
        PetSpecies.cat => '고양이',
        PetSpecies.hamster => '햄스터',
        PetSpecies.rabbit => '토끼',
        PetSpecies.parrot => '앵무새',
        PetSpecies.other => '반려동물',
      };
}

/// 케어 유형 (사료, 산책, 병원)
enum PetCareType {
  feed,
  walk,
  hospital,
  custom;

  String get defaultEmoji => switch (this) {
        PetCareType.feed => '🍖',
        PetCareType.walk => '🦮',
        PetCareType.hospital => '🏥',
        PetCareType.custom => '📌',
      };

  String get defaultTitle => switch (this) {
        PetCareType.feed => '사료 구매',
        PetCareType.walk => '정기 산책',
        PetCareType.hospital => '병원 접종',
        PetCareType.custom => '케어 일정',
      };
}

/// 케어 일정 1건
@immutable
class PetCareSchedule {
  const PetCareSchedule({
    required this.id,
    required this.title,
    required this.type,
    required this.targetDate,
    this.repeatType = DDayRepeatType.monthly,
  });

  final String id;
  final String title;
  final PetCareType type;
  final DateTime targetDate;
  final DDayRepeatType repeatType;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'targetDate': targetDate.toIso8601String(),
        'repeatType': repeatType.toJson(),
      };

  factory PetCareSchedule.fromJson(Map<String, dynamic> json) {
    return PetCareSchedule(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: PetCareType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PetCareType.custom,
      ),
      targetDate: DateTime.parse(json['targetDate'] as String),
      repeatType: DDayRepeatType.fromJson(json['repeatType'] as String? ?? ''),
    );
  }
}

/// 반려동물 카테고리 컨트롤러 (패밀리 프로필 UI & 대표 아이콘 & 케어 일정 D-Day 칩)
class PetCategoryController {
  const PetCategoryController();

  /// 사용 가능한 전용 대표 아이콘 목록 반환
  List<({PetSpecies species, String icon, String labelKo})> getAvailableIcons() {
    return PetSpecies.values
        .map((s) => (species: s, icon: s.icon, labelKo: s.labelKo))
        .toList();
  }

  /// 케어 일정을 DDayModel로 연동 생성
  DDayModel createCareDDay({
    required String categoryId,
    required String petName,
    required PetCareSchedule schedule,
  }) {
    return DDayModel(
      id: schedule.id,
      categoryId: categoryId,
      categoryKey: 'pet',
      title: '[$petName] ${schedule.title}',
      targetDate: schedule.targetDate,
      displayType: DDayDisplayType.dday,
      repeatType: schedule.repeatType,
      isPredictiveListed: true,
      typeSpecificData: {
        'careType': schedule.type.name,
        'petName': petName,
      },
    );
  }
}
