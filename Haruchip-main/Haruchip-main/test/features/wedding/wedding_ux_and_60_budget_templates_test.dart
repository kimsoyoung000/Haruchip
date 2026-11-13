import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/wedding/data/wedding_budget_master_items.dart';
import 'package:haruchip/features/wedding/models/wedding_budget_item.dart';
import 'package:haruchip/features/wedding/models/wedding_item.dart';
import 'package:haruchip/features/wedding/providers/wedding_provider.dart';
import 'package:haruchip/features/wedding/widgets/wedding_budget_edit_modal.dart';
import 'package:haruchip/features/wedding/widgets/wedding_budget_section_widget.dart';
import 'package:haruchip/features/wedding/widgets/wedding_budget_template_modal.dart';
import 'package:haruchip/features/wedding/widgets/wedding_category_view.dart';
import 'package:haruchip/features/wedding/widgets/wedding_template_manager_modal.dart';

void main() {
  group('1. 일정 등록 시 D-Day 실시간 자동 정렬 (Auto-Sort by Closeness)', () {
    test('D-Day가 가까운 순서(임박순)로 정렬되며, 미지정 항목은 하단에 배치된다', () {
      final now = DateTime(2026, 6, 1);

      final itemA = WeddingItem(
        id: 'undated-1',
        orderIndex: 1,
        title: '날짜 아직 안 잡힌 항목',
        standardOffsetDays: 300,
        stage: WeddingStage.hallAndPlanner,
        targetDate: null,
      );
      final itemB = WeddingItem(
        id: 'future-30',
        orderIndex: 2,
        title: '30일 뒤 일정 (D-30)',
        standardOffsetDays: 200,
        stage: WeddingStage.studimeAndRing,
        targetDate: DateTime(2026, 7, 1),
      );
      final itemC = WeddingItem(
        id: 'imminent-1',
        orderIndex: 3,
        title: '내일 일정 (D-1)',
        standardOffsetDays: 100,
        stage: WeddingStage.studioShoot,
        targetDate: DateTime(2026, 6, 2),
      );
      final itemD = WeddingItem(
        id: 'imminent-5',
        orderIndex: 4,
        title: '5일 뒤 일정 (D-5)',
        standardOffsetDays: 50,
        stage: WeddingStage.invitationAndGuest,
        targetDate: DateTime(2026, 6, 6),
      );

      final list = [itemA, itemB, itemC, itemD];
      list.sort((a, b) => compareWeddingItemsByCloseness(a, b, now));

      // 1등: D-1 (내일)
      expect(list[0].id, 'imminent-1');
      // 2등: D-5
      expect(list[1].id, 'imminent-5');
      // 3등: D-30
      expect(list[2].id, 'future-30');
      // 4등(하단 배치): 날짜 미지정
      expect(list[3].id, 'undated-1');
    });

    test('updateItem으로 날짜가 부여되면 즉시 임박순 정렬 위치로 이동한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weddingListProvider.notifier);
      final current = container.read(weddingListProvider);
      final firstItem = current.first;

      // 처음에는 날짜가 먼 미래로 설정된 항목을 내일로 변경
      final updated = firstItem.copyWith(
        targetDate: DateTime.now().add(const Duration(days: 1)),
      );
      notifier.updateItem(updated);

      final reordered = container.read(weddingListProvider);
      // 가장 임박하므로 맨 앞에 위치해야 함
      expect(reordered.first.id, firstItem.id);
      expect(reordered.first.targetDate, isNotNull);
    });
  });

  group('2. 원터치 아코디언 메모/상세 토글 (Inline Expand/Collapse)', () {
    testWidgets('카드 탭 시 부드럽게 아코디언이 펼쳐져 인라인 메모/장소/팁이 노출되고 다시 탭하면 닫힌다', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final testItem = WeddingItem(
        id: 'accordion-custom',
        orderIndex: 1,
        title: '양가 부모님 한복 맞춤',
        standardOffsetDays: 90,
        stage: WeddingStage.invitationAndGuest,
        targetDate: DateTime.now().add(const Duration(days: 15)),
        location: '종로 비단금침',
        memo: '양가 어머님 배색 취향 사전 확인 필수 (푸른색/붉은색 계열)',
        weekdayNotice: '평일 오후 2시 방문 시 프라이빗 상담 가능',
      );
      container.read(weddingListProvider.notifier).addItem(testItem);

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

      // 초기 상태: 아코디언 닫힘 (상세 메모 미노출)
      expect(find.text('양가 부모님 한복 맞춤'), findsOneWidget);
      expect(find.text('양가 어머님 배색 취향 사전 확인 필수 (푸른색/붉은색 계열)'), findsNothing);

      // 1회 탭 -> 아코디언 펼침
      await tester.tap(find.text('양가 부모님 한복 맞춤'));
      await tester.pumpAndSettle();

      // 인라인 메모, 상세 장소, 팁, 수정 버튼 노출 확인
      expect(find.text('작성된 메모'), findsOneWidget);
      expect(find.text('양가 어머님 배색 취향 사전 확인 필수 (푸른색/붉은색 계열)'), findsOneWidget);
      expect(find.textContaining('종로 비단금침'), findsOneWidget);
      expect(find.textContaining('평일 오후 2시 방문'), findsOneWidget);
      expect(find.text('일정 / 장소 / 메모 수정하기'), findsOneWidget);

      // 다시 탭 -> 아코디언 닫힘
      await tester.tap(find.text('양가 부모님 한복 맞춤'));
      await tester.pumpAndSettle();
      expect(find.text('작성된 메모'), findsNothing);
    });
  });

  group('3. 항목 추가 팝업 및 타이틀 정돈 & 소속 카테고리 태깅', () {
    testWidgets('타이틀이 결혼 준비 항목으로 표시되고 T-360일 추천 문구가 없으며 카테고리 태깅이 연동된다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingTemplateManagerModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 명칭 수정 확인
      expect(find.text('결혼 준비 항목'), findsOneWidget);
      expect(find.text('원하는 일정을 담거나 직접 추가해보세요'), findsOneWidget);

      // 기계적인 T-360일 추천 등 문구 완전 제거 확인
      expect(find.textContaining('T-360일 추천'), findsNothing);
      expect(find.textContaining('T-'), findsNothing);

      // 소속 카테고리 선택 칩 노출 확인
      expect(find.text('소속 카테고리: '), findsOneWidget);
      expect(find.textContaining('상견례 및 웨딩홀/플래너'), findsWidgets);
      expect(find.textContaining('스드메 및 웨딩밴드'), findsWidgets);

      // 직접 추가 폼 필드
      expect(find.text('직접 추가'), findsOneWidget);
    });
  });

  group('4. 60개 마스터 템플릿 기반 결혼 예산 관리표', () {
    test('60개 마스터 템플릿이 8대 대분류에 정확한 수량으로 존재한다', () {
      final templates = create60WeddingBudgetMasterTemplates();
      expect(templates.length, 60);

      // 1. 상견례 & 양가 인사 (6개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.greeting).length, 6);
      // 2. 웨딩홀 & 식대 (8개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.hallAndMeal).length, 8);
      // 3. 스튜디오 & 스냅 촬영 (10개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.studioShoot).length, 10);
      // 4. 드레스 & 턱시도 & 예복 (8개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.dressAndSuit).length, 8);
      // 5. 헤어 & 메이크업 & 케어 (6개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.hairAndBeauty).length, 6);
      // 6. 본식 스냅 & DVD & 부대 연출 (7개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.ceremonyDirecting).length, 7);
      // 7. 혼수 & 가전 & 가구 (6개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.homeAndAppliances).length, 6);
      // 8. 예물 & 예단 & 답례 (9개)
      expect(templates.where((t) => t.category == WeddingBudgetCategory.giftsAndFavors).length, 9);
    });

    testWidgets('상단 예산 대시보드 3단 KPI 및 분담 요약 칩이 정확히 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeddingBudgetSectionWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3단 KPI 카드
      expect(find.text('총 예상 예산'), findsOneWidget);
      expect(find.text('총 실제 지출액'), findsOneWidget);
      expect(find.text('남은 잔금 총액'), findsOneWidget);

      // 분담 요약 칩
      expect(find.text('👦 신랑 총 부담금'), findsOneWidget);
      expect(find.text('👧 신부 총 부담금'), findsOneWidget);
      expect(find.text('🤝 공동 부담금'), findsOneWidget);
    });

    testWidgets('WeddingBudgetTemplateModal 60개 템플릿 검색 및 담기 동작 검증', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingBudgetTemplateModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('결혼 예산 항목'), findsOneWidget);
      expect(find.text('60개 표준 템플릿에서 담거나 직접 추가해보세요'), findsOneWidget);
      expect(find.text('직접 입력'), findsOneWidget);

      // 검색 필터 테스트
      await tester.enterText(find.byType(TextField), '웨딩홀 대관료');
      await tester.pumpAndSettle();
      expect(find.text('웨딩홀 대관료 (생화 장식, 연출료 포함)'), findsOneWidget);
    });

    testWidgets('WeddingBudgetEditModal 8개 세부 입력 필드 지원 검증', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingBudgetEditModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1. 구분 카테고리'), findsOneWidget);
      expect(find.text('2. 항목명'), findsOneWidget);
      expect(find.text('3. 예상 예산 (원)'), findsOneWidget);
      expect(find.text('4. 계약금(예약금)'), findsOneWidget);
      expect(find.text('5. 잔금'), findsOneWidget);
      expect(find.text('6. 부담 구분'), findsOneWidget);
      expect(find.text('7. 진행 상황'), findsOneWidget);
      expect(find.text('8. 상세 메모'), findsOneWidget);
    });
  });
}
