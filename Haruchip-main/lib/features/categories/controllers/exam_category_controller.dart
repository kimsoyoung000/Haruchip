import 'package:flutter/material.dart';
import '../models/exam_timeline.dart';

/// 시험 이벤트 유형 (메인/서브)
enum ExamEventType {
  exam, // 시험일 - 메인
  registration, // 접수일 - 서브
  result; // 합격발표일 - 서브

  String toJson() => name;

  static ExamEventType fromJson(String value) {
    return ExamEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExamEventType.exam,
    );
  }
}

/// 시험 타임라인 이벤트 항목
@immutable
class ExamEventItem {
  const ExamEventItem({
    required this.id,
    required this.title,
    required this.date,
    required this.stage,
    required this.eventType,
    required this.flowOrder,
    required this.subjectColorHex,
  });

  final String id;
  final String title;
  final DateTime date;
  final ExamStage stage;
  final ExamEventType eventType;
  final int flowOrder; // 1(접수) -> 2(필기) -> 3(발표) -> 4(실기) -> 5(최종)
  final String subjectColorHex;

  /// 오늘 기준 종료/마감 여부
  bool isEnded([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  /// 메인 강조 시험일인가?
  bool get isMain => eventType == ExamEventType.exam || stage.isMainExamDay;

  /// D-Day 남은 일수 (0 = D-day, 양수 = 남음, 음수 = 지남)
  int daysRemaining([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'stage': stage.name,
        'eventType': eventType.toJson(),
        'flowOrder': flowOrder,
        'subjectColorHex': subjectColorHex,
      };

  factory ExamEventItem.fromJson(Map<String, dynamic> json) {
    return ExamEventItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      stage: ExamStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => ExamStage.writtenTest,
      ),
      eventType: ExamEventType.fromJson(json['eventType'] as String? ?? ''),
      flowOrder: (json['flowOrder'] as num?)?.toInt() ?? 1,
      subjectColorHex: json['subjectColorHex'] as String? ?? '#4A90E2',
    );
  }
}

/// 시험 카테고리 시각적 스타일링 및 타임라인 로직 컨트롤러
class ExamCategoryController {
  const ExamCategoryController();

  /// D-Day가 임박한 순서대로 시험 이벤트 정렬 (종료되지 않은 일정이 상단, D-Day 적을수록 상단)
  List<ExamEventItem> sortEventsByUrgency(List<ExamEventItem> events, [DateTime? relativeTo]) {
    final sorted = [...events];
    sorted.sort((a, b) {
      final aDiff = a.daysRemaining(relativeTo);
      final bDiff = b.daysRemaining(relativeTo);

      // 미래/오늘(>= 0) 일정이 과거(< 0) 일정보다 상단 배치
      final aIsPast = aDiff < 0;
      final bIsPast = bDiff < 0;

      if (aIsPast != bIsPast) {
        return aIsPast ? 1 : -1;
      }
      return aDiff.compareTo(bDiff);
    });
    return sorted;
  }

  /// 타임라인 트리를 flowOrder (1 -> 2 -> 3 -> 4 -> 5) 순으로 정렬
  List<ExamEventItem> sortByFlowOrder(List<ExamEventItem> events) {
    final sorted = [...events];
    sorted.sort((a, b) => a.flowOrder.compareTo(b.flowOrder));
    return sorted;
  }

  /// 과목 테마 컬러 기반 서브 컬러 (채도가 낮고 차분한 색) 계산
  Color getSubColor(Color subjectColor) {
    final HSLColor hsl = HSLColor.fromColor(subjectColor);
    final HSLColor mutedHsl = hsl
        .withSaturation((hsl.saturation * 0.4).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.95).clamp(0.0, 1.0));
    return mutedHsl.toColor();
  }

  /// 과목 테마 컬러 기반 Gray-out 마감 컬러 계산
  Color getEndedGrayColor(Color subjectColor) {
    return const Color(0xFF9E9E9E);
  }

  /// 1. 시험일(메인): subjectColor 기반 메인 강조 스타일 (Bold)
  TextStyle getMainTextStyle(Color subjectColor) {
    return TextStyle(
      color: subjectColor,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
  }

  /// 2. 접수일/발표일(서브): 채도가 낮은 서브 컬러 스타일 (Regular)
  TextStyle getSubTextStyle(Color subjectColor) {
    return TextStyle(
      color: getSubColor(subjectColor),
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
  }

  /// 3. 종료(마감)된 일정: Opacity 0.4~0.5, Gray-out, 취소선
  TextStyle getEndedTextStyle() {
    return const TextStyle(
      color: Color(0xFF9E9E9E),
      decoration: TextDecoration.lineThrough,
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
  }
}
