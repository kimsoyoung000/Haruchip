import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../models/exam_timeline.dart';

/// 시험 이벤트 유형 (메인/서브 - 하위 호환성 유지)
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

/// 시험 타임라인 이벤트 항목 (하위 호환성 유지)
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

/// 활성 시험 대표 디데이 상태 정보
@immutable
class ExamRollingStatus {
  const ExamRollingStatus({
    required this.badgeText,
    required this.subDetailText,
    required this.activeStage,
    required this.daysLeft,
    required this.isAllFinished,
  });

  final String badgeText; // e.g. '필기시험 D-14', '원서접수 마감 D-3', '중간고사 D-7'
  final String subDetailText; // e.g. '다음: 07.26 실기시험', '1교시 국어 09:00'
  final ExamStageItem? activeStage;
  final int daysLeft;
  final bool isAllFinished;
}

/// 시험 카테고리 시각적 스타일링 및 타임라인 로직 컨트롤러
class ExamCategoryController {
  const ExamCategoryController();

  /// 1. 실시간 대표 디데이 롤링 로직 연산
  /// - 지난 단계는 자동 완료 처리
  /// - 현재 시점 기준 가장 먼저 다가오는 단계의 D-Day를 대표 뱃지로 표기
  ExamRollingStatus getRollingStatus(ExamProfile exam, [DateTime? relativeTo]) {
    // 학교 시험 모드 (중간고사 / 기말고사)
    if (exam.type == ExamType.midterm || exam.type == ExamType.finalExam) {
      if (exam.subjects.isNotEmpty) {
        final sortedSubjects = List<ExamSubjectItem>.from(exam.subjects)
          ..sort((a, b) {
            final cmp = a.examDate.compareTo(b.examDate);
            if (cmp != 0) return cmp;
            return a.period.compareTo(b.period);
          });

        final upcomingSubjects = sortedSubjects.where((s) => !s.isEnded(relativeTo)).toList();
        if (upcomingSubjects.isNotEmpty) {
          final firstSub = upcomingSubjects.first;
          final days = firstSub.daysRemaining(relativeTo);
          final dDayStr = days > 0 ? 'D-$days' : (days == 0 ? 'D-Day' : 'D+${-days}');
          final periodStr = firstSub.period > 0 ? '${firstSub.period}교시 ' : '';
          final timeStr = firstSub.startTime != null ? '${firstSub.startTime} ' : '';

          return ExamRollingStatus(
            badgeText: '${exam.type.labelKo} $dDayStr',
            subDetailText: '$periodStr${firstSub.subjectName} $timeStr($dDayStr)',
            activeStage: null,
            daysLeft: days,
            isAllFinished: false,
          );
        } else {
          return ExamRollingStatus(
            badgeText: '${exam.type.labelKo} 완료 🎉',
            subDetailText: '모든 과목 시험이 종료되었습니다.',
            activeStage: null,
            daysLeft: -1,
            isAllFinished: true,
          );
        }
      }
    }

    // 자격증 / 공인시험 다단계 파이프라인
    if (exam.stages.isNotEmpty) {
      final sortedStages = List<ExamStageItem>.from(exam.stages)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      final upcoming = sortedStages.where((s) => !s.isEnded(relativeTo) && !s.isCompleted).toList();

      if (upcoming.isNotEmpty) {
        final active = upcoming.first;
        final days = active.daysRemaining(relativeTo);
        final dDayStr = days > 0 ? 'D-$days' : (days == 0 ? 'D-Day' : 'D+${-days}');

        String stageTitle = active.name;
        if (active.stageType == ExamStageType.application) {
          stageTitle = '원서접수 마감';
        } else if (active.stageType == ExamStageType.writtenTest) {
          stageTitle = '필기/시험일';
        } else if (active.stageType == ExamStageType.writtenResult) {
          stageTitle = '합격 발표';
        } else if (active.stageType == ExamStageType.practicalTest) {
          stageTitle = '실기/면접';
        } else if (active.stageType == ExamStageType.finalResult) {
          stageTitle = '최종 합격자 발표';
        }

        final m = active.startDate.month.toString().padLeft(2, '0');
        final d = active.startDate.day.toString().padLeft(2, '0');
        final dateLabel = '$m.$d';

        return ExamRollingStatus(
          badgeText: '$stageTitle $dDayStr',
          subDetailText: '$dateLabel $stageTitle',
          activeStage: active,
          daysLeft: days,
          isAllFinished: false,
        );
      } else {
        return const ExamRollingStatus(
          badgeText: '시험 일정 종료 🎉',
          subDetailText: '모든 시험 단계가 마무리되었습니다.',
          activeStage: null,
          daysLeft: -1,
          isAllFinished: true,
        );
      }
    }

    return const ExamRollingStatus(
      badgeText: 'D-Day',
      subDetailText: '등록된 일정이 없습니다.',
      activeStage: null,
      daysLeft: 0,
      isAllFinished: false,
    );
  }

