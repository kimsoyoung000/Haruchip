import 'package:flutter/foundation.dart';

/// 디데이 항목 표시 방식
enum DDayDisplayType {
  dday, // D-34
  daysCount, // 250일째
  monthsCount; // 경과 개월수

  String toJson() => name;

  static DDayDisplayType fromJson(String value) {
    return DDayDisplayType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DDayDisplayType.dday,
    );
  }
}

/// 디데이 반복 유형
enum DDayRepeatType {
  none,
  weekly,
  yearly,
  monthly,
  weekend;

  String toJson() => name;

  static DDayRepeatType fromJson(String value) {
    return DDayRepeatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DDayRepeatType.none,
    );
  }
}

/// 공통 디데이 데이터 모델 (DDayModel)
@immutable
class DDayModel {
  const DDayModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.targetDate,
    this.displayType = DDayDisplayType.dday,
    this.repeatType = DDayRepeatType.none,
    this.isCalendarSynced = false,
    this.linkedGroupId,
    this.isPredictiveListed = false,
    this.typeSpecificData,
    this.categoryKey = '',
  });

  final String id;
  final String categoryId;
  final String title;
  final DateTime targetDate;
  final DDayDisplayType displayType;
  final DDayRepeatType repeatType;
  final bool isCalendarSynced;
  final String? linkedGroupId;
  final bool isPredictiveListed;
  final Map<String, dynamic>? typeSpecificData;
  final String categoryKey;

  DDayModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    DateTime? targetDate,
    DDayDisplayType? displayType,
    DDayRepeatType? repeatType,
    bool? isCalendarSynced,
    String? linkedGroupId,
    bool? isPredictiveListed,
    Map<String, dynamic>? typeSpecificData,
    String? categoryKey,
  }) {
    return DDayModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      displayType: displayType ?? this.displayType,
      repeatType: repeatType ?? this.repeatType,
      isCalendarSynced: isCalendarSynced ?? this.isCalendarSynced,
      linkedGroupId: linkedGroupId ?? this.linkedGroupId,
      isPredictiveListed: isPredictiveListed ?? this.isPredictiveListed,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      categoryKey: categoryKey ?? this.categoryKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'title': title,
        'targetDate': targetDate.toIso8601String(),
        'displayType': displayType.toJson(),
        'repeatType': repeatType.toJson(),
        'isCalendarSynced': isCalendarSynced,
        'linkedGroupId': linkedGroupId,
        'isPredictiveListed': isPredictiveListed,
        'typeSpecificData': typeSpecificData,
        'categoryKey': categoryKey,
      };

  factory DDayModel.fromJson(Map<String, dynamic> json) {
    return DDayModel(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : DateTime.now(),
      displayType: DDayDisplayType.fromJson(json['displayType'] as String? ?? ''),
      repeatType: DDayRepeatType.fromJson(json['repeatType'] as String? ?? ''),
      isCalendarSynced: json['isCalendarSynced'] as bool? ?? false,
      linkedGroupId: json['linkedGroupId'] as String?,
      isPredictiveListed: json['isPredictiveListed'] as bool? ?? false,
      typeSpecificData: json['typeSpecificData'] as Map<String, dynamic>?,
      categoryKey: json['categoryKey'] as String? ?? '',
    );
  }
}
