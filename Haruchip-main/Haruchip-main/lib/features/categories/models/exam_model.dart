import 'package:flutter/foundation.dart';

/// 시험 대분류 유형
enum ExamType {
  qualification, // 자격증 / 어학 / 공무원 / 입시 (다단계 파이프라인)
  midterm, // 중간고사 (과목별 타임테이블)
  finalExam, // 기말고사 (과목별 타임테이블)
  custom; // 직접 입력

  String get labelKo => switch (this) {
        ExamType.qualification => '자격증 / 공인시험',
        ExamType.midterm => '중간고사',
        ExamType.finalExam => '기말고사',
        ExamType.custom => '직접 입력',
      };

  String get emoji => switch (this) {
        ExamType.qualification => '📜',
        ExamType.midterm => '📝',
        ExamType.finalExam => '🎓',
        ExamType.custom => '📌',
      };
}

/// 시험 세부 단계 유형 (4~5단계 핵심 플로우)
enum ExamStageType {
  application, // 원서 접수 (시작/마감)
  writtenTest, // 필기 시험 / 본 시험
  writtenResult, // 필기 합격 발표 / 성적 발표
  practicalTest, // 실기 시험 / 면접
  finalResult; // 최종 합격 발표

  String get labelKo => switch (this) {
        ExamStageType.application => '원서 접수',
        ExamStageType.writtenTest => '필기 시험',
        ExamStageType.writtenResult => '필기 발표',
        ExamStageType.practicalTest => '실기 / 면접',
        ExamStageType.finalResult => '최종 합격 발표',
      };

  String get shortLabel => switch (this) {
        ExamStageType.application => '원서접수',
        ExamStageType.writtenTest => '필기시험',
        ExamStageType.writtenResult => '필기발표',
        ExamStageType.practicalTest => '실기/면접',
        ExamStageType.finalResult => '최종합격',
      };

  String get defaultEmoji => switch (this) {
        ExamStageType.application => '📋',
        ExamStageType.writtenTest => '✍️',
        ExamStageType.writtenResult => '📢',
        ExamStageType.practicalTest => '🛠️',
        ExamStageType.finalResult => '🎉',
      };

  /// 시험을 치르는 메인 시험일인가?
  bool get isExamDay =>
      this == ExamStageType.writtenTest || this == ExamStageType.practicalTest;
}

/// 단일 시험의 단계별 항목 (원서접수 -> 필기 -> 발표 -> 실기 -> 최종)
@immutable
class ExamStageItem {
  const ExamStageItem({
    required this.id,
    required this.stageType,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isCompleted = false,
    this.testTime,
    this.location,
    this.seatNumber,
    this.registrationNumber,
    this.checklist = const [],
    this.memo,
  });

  final String id;
  final ExamStageType stageType;
  final String name; // e.g. '원서접수 마감', '1차 필기시험', '최종 합격 발표'
  final DateTime startDate;
  final DateTime? endDate; // 접수 기간 마감일 등
  final bool isCompleted;
  final String? testTime; // e.g. '09:30 ~ 11:30' (입실 09:10)
  final String? location; // e.g. '서울공업고등학교 3고사장'
  final String? seatNumber; // e.g. '15번 좌석'
  final String? registrationNumber; // e.g. '12345678'
  final List<String> checklist; // e.g. ['신분증', '컴퓨터용 사인펜', '수정테이프']
  final String? memo;

