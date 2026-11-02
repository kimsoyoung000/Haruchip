import 'package:flutter/material.dart';

/// 목표 분류 타입
enum GoalType {
  yearly, // 올해 목표
  monthly, // 매달 목표
  bucket; // 기한 없는 버킷리스트

  String get labelKo => switch (this) {
        GoalType.yearly => '올해 목표',
        GoalType.monthly => '매달 목표',
        GoalType.bucket => '버킷리스트',
      };

  String toJson() => name;
  static GoalType fromJson(String value) {
    return GoalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalType.yearly,
    );
  }
}

/// 3단계 진행 상태 (노션 태그 스타일)
enum GoalStatus {
  notStarted, // 시작 전 (회색)
  inProgress, // 진행 중 (블루)
  completed; // 달성 완료 (그린)

  String get labelKo => switch (this) {
        GoalStatus.notStarted => '시작 전',
        GoalStatus.inProgress => '진행 중',
        GoalStatus.completed => '달성 완료',
      };

  Color get tagColor => switch (this) {
        GoalStatus.notStarted => const Color(0xFF64748B),
        GoalStatus.inProgress => const Color(0xFF2563EB),
        GoalStatus.completed => const Color(0xFF16A34A),
      };

  Color get tagBgColor => switch (this) {
        GoalStatus.notStarted => const Color(0xFFF1F5F9),
        GoalStatus.inProgress => const Color(0xFFEFF6FF),
        GoalStatus.completed => const Color(0xFFF0FDF4),
      };

  String toJson() => name;
  static GoalStatus fromJson(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalStatus.notStarted,
    );
  }
}

/// 형광펜 하이라이트 우선순위 색상
enum HighlighterColor {
  none, // 투명
  yellow, // 옐로우 (#FEF08A)
  mint, // 민트 (#A7F3D0)
  pink; // 핑크 (#FBCFE8)

  String get labelKo => switch (this) {
        HighlighterColor.none => '기본',
        HighlighterColor.yellow => '노랑',
        HighlighterColor.mint => '민트',
        HighlighterColor.pink => '핑크',
      };

  Color get color => switch (this) {
        HighlighterColor.none => Colors.transparent,
        HighlighterColor.yellow => const Color(0xFFFEF08A),
        HighlighterColor.mint => const Color(0xFFA7F3D0),
        HighlighterColor.pink => const Color(0xFFFBCFE8),
      };

  String toJson() => name;
  static HighlighterColor fromJson(String value) {
    return HighlighterColor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HighlighterColor.none,
    );
  }
}

/// 목표 / 버킷리스트 아이템 모델
@immutable
class GoalItem {
  const GoalItem({
    required this.id,
    required this.title,
    this.goalType = GoalType.yearly,
    this.targetYear,
    this.targetMonth,
    this.deadline,
    this.status = GoalStatus.notStarted,
    this.isCompleted = false,
    this.completedAt,
    this.highlighter = HighlighterColor.none,
    this.showInCalendar = false,
    this.memo,
  });

  final String id;
  final String title;
  final GoalType goalType;
  final int? targetYear; // e.g. 2026
  final int? targetMonth; // 1..12
  final DateTime? deadline; // 마감일 (null이면 기한 없음)
  final GoalStatus status;
  final bool isCompleted;
  final DateTime? completedAt;
  final HighlighterColor highlighter;
  final bool showInCalendar;
  final String? memo;

  /// D-Day 계산 및 라벨
  String get dDayLabel {
    if (isCompleted) return '달성 완료';
    if (deadline == null) return '기한 없음';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline!.year, deadline!.month, deadline!.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  GoalItem copyWith({
    String? id,
    String? title,
    GoalType? goalType,
    int? targetYear,
    int? targetMonth,
    DateTime? deadline,
    bool clearDeadline = false,
    GoalStatus? status,
    bool? isCompleted,
    DateTime? completedAt,
    HighlighterColor? highlighter,
    bool? showInCalendar,
    String? memo,
  }) {
    return GoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      goalType: goalType ?? this.goalType,
      targetYear: targetYear ?? this.targetYear,
      targetMonth: targetMonth ?? this.targetMonth,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      highlighter: highlighter ?? this.highlighter,
      showInCalendar: showInCalendar ?? this.showInCalendar,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'goalType': goalType.toJson(),
        'targetYear': targetYear,
        'targetMonth': targetMonth,
        'deadline': deadline?.toIso8601String(),
        'status': status.toJson(),
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'highlighter': highlighter.toJson(),
        'showInCalendar': showInCalendar,
        'memo': memo,
      };

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] as String? ?? 'goal-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      goalType: GoalType.fromJson(json['goalType'] as String? ?? 'yearly'),
      targetYear: json['targetYear'] as int?,
      targetMonth: json['targetMonth'] as int?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      status: GoalStatus.fromJson(json['status'] as String? ?? 'notStarted'),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      highlighter: HighlighterColor.fromJson(json['highlighter'] as String? ?? 'none'),
      showInCalendar: json['showInCalendar'] as bool? ?? false,
      memo: json['memo'] as String?,
    );
  }
}

/// 기본 목표 / 버킷리스트 목업 데이터
final List<GoalItem> kDefaultMockGoals = [
  GoalItem(
    id: 'goal-1',
    title: '토익 900점 달성하기 🎯',
    goalType: GoalType.yearly,
    targetYear: DateTime.now().year,
    deadline: DateTime(DateTime.now().year, 11, 30),
    status: GoalStatus.inProgress,
    highlighter: HighlighterColor.yellow,
    showInCalendar: true,
  ),
  GoalItem(
    id: 'goal-2',
    title: '체지방률 5% 감량 및 바디프로필',
    goalType: GoalType.yearly,
    targetYear: DateTime.now().year,
    deadline: DateTime(DateTime.now().year, 12, 15),
    status: GoalStatus.inProgress,
    highlighter: HighlighterColor.mint,
    showInCalendar: false,
  ),
  GoalItem(
    id: 'goal-3',
    title: '이번 달 경제/재테크 서적 2권 완독 📚',
    goalType: GoalType.monthly,
    targetYear: DateTime.now().year,
    targetMonth: DateTime.now().month,
    deadline: DateTime(DateTime.now().year, DateTime.now().month, 28),
    status: GoalStatus.inProgress,
    highlighter: HighlighterColor.pink,
    showInCalendar: true,
  ),
  GoalItem(
    id: 'goal-4',
    title: '스위스 인터라켄 패러글라이딩 🪂',
    goalType: GoalType.bucket,
    deadline: null, // 기한 없음
    status: GoalStatus.notStarted,
    highlighter: HighlighterColor.none,
    showInCalendar: false,
  ),
  GoalItem(
    id: 'goal-5',
    title: '나만의 사이드 프로젝트 앱 출시하기 📱',
    goalType: GoalType.bucket,
    deadline: null,
    status: GoalStatus.inProgress,
    highlighter: HighlighterColor.yellow,
    showInCalendar: false,
  ),
];
