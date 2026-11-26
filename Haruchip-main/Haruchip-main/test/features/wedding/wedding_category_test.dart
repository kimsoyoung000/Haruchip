import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/wedding/data/wedding_budget_master_items.dart';
import 'package:haruchip/features/wedding/data/wedding_standard_items.dart';
import 'package:haruchip/features/wedding/logic/wedding_scheduler_engine.dart';
import 'package:haruchip/features/wedding/models/wedding_budget_item.dart';
import 'package:haruchip/features/wedding/models/wedding_item.dart';
import 'package:haruchip/features/wedding/providers/wedding_budget_provider.dart';
import 'package:haruchip/features/wedding/providers/wedding_provider.dart';
import 'package:haruchip/features/wedding/widgets/wedding_category_view.dart';
import 'package:haruchip/features/wedding/widgets/wedding_couple_share_modal.dart';
import 'package:haruchip/features/wedding/widgets/wedding_template_manager_modal.dart';

void main() {
  group('Wedding Standard Master Items & Starter Items', () {
    test('createDefaultWeddingMasterItems contains exactly 57 distinct individual items', () {
      final items = createDefaultWeddingMasterItems();
      expect(items.length, 57);

      final ids = items.map((i) => i.id).toSet();
      expect(ids.length, 57, reason: 'Every item must have a unique ID');

      final orderIndices = items.map((i) => i.orderIndex).toSet();
      expect(orderIndices.length, 57, reason: 'Every item must have a unique order index');
      expect(items.first.orderIndex, 1);
      expect(items.last.orderIndex, 57);
    });

    test('createStarterWeddingItems contains 5 key milestone items', () {
      final starter = createStarterWeddingItems();
      expect(starter.length, 5);
      expect(starter.any((i) => i.title.contains('부모님 인사')), isTrue);
      expect(starter.any((i) => i.title.contains('웨딩홀 계약')), isTrue);
      expect(starter.any((i) => i.title.contains('드레스샵 계약')), isTrue);
      expect(starter.any((i) => i.title.contains('스튜디오 촬영 진행')), isTrue);
      expect(starter.any((i) => i.title.contains('본식 당일')), isTrue);
    });

    test('All 6 wedding stages are covered in master items', () {
      final items = createDefaultWeddingMasterItems();
      final stages = items.map((i) => i.stage).toSet();
      expect(stages.length, WeddingStage.values.length);
      for (final stage in WeddingStage.values) {
        expect(stages.contains(stage), isTrue);
      }
    });

    test('Weekday preferred items have isWeekdayPreferred flag set to true', () {
      final items = createDefaultWeddingMasterItems();
      final weekdayItems = items.where((i) => i.isWeekdayPreferred).toList();

      expect(weekdayItems.isNotEmpty, isTrue);
      expect(weekdayItems.any((i) => i.title.contains('드레스샵 계약')), isTrue);
      expect(weekdayItems.any((i) => i.title.contains('스튜디오 촬영 진행')), isTrue);
      expect(weekdayItems.any((i) => i.title.contains('본식 드레스 최종 가봉')), isTrue);
      expect(weekdayItems.any((i) => i.title.contains('웨딩 네일')), isTrue);
    });
  });

  group('WeddingItem Model Tests', () {
    test('dDayLabel returns countdown label and formattedDateTime details with location', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final item = WeddingItem(
        id: 'test-1',
        orderIndex: 1,
        title: '웨딩홀 투어',
        standardOffsetDays: 300,
        stage: WeddingStage.hallAndPlanner,
        targetDate: futureDate,
        deadlineTime: const TimeOfDay(hour: 14, minute: 0),
        location: '더채플앳논현',
      );

      expect(item.dDayLabel(), 'D-10');
      expect(item.formattedDateTime.contains('14:00'), isTrue);
      expect(item.location, '더채플앳논현');
    });

    test('JSON serialization toJson and fromJson preserves location and time', () {
      final original = WeddingItem(
        id: 'wedding-std-10',
        orderIndex: 10,
        title: '드레스샵 계약',
        standardOffsetDays: 240,
        stage: WeddingStage.studimeAndRing,
        targetDate: DateTime(2025, 5, 20),
        deadlineTime: const TimeOfDay(hour: 14, minute: 30),
        location: '로브드K 청담',
        memo: '비즈 맛집 투어 예약',
        isCompleted: true,
        isWeekdayPreferred: true,
      );

      final json = original.toJson();
      final restored = WeddingItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.location, '로브드K 청담');
      expect(restored.memo, '비즈 맛집 투어 예약');
      expect(restored.isCompleted, isTrue);
      expect(restored.isWeekdayPreferred, isTrue);
    });
  });

  group('WeddingSchedulerEngine Smart Scheduling & Snapping', () {
    test('Snaps items strictly to Saturday slots when only Saturday is selected', () {
      final weddingDate = DateTime(2025, 10, 18);
      const engine = WeddingSchedulerEngine();
      final items = createDefaultWeddingMasterItems();
      final scheduled = engine.scheduleItems(
        weddingDate: weddingDate,
        items: items,
        availableSlots: {AvailableTimeSlot.saturday},
      );

      expect(scheduled.length, 57);
      for (final item in scheduled) {
        expect(item.targetDate, isNotNull);
        expect(item.targetDate!.weekday, DateTime.saturday,
            reason: 'Item "${item.title}" should be scheduled on a Saturday');
      }
    });

    test('Prioritizes weekday evening slots for weekday-preferred items when available', () {
      final weddingDate = DateTime(2025, 10, 18);
      const engine = WeddingSchedulerEngine();
      final items = createDefaultWeddingMasterItems();
      final scheduled = engine.scheduleItems(
        weddingDate: weddingDate,
        items: items,
        availableSlots: {
          AvailableTimeSlot.saturday,
          AvailableTimeSlot.weekdayEvening,
        },
      );

      final dressTour = scheduled.firstWhere((i) => i.title.contains('드레스샵 계약'));
      expect(
        dressTour.targetDate!.weekday != DateTime.saturday &&
            dressTour.targetDate!.weekday != DateTime.sunday,
        isTrue,
        reason: 'Dress tour should snap to a weekday evening slot',
      );
      expect(dressTour.deadlineTime, const TimeOfDay(hour: 19, minute: 30));
    });
  });

  group('WeddingNotifier & Riverpod State Flow', () {
    test('Initializes with 5 starter items and allows syncing templates and custom items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialItems = container.read(weddingListProvider);
      expect(initialItems.length, 5);

      final initialStats = container.read(weddingStatsProvider);
      expect(initialStats.total, 5);
      expect(initialStats.completed, 0);

      // Sync with 10 templates and 1 custom item
      final tenTemplateIds = createDefaultWeddingMasterItems().take(10).map((i) => i.id).toSet();
      final customItem = WeddingItem(
        id: 'wedding-custom-1',
        orderIndex: 11,
        title: '청모 식당 예약',
        standardOffsetDays: 20,
        stage: WeddingStage.invitationAndGuest,
      );

      container.read(weddingListProvider.notifier).syncSelectedTemplates(tenTemplateIds, [customItem]);

      final updatedItems = container.read(weddingListProvider);
      expect(updatedItems.length, 11);
      expect(updatedItems.any((i) => i.title == '청모 식당 예약'), isTrue);
    });

    test('toggleItemCompletion updates completed count and ratio', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(weddingListProvider);
      container.read(weddingListProvider.notifier).toggleItemCompletion(items.first.id);

      final stats = container.read(weddingStatsProvider);
      expect(stats.completed, 1);
      expect(stats.ratio, closeTo(1 / items.length, 0.001));
    });
  });

  group('Wedding Budget & Expenses Provider', () {
    test('Calculates budget summary accurately across groom, bride, and joint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final summary = container.read(weddingBudgetSummaryProvider);
      expect(summary.totalEstimated > 0, isTrue);
      expect(summary.totalActual > 0, isTrue);
      expect(summary.groomShare > 0, isTrue);
      expect(summary.brideShare > 0, isTrue);
      expect(summary.jointShare > 0, isTrue);
      expect(summary.totalActual, summary.groomShare + summary.brideShare + summary.jointShare);
    });

    test('Adds and deletes budget items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(weddingBudgetListProvider).length;

      const newItem = WeddingBudgetItem(
        id: 'budget-test-custom',
        title: '신부 웨딩슈즈',
        estimatedBudget: 300000,
        deposit: 100000,
        balance: 200000,
        payer: ExpensePayer.groom,
      );

      container.read(weddingBudgetListProvider.notifier).addItem(newItem);
      expect(container.read(weddingBudgetListProvider).length, initialCount + 1);

      container.read(weddingBudgetListProvider.notifier).removeItem('budget-test-custom');
      expect(container.read(weddingBudgetListProvider).length, initialCount);
    });
  });

  group('Wedding Widgets Rendering', () {
    testWidgets('WeddingCategoryView renders slim checklist accordion, smart picker button, and executive budget summary', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeddingCategoryView(),
              ),
            ),
          ),
        ),
      );

      // Checklist header and smart picker add button
      expect(find.text('웨딩 체크리스트'), findsOneWidget);
      expect(find.byKey(const Key('wedding_open_smart_picker_btn')), findsOneWidget);

      // 1-line slim tile items
      expect(find.text('#01'), findsNothing);
      expect(find.text('양가 부모님 인사드리기 (신부 쪽)'), findsOneWidget);

      // Executive budget summary section
      expect(find.text('웨딩 예산 · 지출표'), findsOneWidget);
      expect(find.text('목표 예산'), findsOneWidget);
      expect(find.text('실제 확정액'), findsOneWidget);
      expect(find.textContaining('남은 잔금'), findsWidgets);
    });

    testWidgets('WeddingTemplateManagerModal renders 57 master library smart picker with 5 domain tabs and custom input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingTemplateManagerModal(),
            ),
          ),
        ),
      );

      expect(find.text('결혼 준비 항목 라이브러리'), findsOneWidget);
      expect(find.byKey(const Key('wedding_picker_custom_input')), findsOneWidget);
      expect(find.byKey(const Key('wedding_picker_search_input')), findsOneWidget);
      expect(find.text('웨딩홀 & 본식'), findsOneWidget);
      expect(find.text('스드메 & 촬영'), findsOneWidget);
      expect(find.text('D-1년 전'), findsNothing);
      expect(find.text('1. 웨딩홀 & 본식'), findsNothing);
      expect(find.text('선택한 5개 추가하기'), findsOneWidget);
    });

    testWidgets('WeddingCoupleShareModal renders invite code and partner connection input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingCoupleShareModal(),
            ),
          ),
        ),
      );

      expect(find.text('신랑 · 신부 공동 관리'), findsOneWidget);
      expect(find.text('내 초대 코드'), findsOneWidget);
      expect(find.text('WED-7729-HARU'), findsOneWidget);
      expect(find.text('상대방 초대 코드 등록'), findsOneWidget);
      expect(find.text('연결하기'), findsOneWidget);
    });

    testWidgets('CategoryDetailScreen for wedding removes sparkle & duplicate + and keeps only [👥][🎨][⚙️]', (tester) async {
      final category = Category(
        id: 'cat-wedding',
        categoryKey: 'wedding',
        name: '결혼 준비',
        emoji: '💍',
        colorHex: '#E53E3E',
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CategoryDetailScreen(category: category),
          ),
        ),
      );

      // 반짝이(✨) 및 상단 중복 [+] 아이콘 완전 제거 확인
      expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
      expect(find.byKey(const Key('category_add_item_button')), findsNothing);

      // 우측 공통 규격 3종([👥], [🎨], [⚙️])만 깔끔하게 유지
      expect(
        find.byKey(const Key('partner_share_dropdown_button_wedding')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('category_decorate_button')), findsOneWidget);
      expect(
        find.byKey(const Key('category_section_manage_button')),
        findsOneWidget,
      );

      // Category body should have the refined WeddingCategoryView
      expect(find.text('웨딩 체크리스트'), findsOneWidget);
    });
  });

  group('60 Standard Wedding Budget Master Database Tests', () {
    test('create60WeddingBudgetMasterTemplates contains exactly 60 distinct templates across 8 categories', () {
      final templates = create60WeddingBudgetMasterTemplates();
      expect(templates.length, 60);

      final ids = templates.map((t) => t.id).toSet();
      expect(ids.length, 60);

      final categories = templates.map((t) => t.category).toSet();
      expect(categories.length, 8);
      expect(categories.length, WeddingBudgetCategory.values.length);

      // 대분류별 개수 정확성 검증
      expect(templates.where((t) => t.category == WeddingBudgetCategory.greeting).length, 6);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.hallAndMeal).length, 8);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.studioShoot).length, 10);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.dressAndSuit).length, 8);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.hairAndBeauty).length, 6);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.ceremonyDirecting).length, 7);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.homeAndAppliances).length, 6);
      expect(templates.where((t) => t.category == WeddingBudgetCategory.giftsAndFavors).length, 9);
    });

    test('addTemplateItem adds master template to budget list accurately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weddingBudgetListProvider.notifier);
      final initialCount = container.read(weddingBudgetListProvider).length;

      final tpl = create60WeddingBudgetMasterTemplates().first;
      notifier.addTemplateItem(tpl);

      final list = container.read(weddingBudgetListProvider);
      expect(list.length, initialCount + 1);
      expect(list.any((i) => i.title == tpl.title), isTrue);
    });
  });

  group('Real-Time D-Day Closeness Sorting Tests', () {
    test('compareWeddingItemsByCloseness sorts imminent dates first and undated items at the bottom', () {
      final now = DateTime(2026, 5, 1);
      final item1 = WeddingItem(
        id: 'w-1',
        orderIndex: 1,
        title: '날짜 미지정 항목 A',
        standardOffsetDays: 300,
        stage: WeddingStage.hallAndPlanner,
        targetDate: null,
      );
      final item2 = WeddingItem(
        id: 'w-2',
        orderIndex: 2,
        title: 'D-30 항목',
        standardOffsetDays: 200,
        stage: WeddingStage.studimeAndRing,
        targetDate: DateTime(2026, 5, 31),
      );
      final item3 = WeddingItem(
        id: 'w-3',
        orderIndex: 3,
        title: 'D-2 항목 (가장 임박)',
        standardOffsetDays: 100,
        stage: WeddingStage.studioShoot,
        targetDate: DateTime(2026, 5, 3),
      );
      final item4 = WeddingItem(
        id: 'w-4',
        orderIndex: 4,
        title: 'D-10 항목',
        standardOffsetDays: 50,
        stage: WeddingStage.finalCheckAndCeremony,
        targetDate: DateTime(2026, 5, 11),
      );
      final item5 = WeddingItem(
        id: 'w-5',
        orderIndex: 5,
        title: '날짜 미지정 항목 B',
        standardOffsetDays: 10,
        stage: WeddingStage.invitationAndGuest,
        targetDate: null,
      );

      final items = [item1, item2, item3, item4, item5];
      items.sort((a, b) => compareWeddingItemsByCloseness(a, b, now));

      // 임박순 정렬 결과: D-2 -> D-10 -> D-30 -> 미지정 A -> 미지정 B
      expect(items[0].id, 'w-3');
      expect(items[1].id, 'w-4');
      expect(items[2].id, 'w-2');
      expect(items[3].id, 'w-1');
      expect(items[4].id, 'w-5');
    });
  });

  group('Slim Checklist Tile & Edit Sheet Tests', () {
    testWidgets('Tapping slim checklist tile opens 3-second WeddingItemEditModal with memo & location', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final customItem = WeddingItem(
        id: 'accordion-test-1',
        orderIndex: 1,
        title: '스튜디오 촬영 드레스 셀렉',
        standardOffsetDays: 150,
        stage: WeddingStage.studimeAndRing,
        targetDate: DateTime.now().add(const Duration(days: 5)),
        location: '로브드K 청담',
        memo: '비즈 풍성 드레스 및 실크 슬림 드레스 셀렉 예정',
        weekdayNotice: '수~금요일 방문 시 주말보다 한적하게 피팅 가능',
      );

      container.read(weddingListProvider.notifier).addItem(customItem);

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

      // 1줄 슬림 타일 표시 확인
      expect(find.text('스튜디오 촬영 드레스 셀렉'), findsOneWidget);
      expect(find.text('· 📍로브드K 청담'), findsOneWidget);

      // 타일 탭 -> 일정 수정 바텀시트 오픈
      await tester.tap(find.byKey(const Key('wedding_slim_tile_accordion-test-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('일정 수정'), findsOneWidget);
      expect(find.text('비즈 풍성 드레스 및 실크 슬림 드레스 셀렉 예정'), findsOneWidget);
    });
  });
}
