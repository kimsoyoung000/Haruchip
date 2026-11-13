import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/screens/couple_category_detail_screen.dart';
import 'package:haruchip/features/onboarding/screens/category_selection_screen.dart';
import 'package:haruchip/features/onboarding/screens/dashboard_view_mode_screen.dart';

Future<ProviderContainer> _pumpSelection(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CategorySelectionScreen()),
    ),
  );
  return container;
}

void main() {
  testWidgets('카테고리를 1개 이상 고르기 전에는 다음 단계로 이동하지 않는다', (tester) async {
    await _pumpSelection(tester);

    expect(find.text('카테고리를 1개 이상 선택해주세요'), findsOneWidget);
    expect(find.byType(DashboardViewModeScreen), findsNothing);
  });

  testWidgets('온보딩에서 카테고리를 고르고 다음으로를 누르면 설정 폼 루프 없이 바로 뷰모드 화면으로 직행한다', (tester) async {
    final c = await _pumpSelection(tester);

    await tester.tap(find.text('커플'));
    await tester.pump();
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();

    // 온보딩 중에는 세부 설정 모달이 뜨지 않고 바로 DashboardViewModeScreen으로 이동
    expect(find.text('만난 날 및 재회 설정'), findsNothing);
    expect(find.byType(DashboardViewModeScreen), findsOneWidget);

    final cats = c.read(categoryListProvider);
    expect(cats.length, 1);
    expect(cats.first.categoryKey, 'couple');
    // 초기에는 아직 초기 설정이 완료되지 않은 상태(metadata null 또는 isInitialized != true)
    expect(cats.first.metadata?['isInitialized'], isNot(true));
  });

  testWidgets('메인 대시보드에서 미설정 커플 카테고리 최초 진입 시 설정 폼이 뜨고, 완료 후 재진입 시에는 뜨지 않는다', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 초기 상태: 온보딩에서 seed된 미설정 커플 카테고리
    final initialCategory = CategoryModel(
      id: 'cat-couple-1',
      categoryKey: 'couple',
      name: '커플',
      emoji: '💕',
      colorHex: '#FF6B6B',
      createdAt: DateTime.now(),
    );
    container.read(categoryListProvider.notifier).upsertCategory(initialCategory);

    // 1. 최초 진입 (First Tap)
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CoupleCategoryDetailScreen(category: initialCategory),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 아직 미설정이므로 기존 설정 모달('만난 날 및 재회 설정')이 바로 노출됨
    expect(find.text('만난 날 및 재회 설정'), findsOneWidget);

    // 사용자가 '설정 완료' 탭
    await tester.tap(find.text('설정 완료'));
    await tester.pumpAndSettle();

    // 모달이 닫히고, 카테고리에 isInitialized = true 가 저장됨
    final updatedCategory = container.read(categoryListProvider).firstWhere((c) => c.id == initialCategory.id);
    expect(updatedCategory.metadata?['isInitialized'], isTrue);

    // 2. 두 번째 진입 (Subsequent Tap)
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CoupleCategoryDetailScreen(category: updatedCategory),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 이미 설정 완료 플래그가 확정되었으므로 설정 모달 없이 정상 커플 화면으로 즉시 진입
    expect(find.text('만난 날 및 재회 설정'), findsNothing);
    expect(find.byType(CoupleCategoryDetailScreen), findsOneWidget);
  });
}
