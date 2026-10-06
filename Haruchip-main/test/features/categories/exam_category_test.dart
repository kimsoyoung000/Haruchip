import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/controllers/exam_category_controller.dart';
import 'package:haruchip/features/categories/data/official_exam_database.dart';
import 'package:haruchip/features/categories/models/exam_model.dart';
import 'package:haruchip/features/categories/models/exam_timeline.dart';
import 'package:haruchip/features/categories/widgets/exam_card_widget.dart';
import 'package:haruchip/features/categories/widgets/exam_official_db_modal.dart';

void main() {
  group('ExamModel & Serialization Tests', () {
    test('ExamStageItem serialization and days remaining calculation', () {
      final now = DateTime(2026, 10, 1);
      final stage = ExamStageItem(
        id: 'stage-test-1',
        stageType: ExamStageType.writtenTest,
        name: '필기 시험',
        startDate: DateTime(2026, 10, 15),
        testTime: '09:30 입실',
        location: '서울공고',
        seatNumber: '14번',
        checklist: const ['신분증', '컴싸'],
      );

      final json = stage.toJson();
      final fromJson = ExamStageItem.fromJson(json);

      expect(fromJson.id, 'stage-test-1');
      expect(fromJson.stageType, ExamStageType.writtenTest);
      expect(fromJson.name, '필기 시험');
      expect(fromJson.startDate, DateTime(2026, 10, 15));
      expect(fromJson.testTime, '09:30 입실');
      expect(fromJson.location, '서울공고');
      expect(fromJson.seatNumber, '14번');
      expect(fromJson.checklist, ['신분증', '컴싸']);

      expect(stage.daysRemaining(now), 14);
      expect(stage.isEnded(now), false);
      expect(stage.isEnded(DateTime(2026, 10, 20)), true);
    });

    test('ExamSubjectItem serialization and countdown calculation', () {
      final now = DateTime(2026, 10, 10);
      final sub = ExamSubjectItem(
        id: 'sub-test-1',
        subjectName: '수학 I',
        examDate: DateTime(2026, 10, 19),
        period: 2,
        startTime: '10:30',
        endTime: '11:40',
        classroom: '3반',
        checklist: const ['계산기'],
      );

      final json = sub.toJson();
      final fromJson = ExamSubjectItem.fromJson(json);

      expect(fromJson.id, 'sub-test-1');
      expect(fromJson.subjectName, '수학 I');
      expect(fromJson.examDate, DateTime(2026, 10, 19));
      expect(fromJson.period, 2);
      expect(fromJson.startTime, '10:30');
      expect(fromJson.endTime, '11:40');
      expect(fromJson.classroom, '3반');
      expect(fromJson.checklist, ['계산기']);

      expect(sub.daysRemaining(now), 9);
      expect(sub.isEnded(now), false);
      expect(sub.isEnded(DateTime(2026, 10, 20)), true);
    });

    test('ExamProfile complete serialization with stages and subjects', () {
      final exam = ExamProfile(
        id: 'exam-full-1',
        title: '2026 정보처리기사 2회차',
        type: ExamType.qualification,
        categoryName: '국가기술자격',
        colorHex: '#4F46E5',
        targetScore: '동차 합격',
        showInMainCalendar: true,
        stages: [
          ExamStageItem(
            id: 'st-1',
            stageType: ExamStageType.application,
            name: '원서접수',
            startDate: DateTime(2026, 4, 15),
            endDate: DateTime(2026, 4, 18),
          ),
          ExamStageItem(
            id: 'st-2',
            stageType: ExamStageType.writtenTest,
            name: '필기시험',
            startDate: DateTime(2026, 5, 10),
          ),
        ],
      );

      final json = exam.toJson();
      final fromJson = ExamProfile.fromJson(json);

      expect(fromJson.id, 'exam-full-1');
      expect(fromJson.title, '2026 정보처리기사 2회차');
      expect(fromJson.type, ExamType.qualification);
      expect(fromJson.categoryName, '국가기술자격');
      expect(fromJson.colorHex, '#4F46E5');
      expect(fromJson.targetScore, '동차 합격');
      expect(fromJson.showInMainCalendar, true);
      expect(fromJson.stages.length, 2);
      expect(fromJson.stages.first.name, '원서접수');
      expect(fromJson.stages.last.name, '필기시험');
    });
  });

  group('Official Exam Database Tests', () {
    test('kOfficialExamPresets contains valid real exam schedules and categories', () {
      expect(kOfficialExamPresets.isNotEmpty, true);

      final categories = kOfficialExamPresets.map((p) => p.groupCategory).toSet();
      expect(categories.contains('어학/상시'), true);
      expect(categories.contains('국가기술자격'), true);
      expect(categories.contains('공무원/공기업'), true);
      expect(categories.contains('입시/수능'), true);
      expect(categories.contains('학교시험'), true);

      final toeic = kOfficialExamPresets.firstWhere((p) => p.id == 'preset-toeic');
      expect(toeic.title, '토익 (TOEIC)');
      expect(toeic.rounds.isNotEmpty, true);
      expect(toeic.rounds.first.stages.isNotEmpty, true);

      final qnet = kOfficialExamPresets.firstWhere((p) => p.id == 'preset-qnet-cs');
      expect(qnet.title.contains('정보처리기사'), true);
      expect(qnet.rounds.length >= 2, true);
    });
  });

  group('ExamCategoryController Rolling Status & Urgency Tests', () {
    const controller = ExamCategoryController();

    test('getRollingStatus for Qualification Pipeline: displays earliest upcoming stage D-Day', () {
      final exam = ExamProfile(
        id: 'exam-pipe-1',
        title: '정보처리기사 2회차',
        type: ExamType.qualification,
        stages: [
          ExamStageItem(
            id: 'st-1',
            stageType: ExamStageType.application,
            name: '원서접수',
            startDate: DateTime(2026, 4, 15),
            endDate: DateTime(2026, 4, 18),
            isCompleted: true, // past completed
          ),
          ExamStageItem(
            id: 'st-2',
            stageType: ExamStageType.writtenTest,
            name: '1차 필기시험',
            startDate: DateTime(2026, 5, 10), // in 10 days
          ),
          ExamStageItem(
            id: 'st-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 발표',
            startDate: DateTime(2026, 6, 10),
          ),
        ],
      );

      final status = controller.getRollingStatus(exam, DateTime(2026, 4, 30));
      expect(status.badgeText, '필기/시험일 D-10');
      expect(status.subDetailText, '05.10 필기/시험일');
      expect(status.isAllFinished, false);
      expect(status.activeStage?.id, 'st-2');
    });

    test('getRollingStatus when all stages are finished', () {
      final exam = ExamProfile(
        id: 'exam-finished',
        title: '토익 완료 회차',
        type: ExamType.qualification,
        stages: [
          ExamStageItem(
            id: 'st-1',
            stageType: ExamStageType.writtenTest,
            name: '시험일',
            startDate: DateTime(2026, 1, 10),
            isCompleted: true,
          ),
        ],
      );

      final status = controller.getRollingStatus(exam, DateTime(2026, 2, 1));
      expect(status.badgeText, '시험 일정 종료 🎉');
      expect(status.isAllFinished, true);
    });

    test('getRollingStatus for School Exam: displays earliest upcoming subject countdown', () {
      final exam = ExamProfile(
        id: 'exam-school-1',
        title: '2학기 중간고사',
        type: ExamType.midterm,
        subjects: [
          ExamSubjectItem(
            id: 'sub-1',
            subjectName: '국어',
            examDate: DateTime(2026, 10, 20),
            period: 1,
            startTime: '09:00',
          ),
          ExamSubjectItem(
            id: 'sub-2',
            subjectName: '수학',
            examDate: DateTime(2026, 10, 20),
            period: 2,
            startTime: '10:30',
          ),
        ],
      );

      final status = controller.getRollingStatus(exam, DateTime(2026, 10, 15));
      expect(status.badgeText, '중간고사 D-5');
      expect(status.subDetailText.contains('국어'), true);
      expect(status.isAllFinished, false);
    });

    test('sortExamsByUrgency sorts nearest active exams first, and finished exams last', () {
      final examSoon = ExamProfile(
        id: 'soon',
        title: '곧 시험',
        type: ExamType.qualification,
        stages: [
          ExamStageItem(
            id: 's1',
            stageType: ExamStageType.writtenTest,
            name: '필기',
            startDate: DateTime(2026, 10, 12), // D-2
          ),
        ],
      );

      final examLater = ExamProfile(
        id: 'later',
        title: '나중 시험',
        type: ExamType.qualification,
        stages: [
          ExamStageItem(
            id: 's2',
            stageType: ExamStageType.writtenTest,
            name: '필기',
            startDate: DateTime(2026, 11, 15), // D-36
          ),
        ],
      );

      final examDone = ExamProfile(
        id: 'done',
        title: '끝난 시험',
        type: ExamType.qualification,
        stages: [
          ExamStageItem(
            id: 's3',
            stageType: ExamStageType.writtenTest,
            name: '필기',
            startDate: DateTime(2026, 9, 1),
            isCompleted: true,
          ),
        ],
      );

      final sorted = controller.sortExamsByUrgency([examDone, examLater, examSoon], DateTime(2026, 10, 10));
      expect(sorted[0].id, 'soon');
      expect(sorted[1].id, 'later');
      expect(sorted[2].id, 'done');
    });

    test('Legacy compatibility methods in ExamCategoryController work properly', () {
      final now = DateTime(2026, 10, 10);
      final events = [
        ExamEventItem(
          id: 'ev-1',
          title: '필기시험',
          date: DateTime(2026, 10, 20),
          stage: ExamStage.writtenTest,
          eventType: ExamEventType.exam,
          flowOrder: 2,
          subjectColorHex: '#4A90E2',
        ),
        ExamEventItem(
          id: 'ev-2',
          title: '원서접수',
          date: DateTime(2026, 10, 12),
          stage: ExamStage.application,
          eventType: ExamEventType.registration,
          flowOrder: 1,
          subjectColorHex: '#4A90E2',
        ),
      ];

      final urgent = controller.sortEventsByUrgency(events, now);
      expect(urgent.first.id, 'ev-2');

      final flow = controller.sortByFlowOrder(events);
      expect(flow.first.id, 'ev-2');

      final subColor = controller.getSubColor(const Color(0xFF4A90E2));
      expect(subColor, isA<Color>());
    });
  });

  group('Exam Widgets Tests', () {
    testWidgets('ExamCardWidget renders qualification pipeline stages properly', (tester) async {
      final exam = ExamProfile(
        id: 'test-card-1',
        title: '2026 토익 제539회',
        type: ExamType.qualification,
        categoryName: '어학',
        colorHex: '#2563EB',
        targetScore: '850점',
        stages: [
          ExamStageItem(
            id: 'stage-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 10, 19),
          ),
          ExamStageItem(
            id: 'stage-2',
            stageType: ExamStageType.writtenTest,
            name: '토익 정기시험일',
            startDate: DateTime(2026, 10, 25),
            testTime: '09:20 입실완료',
            checklist: const ['신분증', '연필', '지우개'],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamCardWidget(
              exam: exam,
              onEdit: () {},
              onDelete: () {},
              onExamChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('2026 토익 제539회'), findsOneWidget);
      expect(find.text('850점'), findsOneWidget);
      expect(find.text('원서 접수 마감'), findsOneWidget);
      expect(find.text('토익 정기시험일'), findsOneWidget);
      expect(find.text('신분증'), findsOneWidget);
      expect(find.text('연필'), findsOneWidget);
    });

    testWidgets('ExamOfficialDbModal displays tabs and search filtering', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showExamOfficialDbModal(context),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('공식 시험일정 불러오기'), findsOneWidget);
      expect(find.text('어학/상시'), findsWidgets);
      expect(find.text('국가기술자격'), findsWidgets);

      // Search filter test
      await tester.enterText(find.byType(TextField), '토익');
      await tester.pumpAndSettle();

      expect(find.text('토익 (TOEIC)'), findsOneWidget);
    });
  });
}
