import 'package:flutter/foundation.dart';

/// 아기 성별
enum BabyGender {
  boy,
  girl,
  none;

  String toJson() => name;

  static BabyGender fromJson(String? value) {
    return BabyGender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BabyGender.none,
    );
  }

  String get label => switch (this) {
        BabyGender.boy => '남아 🩵',
        BabyGender.girl => '여아 🩷',
        BabyGender.none => '미지정',
      };
}

/// 케어 타임로그 유형 (4대 필수 케어)
enum BabyCareLogType {
  feeding,
  babyFood,
  sleep,
  diaper;

  String toJson() => name;

  static BabyCareLogType fromJson(String? value) {
    return BabyCareLogType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BabyCareLogType.feeding,
    );
  }

  String get label => switch (this) {
        BabyCareLogType.feeding => '수유',
        BabyCareLogType.babyFood => '이유식',
        BabyCareLogType.sleep => '수면',
        BabyCareLogType.diaper => '기저귀',
      };

  String get emoji => switch (this) {
        BabyCareLogType.feeding => '🍼',
        BabyCareLogType.babyFood => '🥣',
        BabyCareLogType.sleep => '💤',
        BabyCareLogType.diaper => '👶',
      };
}

/// 개별 케어 타임로그 아이템
@immutable
class BabyCareLogItem {
  const BabyCareLogItem({
    required this.id,
    required this.type,
    required this.timestamp,
    this.amount,
    this.subType,
    this.durationMinutes,
    this.memo,
  });

  final String id;
  final BabyCareLogType type;
  final DateTime timestamp;
  final double? amount; // ml for feeding, g for babyFood
  final String? subType; // 모유/분유/유축, 대변/소변/대소변, 낮잠/밤잠
  final int? durationMinutes; // 수면 시간
  final String? memo;

  BabyCareLogItem copyWith({
    String? id,
    BabyCareLogType? type,
    DateTime? timestamp,
    double? amount,
    String? subType,
    int? durationMinutes,
    String? memo,
  }) {
    return BabyCareLogItem(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      subType: subType ?? this.subType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'timestamp': timestamp.toIso8601String(),
        if (amount != null) 'amount': amount,
        if (subType != null) 'subType': subType,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (memo != null) 'memo': memo,
      };

  factory BabyCareLogItem.fromJson(Map<String, dynamic> json) {
    return BabyCareLogItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: BabyCareLogType.fromJson(json['type'] as String?),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble(),
      subType: json['subType'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      memo: json['memo'] as String?,
    );
  }
}

/// 국가 필수 예방접종 접종 차수 모델
@immutable
class VaccineDose {
  const VaccineDose({
    required this.id,
    required this.name,
    required this.disease,
    required this.recommendedAgeMonths,
    required this.recommendedAgeLabel,
    this.isCompleted = false,
    this.completedDate,
    this.memo,
  });

  final String id;
  final String name; // e.g., 'BCG (피내/경피)', 'B형간염 1차', 'DTaP 1차'
  final String disease; // e.g., '결핵', 'B형간염', '디프테리아/파상풍/백일해'
  final int recommendedAgeMonths; // 권장 개월수 (0, 1, 2, 4, 6, 12, 15, 18, 24, 48, 72, 132, 144)
  final String recommendedAgeLabel; // e.g., '생후 4주 이내', '1개월', '2개월'
  final bool isCompleted;
  final DateTime? completedDate;
  final String? memo;

