import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/wedding/data/wedding_budget_master_items.dart';
import 'package:haruchip/features/wedding/data/wedding_standard_items.dart';
import 'package:haruchip/features/wedding/models/wedding_budget_item.dart';
import 'package:haruchip/features/wedding/models/wedding_item.dart';
import 'package:haruchip/features/wedding/providers/wedding_budget_provider.dart';
import 'package:haruchip/features/wedding/providers/wedding_provider.dart';
import 'package:haruchip/features/wedding/widgets/wedding_budget_edit_modal.dart';
import 'package:haruchip/features/wedding/widgets/wedding_budget_section_widget.dart';
import 'package:haruchip/features/wedding/widgets/wedding_budget_template_modal.dart';
import 'package:haruchip/features/wedding/widgets/wedding_category_view.dart';
import 'package:haruchip/features/wedding/widgets/wedding_template_manager_modal.dart';

void main() {
  group('1. 일정 등록 시 D-Day 실시간 자동 정렬 및 57종 라이브러리 보존', () {
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

      expect(list[0].id, 'imminent-1');
      expect(list[1].id, 'imminent-5');
      expect(list[2].id, 'future-30');
      expect(list[3].id, 'undated-1');
    });

    test('57종 표준 추천 항목 보존 및 초성/키워드 검색 동작 검증', () {
      final masters = createDefaultWeddingMasterItems();
      expect(masters.length, greaterThanOrEqualTo(57));

      expect(matchesKoreanQuery('본식 스냅 계약', '스냅'), isTrue);
      expect(matchesKoreanQuery('본식 스냅 계약', 'ㅅㄴ'), isTrue);
      expect(matchesKoreanQuery('혼주 한복 대여', 'ㅎㅂ'), isTrue);
      expect(matchesKoreanQuery('혼주 한복 대여', '드레스'), isFalse);
    });
  });

  group('2. 57종 스마트 추천 피커 모달 (직접입력 + 초성검색 + 5대 도메인 탭 칩)', () {
    testWidgets('직접 입력 추가, 초성 검색(ㅅㄴ), 5대 도메인 탭 및 칩 토글 검증', (tester) async {
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

      // 강제 시기별/번호 폴더 탭 폐기 & 5대 도메인 탭 확인
      expect(find.text('D-1년 전'), findsNothing);
      expect(find.text('1. 웨딩홀 & 본식'), findsNothing);
      expect(find.text('웨딩홀 & 본식'), findsOneWidget);
      expect(find.text('스드메 & 촬영'), findsOneWidget);
      expect(find.text('예물 & 예복'), findsOneWidget);
      expect(find.text('신혼여행 & 신혼집'), findsOneWidget);
      expect(find.text('뷰티 & 케어'), findsOneWidget);

      // 초성 검색('ㅅㄴ') -> 본식 스냅 계약 매칭 확인
      await tester.enterText(
        find.byKey(const Key('wedding_picker_search_input')),
        'ㅅㄴ',
      );
      await tester.pumpAndSettle();
      expect(find.text('본식 스냅 계약'), findsOneWidget);

      // 직접 입력 추가 (미완료·날짜 미정 상태로 추가됨)
      await tester.enterText(
        find.byKey(const Key('wedding_picker_custom_input')),
        '아이폰 스냅 예약',
      );
      await tester.tap(find.byKey(const Key('wedding_picker_custom_add_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('wedding_picker_search_input')),
        '',
      );
      await tester.pumpAndSettle();
      expect(find.text('아이폰 스냅 예약'), findsOneWidget);
    });
  });

  group('3. 단일 D-Day 임박순 정렬, 날짜 미정 접기/펼치기, 청모 임박순 & 사후정산 예산 통합', () {
    testWidgets('인위적 그룹핑 폐기, D-Day 오름차순 정렬, 미정 접기/펼치기, 청모 정렬, 예산표 사후정산 탭 검증', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final itemFar = WeddingItem(
        id: 'chrono-far',
        orderIndex: 1,
        title: '본식 예식',
        standardOffsetDays: 0,
        stage: WeddingStage.finalCheckAndCeremony,
        targetDate: now.add(const Duration(days: 170)),
      );
      final itemSoon = WeddingItem(
        id: 'chrono-soon',
        orderIndex: 2,
        title: '드레스 투어',
        standardOffsetDays: 90,
        stage: WeddingStage.studimeAndRing,
        targetDate: now.add(const Duration(days: 2)),
        location: '로브드K',
      );
      final itemMid = WeddingItem(
        id: 'chrono-mid',
        orderIndex: 3,
        title: '스튜디오 촬영',
        standardOffsetDays: 60,
        stage: WeddingStage.studioShoot,
        targetDate: now.add(const Duration(days: 16)),
      );

      final notifier = container.read(weddingListProvider.notifier);
      notifier.addItem(itemFar);
      notifier.addItem(itemSoon);
      notifier.addItem(itemMid);

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

      // 1) 인위적 번호 폴더 완전 폐기 확인
      expect(find.text('1. 웨딩홀 & 본식'), findsNothing);
      expect(find.text('2. 스드메 & 촬영'), findsNothing);
      expect(find.byKey(const Key('wedding_chronological_list')), findsOneWidget);

      // 2) 엄격한 D-Day 오름차순(D-2 -> D-16 -> D-170) 수직 배치 확인
      final ySoon = tester.getTopLeft(find.byKey(const Key('wedding_slim_tile_chrono-soon'))).dy;
      final yMid = tester.getTopLeft(find.byKey(const Key('wedding_slim_tile_chrono-mid'))).dy;
      final yFar = tester.getTopLeft(find.byKey(const Key('wedding_slim_tile_chrono-far'))).dy;
      expect(ySoon, lessThan(yMid));
      expect(yMid, lessThan(yFar));

      // 3) 날짜 미정 항목은 최하단 [날짜 미정 항목 (N개)]에 기본 접힘 -> 탭하면 펼침
      expect(find.byKey(const Key('wedding_undated_section_header')), findsOneWidget);
      expect(find.text('양가 부모님 인사드리기 (신부 쪽)'), findsNothing);
      await tester.tap(find.byKey(const Key('wedding_undated_section_header')));
      await tester.pumpAndSettle();
      expect(find.text('양가 부모님 인사드리기 (신부 쪽)'), findsOneWidget);

      // 4) 독립 사후정산 섹션 폐기 & 웨딩 예산·지출표 3단 탭(전체/본식 전/본식 당일·사후 정산) 확인
      expect(find.byKey(const Key('wedding_after_wedding_section')), findsNothing);
      expect(find.byKey(const Key('wedding_budget_phase_all')), findsOneWidget);
      expect(find.byKey(const Key('wedding_budget_phase_preWedding')), findsOneWidget);
      expect(find.byKey(const Key('wedding_budget_phase_postWedding')), findsOneWidget);

      // [본식 당일/사후 정산] 탭 선택 -> 사후 정산 항목만 노출
      await tester.ensureVisible(
        find.byKey(const Key('wedding_budget_phase_postWedding')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wedding_budget_phase_postWedding')));
      await tester.pumpAndSettle();
      expect(find.text('사회자 · 축가 · 헬퍼 이모님 수고비'), findsOneWidget);
      expect(find.text('지방 하객 차비(교통비) 정산'), findsOneWidget);
      expect(find.text('직장 · 지인 답례품 전달'), findsOneWidget);
      expect(find.text('웨딩홀 대관료 & 식대'), findsNothing);

      // 5) 청첩장 모임 D-Day 임박순 정렬 확인
      expect(find.byKey(const Key('wedding_invitation_meetings_section')), findsOneWidget);
      expect(find.byKey(const Key('wedding_meetings_sorted_list')), findsOneWidget);
    });
  });

  group('4. 목표 예산 집계 요약 대시보드 & 스마트 지출 상세 관리 엔진', () {
    test('60개 마스터 템플릿이 8대 대분류에 정확한 수량으로 존재한다', () {
      final templates = create60WeddingBudgetMasterTemplates();
      expect(templates.length, 60);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.greeting).length, 6);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.hallAndMeal).length, 8);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.studioShoot).length, 10);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.dressAndSuit).length, 8);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.hairAndBeauty).length, 6);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.ceremonyDirecting).length, 7);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.homeAndAppliances).length, 6);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.giftsAndFavors).length, 9);
    });

    testWidgets('Executive Summary Card: 목표 예산 대비 초과/절약 뱃지, 듀얼 바, 부담 주체별 소계 검증', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeddingBudgetSectionWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 기본 목표 4,000만 원 vs 초기 확정액 4,635만 원 -> 초과 뱃지
      expect(find.text('목표 예산'), findsOneWidget);
      expect(find.text('실제 확정액'), findsOneWidget);
      expect(find.textContaining('초과'), findsOneWidget);
      expect(find.textContaining('기지불 완료'), findsOneWidget);
      expect(find.textContaining('남은 잔금'), findsWidgets);
      expect(find.textContaining('신랑 부담'), findsOneWidget);
      expect(find.textContaining('신부 부담'), findsOneWidget);
      expect(find.textContaining('공동 부담'), findsOneWidget);

      // 목표 예산을 5,000만 원으로 올리면 -> '절약 중' 뱃지로 즉시 전환
      container
          .read(weddingTargetBudgetProvider.notifier)
          .setTargetBudget(50000000);
      await tester.pumpAndSettle();
      expect(find.textContaining('절약 중'), findsOneWidget);
    });

    testWidgets('WeddingBudgetEditModal: 총액-계약금 자동 잔금 계산 및 결제수단/할부/현금영수증 검증', (tester) async {
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

      // 총 견적 1000만원, 계약금 250만원 입력 -> 남은 잔금 750만원 자동 계산
      await tester.enterText(
        find.byKey(const Key('wedding_budget_total_input')),
        '10000000',
      );
      await tester.enterText(
        find.byKey(const Key('wedding_budget_deposit_input')),
        '2500000',
      );
      await tester.pumpAndSettle();

      final balanceField = tester.widget<TextField>(
        find.byKey(const Key('wedding_budget_balance_input')),
      );
      expect(balanceField.controller?.text, '7500000');

      // 결제 수단 4종 + 할부 4종 + 현금영수증 토글 존재 확인
      expect(find.byKey(const Key('wedding_payment_method_creditCard')), findsOneWidget);
      expect(find.byKey(const Key('wedding_payment_method_debitCard')), findsOneWidget);
      expect(find.byKey(const Key('wedding_payment_method_bankTransfer')), findsOneWidget);
      expect(find.byKey(const Key('wedding_payment_method_cash')), findsOneWidget);
      expect(find.byKey(const Key('wedding_installment_0')), findsOneWidget);
      expect(find.byKey(const Key('wedding_installment_3')), findsOneWidget);
      expect(find.byKey(const Key('wedding_installment_6')), findsOneWidget);
      expect(find.byKey(const Key('wedding_installment_12')), findsOneWidget);
      expect(find.byKey(const Key('wedding_cash_receipt_switch')), findsOneWidget);
    });

    test('잔금 결제 예정일 설정 시 칩 캘린더(planListProvider)에 자동 등록된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dueDate = DateTime(2026, 12, 20);
      container.read(weddingBudgetListProvider.notifier).addItem(
            WeddingBudgetItem(
              id: 'bal-sync-1',
              title: '스튜디오 잔금',
              estimatedBudget: 3000000,
              deposit: 500000,
              balance: 2500000,
              status: BudgetPaymentStatus.contracted,
              balanceDueDate: dueDate,
              paymentMethod: WeddingPaymentMethod.bankTransfer,
              cashReceiptIssued: true,
            ),
          );

      final plans = container.read(planListProvider);
      final synced = plans.firstWhere(
        (p) => p.id == 'plan-wedding-balance-bal-sync-1',
      );
      expect(synced.categoryKey, 'wedding');
      expect(synced.date, dueDate);
      expect(synced.title, contains('스튜디오 잔금'));
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
      expect(find.text('직접 입력'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '웨딩홀 대관료');
      await tester.pumpAndSettle();
      expect(find.text('웨딩홀 대관료 (생화 장식, 연출료 포함)'), findsOneWidget);
    });
  });
}
