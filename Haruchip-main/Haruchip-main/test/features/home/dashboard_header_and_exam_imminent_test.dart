import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/models/exam_model.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/home/screens/dashboard_screen.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';
import 'package:haruchip/features/wedding/models/wedding_item.dart';
import 'package:haruchip/features/wedding/providers/wedding_provider.dart';
import 'package:haruchip/features/wedding/widgets/wedding_category_view.dart';

void main() {
  group('Main Dashboard Header Cleanliness Tests', () {
    testWidgets('MainShellScreen top bar renders notification bell icon but excludes 하루칩 text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 우측 상단 알림 종 아이콘 유지 확인
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

      // 좌측 상단 '하루칩' 브랜드 텍스트 제거 확인
      expect(find.text('하루칩'), findsNothing);
    });

    testWidgets('DashboardScreen completely removes lightning banner and dday chips box', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 번개 아이콘(⚡) 배너 완전 제거 확인
      expect(find.text('⚡'), findsNothing);

      // 상단 카테고리 칩 바('전체', '취미', '여행', '결혼' 등)가 최상단에 바로 렌더링 확인
      expect(find.text('전체'), findsOneWidget);
    });
  });

  group('Wedding Category Checklist Tag Tests', () {
    testWidgets('Wedding items render [체크박스] + [항목명] + [일정/장소] without #순번 tag', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weddingListProvider.notifier);
      notifier.addItem(
        WeddingItem(
          id: 'custom-1',
          orderIndex: 1,
          title: '양가 부모님 인사드리기',
          standardOffsetDays: 30,
          stage: WeddingStage.hallAndPlanner,
          targetDate: DateTime.now().add(const Duration(days: 30)),
          location: '한정식집',
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeddingCategoryView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 순번 태그 (#01, #05 등) 미존재 확인
      expect(find.text('#01'), findsNothing);
      expect(find.text('#02'), findsNothing);

      // 체크박스, 항목명, 일정 및 장소 정상 렌더링 확인
      expect(find.text('양가 부모님 인사드리기'), findsOneWidget);
      expect(find.textContaining('📅 '), findsWidgets);
      expect(find.text('한정식집'), findsOneWidget);
    });
  });

  group('Exam Dashboard Imminent D-Day Extraction Tests', () {
    testWidgets('CategorySummaryDashboardCard extracts nearest imminent schedule (registration / written / practical)', (tester) async {
      final now = DateTime.now();
      final exam = ExamProfile(
        id: 'exam-priority-test',
        title: '정보처리기사 2회차',
        type: ExamType.qualification,
        categoryName: '국가기술자격',
        colorHex: '#2563EB',
        stages: [
          ExamStageItem(
            id: 'st-reg',
            stageType: ExamStageType.application,
            name: '원서접수 마감',
            startDate: now.add(const Duration(days: 3)),
            endDate: now.add(const Duration(days: 6)),
          ),
          ExamStageItem(
            id: 'st-written',
            stageType: ExamStageType.writtenTest,
            name: '1차 필기시험',
            startDate: now.add(const Duration(days: 20)),
          ),
          ExamStageItem(
            id: 'st-practical',
            stageType: ExamStageType.practicalTest,
            name: '2차 실기시험',
            startDate: now.add(const Duration(days: 50)),
          ),
        ],
      );

      final category = CategoryModel(
        id: 'cat-exam-1',
        categoryKey: 'exam',
        name: '시험 / 자격증',
        icon: '📚',
        colorHex: '#2563EB',
        createdAt: DateTime.now(),
        metadata: {
          'isInitialized': true,
          'exams': [exam.toJson()],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySummaryDashboardCard(
              category: category,
              countUpItems: const [],
              countDownItems: const [],
              isEditMode: false,
              isWideList: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 가장 가까운 D-Day인 '원서접수 마감'이 대표로 자동 추출되어 표시됨
      expect(find.textContaining('원서접수 마감'), findsOneWidget);
      expect(find.textContaining('가장 임박한 시험'), findsOneWidget);
    });
  });

  group('Exam Category Detail & Unified Timeline Tests', () {
    testWidgets('CategoryDetailScreen provides single AppBar action with 📚 and unified timeline at bottom', (tester) async {
      final now = DateTime.now();
      final exam1 = ExamProfile(
        id: 'ex-1',
        title: '정보처리기사',
        type: ExamType.qualification,
        colorHex: '#4F46E5',
        stages: [
          ExamStageItem(
            id: 'st-1',
            stageType: ExamStageType.application,
            name: '원서접수',
            startDate: now.add(const Duration(days: 5)),
          ),
          ExamStageItem(
            id: 'st-2',
            stageType: ExamStageType.writtenTest,
            name: '필기시험',
            startDate: now.add(const Duration(days: 25)),
          ),
        ],
      );

      final exam2 = ExamProfile(
        id: 'ex-2',
        title: 'TOEIC 정기시험',
        type: ExamType.qualification,
        colorHex: '#0284C7',
        stages: [
          ExamStageItem(
            id: 'st-3',
            stageType: ExamStageType.writtenTest,
            name: '토익 본시험',
            startDate: now.add(const Duration(days: 12)),
          ),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(categoryListProvider.notifier);
      final created = notifier.addCategory(categoryKey: 'exam', name: '시험', emoji: '📚', colorHex: '#4F46E5');
      final category = created.copyWith(metadata: {
        'isInitialized': true,
        'exams': [exam1.toJson(), exam2.toJson()],
      });
      notifier.updateCategory(category);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: CategoryDetailScreen(category: category)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 상단 앱바 우측 책 이모지(📚) 적용 확인
      expect(find.text('📚'), findsWidgets);
      expect(find.text('공식 DB'), findsOneWidget);
      expect(find.text('+ 시험 추가'), findsOneWidget);

      // 2. 아래 중복 흰색 박스(시험 파이프라인 관리) 완전 삭제 확인
      expect(find.text('시험 파이프라인 관리'), findsNothing);

      // 3. 리스트 헤더에 [편집] 버튼 존재 확인
      expect(find.text('편집'), findsOneWidget);

      // 4. 최하단 '통합 임박 일정 타임라인' 신설 확인
      expect(find.text('통합 임박 일정 타임라인'), findsOneWidget);
      expect(find.textContaining('원서접수'), findsWidgets);
      expect(find.textContaining('토익 본시험'), findsWidgets);
    });
  });
}