  VaccineDose copyWith({
    String? id,
    String? name,
    String? disease,
    int? recommendedAgeMonths,
    String? recommendedAgeLabel,
    bool? isCompleted,
    DateTime? completedDate,
    String? memo,
  }) {
    return VaccineDose(
      id: id ?? this.id,
      name: name ?? this.name,
      disease: disease ?? this.disease,
      recommendedAgeMonths: recommendedAgeMonths ?? this.recommendedAgeMonths,
      recommendedAgeLabel: recommendedAgeLabel ?? this.recommendedAgeLabel,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'disease': disease,
        'recommendedAgeMonths': recommendedAgeMonths,
        'recommendedAgeLabel': recommendedAgeLabel,
        'isCompleted': isCompleted,
        if (completedDate != null) 'completedDate': completedDate!.toIso8601String(),
        if (memo != null) 'memo': memo,
      };

  factory VaccineDose.fromJson(Map<String, dynamic> json) {
    return VaccineDose(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      disease: json['disease'] as String? ?? '',
      recommendedAgeMonths: json['recommendedAgeMonths'] as int? ?? 0,
      recommendedAgeLabel: json['recommendedAgeLabel'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      memo: json['memo'] as String?,
    );
  }
}

/// 국가 영유아 건강검진 차수 모델 (1~8차)
@immutable
class HealthCheckupDose {
  const HealthCheckupDose({
    required this.stage,
    required this.name,
    required this.startDays,
    required this.endDays,
    required this.periodLabel,
    this.isCompleted = false,
    this.completedDate,
    this.memo,
  });

  final int stage; // 1 ~ 8
  final String name; // e.g., '1차 영유아 건강검진'
  final int startDays; // e.g., 14
  final int endDays; // e.g., 35
  final String periodLabel; // e.g., '생후 14~35일', '생후 4~6개월'
  final bool isCompleted;
  final DateTime? completedDate;
  final String? memo;

  HealthCheckupDose copyWith({
    int? stage,
    String? name,
    int? startDays,
    int? endDays,
    String? periodLabel,
    bool? isCompleted,
    DateTime? completedDate,
    String? memo,
  }) {
    return HealthCheckupDose(
      stage: stage ?? this.stage,
      name: name ?? this.name,
      startDays: startDays ?? this.startDays,
      endDays: endDays ?? this.endDays,
      periodLabel: periodLabel ?? this.periodLabel,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'name': name,
        'startDays': startDays,
        'endDays': endDays,
        'periodLabel': periodLabel,
        'isCompleted': isCompleted,
        if (completedDate != null) 'completedDate': completedDate!.toIso8601String(),
        if (memo != null) 'memo': memo,
      };

  factory HealthCheckupDose.fromJson(Map<String, dynamic> json) {
    return HealthCheckupDose(
      stage: json['stage'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      startDays: json['startDays'] as int? ?? 0,
      endDays: json['endDays'] as int? ?? 0,
      periodLabel: json['periodLabel'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      memo: json['memo'] as String?,
    );
  }
}

/// 아기 신체 성장 측정 기록 (키, 몸무게, 머리둘레)
@immutable
class GrowthRecord {
  const GrowthRecord({
    required this.id,
    required this.date,
    this.heightCm,
    this.weightKg,
    this.headCircumferenceCm,
    this.memo,
  });

  final String id;
  final DateTime date;
  final double? heightCm;
  final double? weightKg;
  final double? headCircumferenceCm;
  final String? memo;

  GrowthRecord copyWith({
    String? id,
    DateTime? date,
    double? heightCm,
    double? weightKg,
    double? headCircumferenceCm,
    String? memo,
  }) {
    return GrowthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (headCircumferenceCm != null) 'headCircumferenceCm': headCircumferenceCm,
        if (memo != null) 'memo': memo,
      };

  factory GrowthRecord.fromJson(Map<String, dynamic> json) {
    return GrowthRecord(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      headCircumferenceCm: (json['headCircumferenceCm'] as num?)?.toDouble(),
      memo: json['memo'] as String?,
    );
  }
}

/// 아기 상세 종합 프로필
@immutable
class BabyProfile {
  const BabyProfile({
    required this.name,
    required this.birthDate,
    this.birthTime,
    this.gender = BabyGender.none,
    this.bloodType,
    this.photoUrl,
    this.feedingIntervalHours = 3,
    this.careLogs = const [],
    this.vaccineDoses = const [],
    this.checkupDoses = const [],
    this.growthRecords = const [],
  });

  final String name;
  final DateTime birthDate;
  final String? birthTime; // e.g. '14:30'
  final BabyGender gender;
  final String? bloodType; // 'A', 'B', 'O', 'AB'
  final String? photoUrl;
  final int feedingIntervalHours; // default 3 hours
  final List<BabyCareLogItem> careLogs;
  final List<VaccineDose> vaccineDoses;
  final List<HealthCheckupDose> checkupDoses;
  final List<GrowthRecord> growthRecords;

  BabyProfile copyWith({
    String? name,
    DateTime? birthDate,
    String? birthTime,
    BabyGender? gender,
    String? bloodType,
    String? photoUrl,
    int? feedingIntervalHours,
    List<BabyCareLogItem>? careLogs,
    List<VaccineDose>? vaccineDoses,
    List<HealthCheckupDose>? checkupDoses,
    List<GrowthRecord>? growthRecords,
  }) {
    return BabyProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      photoUrl: photoUrl ?? this.photoUrl,
      feedingIntervalHours: feedingIntervalHours ?? this.feedingIntervalHours,
      careLogs: careLogs ?? this.careLogs,
      vaccineDoses: vaccineDoses ?? this.vaccineDoses,
      checkupDoses: checkupDoses ?? this.checkupDoses,
      growthRecords: growthRecords ?? this.growthRecords,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        if (birthTime != null) 'birthTime': birthTime,
        'gender': gender.toJson(),
        if (bloodType != null) 'bloodType': bloodType,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'feedingIntervalHours': feedingIntervalHours,
        'careLogs': careLogs.map((c) => c.toJson()).toList(),
        'vaccineDoses': vaccineDoses.map((v) => v.toJson()).toList(),
        'checkupDoses': checkupDoses.map((h) => h.toJson()).toList(),
        'growthRecords': growthRecords.map((g) => g.toJson()).toList(),
      };

  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    return BabyProfile(
      name: json['name'] as String? ?? json['babyName'] as String? ?? '우리 아기 👶',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now().subtract(const Duration(days: 100)),
      birthTime: json['birthTime'] as String?,
      gender: BabyGender.fromJson(json['gender'] as String?),
      bloodType: json['bloodType'] as String?,
      photoUrl: json['photoUrl'] as String?,
      feedingIntervalHours: json['feedingIntervalHours'] as int? ?? 3,
      careLogs: (json['careLogs'] as List<dynamic>?)
              ?.map((e) => BabyCareLogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      vaccineDoses: (json['vaccineDoses'] as List<dynamic>?)
              ?.map((e) => VaccineDose.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checkupDoses: (json['checkupDoses'] as List<dynamic>?)
              ?.map((e) => HealthCheckupDose.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      growthRecords: (json['growthRecords'] as List<dynamic>?)
              ?.map((e) => GrowthRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