  /// 오늘 기준 종료 여부 (endDate가 있으면 endDate 기준, 없으면 startDate 기준)
  bool isEnded([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = endDate ?? startDate;
    final targetDate = DateTime(target.year, target.month, target.day);
    return targetDate.isBefore(today);
  }

  /// D-Day 잔여일수
  int daysRemaining([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = (stageType == ExamStageType.application && endDate != null)
        ? endDate!
        : startDate;
    final targetDate = DateTime(target.year, target.month, target.day);
    return targetDate.difference(today).inDays;
  }

  ExamStageItem copyWith({
    String? id,
    ExamStageType? stageType,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    String? testTime,
    String? location,
    String? seatNumber,
    String? registrationNumber,
    List<String>? checklist,
    String? memo,
  }) {
    return ExamStageItem(
      id: id ?? this.id,
      stageType: stageType ?? this.stageType,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      testTime: testTime ?? this.testTime,
      location: location ?? this.location,
      seatNumber: seatNumber ?? this.seatNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      checklist: checklist ?? this.checklist,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageType': stageType.name,
        'name': name,
        'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'isCompleted': isCompleted,
        if (testTime != null) 'testTime': testTime,
        if (location != null) 'location': location,
        if (seatNumber != null) 'seatNumber': seatNumber,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (checklist.isNotEmpty) 'checklist': checklist,
        if (memo != null) 'memo': memo,
      };

  factory ExamStageItem.fromJson(Map<String, dynamic> json) {
    return ExamStageItem(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      stageType: ExamStageType.values.firstWhere(
        (e) => e.name == json['stageType'],
        orElse: () => ExamStageType.writtenTest,
      ),
      name: json['name'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      testTime: json['testTime'] as String?,
      location: json['location'] as String?,
      seatNumber: json['seatNumber'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      checklist: (json['checklist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      memo: json['memo'] as String?,
    );
  }
}

/// 학교 시험 과목별 타임테이블 항목 (중간고사 / 기말고사)
@immutable
class ExamSubjectItem {
  const ExamSubjectItem({
    required this.id,
    required this.subjectName,
    required this.examDate,
    required this.period,
    this.startTime,
    this.endTime,
    this.classroom,
    this.seatNumber,
    this.checklist = const [],
    this.memo,
    this.isCompleted = false,
  });

  final String id;
  final String subjectName; // e.g. '국어', '수학 I', '데이터베이스론'
  final DateTime examDate; // e.g. 2026-10-20
  final int period; // e.g. 1 (1교시), 2 (2교시)
  final String? startTime; // e.g. '09:00'
  final String? endTime; // e.g. '10:00'
  final String? classroom; // e.g. '3반 교실', '인문관 301호'
  final String? seatNumber; // e.g. '24번'
  final List<String> checklist; // e.g. ['공학용 계산기', '컴싸']
  final String? memo; // e.g. '범위: 1단원 ~ 4단원'
  final bool isCompleted;

  /// 시험 잔여일수
  int daysRemaining([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(examDate.year, examDate.month, examDate.day);
    return targetDate.difference(today).inDays;
  }

  /// 시험 종료 여부
  bool isEnded([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(examDate.year, examDate.month, examDate.day);
    return targetDate.isBefore(today);
  }

  ExamSubjectItem copyWith({
    String? id,
    String? subjectName,
    DateTime? examDate,
    int? period,
    String? startTime,
    String? endTime,
    String? classroom,
    String? seatNumber,
    List<String>? checklist,
    String? memo,
    bool? isCompleted,
  }) {
    return ExamSubjectItem(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      examDate: examDate ?? this.examDate,
      period: period ?? this.period,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classroom: classroom ?? this.classroom,
      seatNumber: seatNumber ?? this.seatNumber,
      checklist: checklist ?? this.checklist,
      memo: memo ?? this.memo,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectName': subjectName,
        'examDate': examDate.toIso8601String(),
        'period': period,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (classroom != null) 'classroom': classroom,
        if (seatNumber != null) 'seatNumber': seatNumber,
        if (checklist.isNotEmpty) 'checklist': checklist,
        if (memo != null) 'memo': memo,
        'isCompleted': isCompleted,
      };

  factory ExamSubjectItem.fromJson(Map<String, dynamic> json) {
    return ExamSubjectItem(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      subjectName: json['subjectName'] as String? ?? '',
      examDate: DateTime.parse(json['examDate'] as String),
      period: (json['period'] as num?)?.toInt() ?? 1,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      classroom: json['classroom'] as String?,
      seatNumber: json['seatNumber'] as String?,
      checklist: (json['checklist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      memo: json['memo'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// 개별 시험 종합 프로필 (자격증/공인시험 파이프라인 또는 중간/기말 과목 타임테이블)
@immutable
class ExamProfile {
  const ExamProfile({
    required this.id,
    required this.title,
    this.type = ExamType.qualification,
    this.categoryName = '국가기술자격',
    this.colorHex = '#3B82F6',
    this.stages = const [],
    this.subjects = const [],
    this.targetScore,
    this.showInMainCalendar = true,
    this.createdAt,
  });

  final String id;
  final String title; // e.g. '2026 정보처리기사 2회차', '2학기 중간고사'
  final ExamType type;
  final String categoryName; // e.g. '어학', '국가기술자격', '공무원', '학교시험'
  final String colorHex;
  final List<ExamStageItem> stages; // 자격증용 파이프라인 단계들
  final List<ExamSubjectItem> subjects; // 중간/기말용 과목별 타임테이블
  final String? targetScore; // e.g. '850점 목표', '평점 4.0'
  final bool showInMainCalendar;
  final DateTime? createdAt;

  ExamProfile copyWith({
    String? id,
    String? title,
    ExamType? type,
    String? categoryName,
    String? colorHex,
    List<ExamStageItem>? stages,
    List<ExamSubjectItem>? subjects,
    String? targetScore,
    bool? showInMainCalendar,
    DateTime? createdAt,
  }) {
    return ExamProfile(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      colorHex: colorHex ?? this.colorHex,
      stages: stages ?? this.stages,
      subjects: subjects ?? this.subjects,
      targetScore: targetScore ?? this.targetScore,
      showInMainCalendar: showInMainCalendar ?? this.showInMainCalendar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'categoryName': categoryName,
        'colorHex': colorHex,
        'stages': stages.map((s) => s.toJson()).toList(),
        'subjects': subjects.map((s) => s.toJson()).toList(),
        if (targetScore != null) 'targetScore': targetScore,
        'showInMainCalendar': showInMainCalendar,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  factory ExamProfile.fromJson(Map<String, dynamic> json) {
    return ExamProfile(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '시험',
      type: ExamType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExamType.qualification,
      ),
      categoryName: json['categoryName'] as String? ?? '자격증',
      colorHex: json['colorHex'] as String? ?? '#3B82F6',
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => ExamStageItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => ExamSubjectItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      targetScore: json['targetScore'] as String?,
      showInMainCalendar: json['showInMainCalendar'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