  /// 2. 시험 목록을 '가장 임박한 세부 일정순'으로 정렬 (Smart View)
  List<ExamProfile> sortExamsByUrgency(List<ExamProfile> exams, [DateTime? relativeTo]) {
    final sorted = List<ExamProfile>.from(exams);
    sorted.sort((a, b) {
      final aStatus = getRollingStatus(a, relativeTo);
      final bStatus = getRollingStatus(b, relativeTo);

      if (aStatus.isAllFinished != bStatus.isAllFinished) {
        return aStatus.isAllFinished ? 1 : -1;
      }

      final aDays = aStatus.daysLeft;
      final bDays = bStatus.daysLeft;

      final aIsPast = aDays < 0;
      final bIsPast = bDays < 0;

      if (aIsPast != bIsPast) {
        return aIsPast ? 1 : -1;
      }

      return aDays.compareTo(bDays);
    });
    return sorted;
  }

  /// 3. 과목별 시간 및 남은 시간 텍스트 포맷
  String getSubjectRemainingLabel(ExamSubjectItem subject, [DateTime? relativeTo]) {
    final days = subject.daysRemaining(relativeTo);
    final periodStr = subject.period > 0 ? '${subject.period}교시' : '';
    final timeStr = subject.startTime != null ? ' ${subject.startTime}' : '';

    if (days == 0) {
      return '오늘$timeStr ($periodStr)';
    } else if (days == 1) {
      return '내일$timeStr ($periodStr) D-1';
    } else if (days > 1) {
      return '$periodStr$timeStr D-$days';
    } else {
      return '시험 종료';
    }
  }

  // ==========================================
  // 기존 레거시 호환 메서드 (하위 호환성 100% 보존)
  // ==========================================
  List<ExamEventItem> sortEventsByUrgency(List<ExamEventItem> events, [DateTime? relativeTo]) {
    final sorted = [...events];
    sorted.sort((a, b) {
      final aDiff = a.daysRemaining(relativeTo);
      final bDiff = b.daysRemaining(relativeTo);

      final aIsPast = aDiff < 0;
      final bIsPast = bDiff < 0;

      if (aIsPast != bIsPast) {
        return aIsPast ? 1 : -1;
      }
      return aDiff.compareTo(bDiff);
    });
    return sorted;
  }

  List<ExamEventItem> sortByFlowOrder(List<ExamEventItem> events) {
    final sorted = [...events];
    sorted.sort((a, b) => a.flowOrder.compareTo(b.flowOrder));
    return sorted;
  }

  Color getSubColor(Color subjectColor) {
    final HSLColor hsl = HSLColor.fromColor(subjectColor);
    final HSLColor mutedHsl = hsl
        .withSaturation((hsl.saturation * 0.4).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.95).clamp(0.0, 1.0));
    return mutedHsl.toColor();
  }

  Color getEndedGrayColor(Color subjectColor) {
    return const Color(0xFF9E9E9E);
  }

  TextStyle getMainTextStyle(Color subjectColor) {
    return TextStyle(
      color: subjectColor,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
  }

  TextStyle getSubTextStyle(Color subjectColor) {
    return TextStyle(
      color: getSubColor(subjectColor),
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
  }

  TextStyle getEndedTextStyle() {
    return const TextStyle(
      color: Color(0xFF9E9E9E),
      decoration: TextDecoration.lineThrough,
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
  }
}
