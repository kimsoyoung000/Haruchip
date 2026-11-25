import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/home/screens/dashboard_screen.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/settings/screens/profile_settings_screen.dart';

void main() {
  testWidgets('메인 대시보드 상단 헤더 정리 (뷰모드 토글/순서편집 제거, 필터+알림 아이콘 1번째 탭 우측 배치)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainShellScreen())),
    );
    await tester.pumpAndSettle();

    // 제거 대상
    expect(find.text('순서 편집'), findsNothing);
    expect(find.text('✨ 나의 주요 디데이'), findsNothing);

    // 1번째 탭 우측: 카테고리 필터 아이콘 + 알림 종 아이콘
    expect(find.byKey(const Key('dashboard_category_filter_button')),
        findsOneWidget);
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

    // 필터 아이콘 탭 -> 카테고리 표시 모달 오픈
    await tester.tap(find.byKey(const Key('dashboard_category_filter_button')));
    await tester.pumpAndSettle();
    expect(find.text('카테고리 표시'), findsOneWidget);
  });

  testWidgets('모든 카테고리 카드의 세로 높이 완전 고정 (일정 0개 ~ 3개 동일 높이 148dp) 및 지난 일정 제외/임박순 정렬',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final catNotifier = container.read(categoryListProvider.notifier);
    catNotifier.replaceAll([
      Category(
        id: 'c-couple',
        categoryKey: 'couple',
        name: '커플',
        emoji: '❤️',
        colorHex: '#FF8DA1',
        createdAt: today,
      ),
      Category(
        id: 'c-plan',
        categoryKey: 'plan',
        name: '일정/약속',
        emoji: '📝',
        colorHex: '#60A5FA',
        createdAt: today,
      ),
      Category(
        id: 'c-military',
        categoryKey: 'military',
        name: '군대',
        emoji: '🎖️',
        colorHex: '#16A34A',
        createdAt: today,
      ),
      Category(
        id: 'c-empty',
        categoryKey: 'birthday',
        name: '생일',
        emoji: '🎂',
        colorHex: '#F472B6',
        createdAt: today,
      ),
    ]);

    final planNotifier = container.read(planListProvider.notifier);
    planNotifier.replaceAll([
      // 지난 일정 (메인 카드에 절대 노출되면 안 됨)
      PlanItem(
        id: 'past-1',
        title: '이미 지난 회의',
        date: today.subtract(const Duration(days: 3)),
        categoryKey: 'plan',
      ),
      // 임박순 정렬 검증용 (D-10, D-2, D-5, D-15 -> D-2, D-5, D-10 상위 3개만)
      PlanItem(
        id: 'up-10',
        title: '먼 일정 D10',
        date: today.add(const Duration(days: 10)),
        categoryKey: 'plan',
      ),
      PlanItem(
        id: 'up-2',
        title: '가장 임박 D2',
        date: today.add(const Duration(days: 2)),
        categoryKey: 'plan',
      ),
      PlanItem(
        id: 'up-5',
        title: '중간 일정 D5',
        date: today.add(const Duration(days: 5)),
        categoryKey: 'plan',
      ),
      PlanItem(
        id: 'up-15',
        title: '제외될 4번째 일정',
        date: today.add(const Duration(days: 15)),
        categoryKey: 'plan',
      ),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 지난 일정 자동 제외
    expect(find.text('이미 지난 회의'), findsNothing);

    // 2. 그룹 2 (일정/약속): 최대 3개 & 임박순 오름차순 (D-2 -> D-5 -> D-10, 4번째 제외)
    expect(find.text('가장 임박 D2'), findsOneWidget);
    expect(find.text('중간 일정 D5'), findsOneWidget);
    expect(find.text('먼 일정 D10'), findsOneWidget);
    expect(find.text('제외될 4번째 일정'), findsNothing);

    final y2 = tester.getTopLeft(find.text('가장 임박 D2')).dy;
    final y5 = tester.getTopLeft(find.text('중간 일정 D5')).dy;
    final y10 = tester.getTopLeft(find.text('먼 일정 D10')).dy;
    expect(y2, lessThan(y5));
    expect(y5, lessThan(y10));

    // 3. 빈 상태 플레이스홀더 확인
    expect(find.text('등록된 일정이 없어요'), findsWidgets);

    // 4. 모든 카드의 높이가 정확히 kFixedCardHeight(148.0)로 통일되었는지 확인
    final cards = find.byType(CategorySummaryDashboardCard);
    expect(cards, findsNWidgets(4));
    for (int i = 0; i < 4; i++) {
      final size = tester.getSize(cards.at(i));
      expect(size.height, CategorySummaryDashboardCard.kFixedCardHeight);
    }
  });

  testWidgets('프로필 & 설정 > 앱 환경설정 내 [카테고리 순서 편집] 메뉴 존재 및 시트 호출',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileSettingsScreen())),
    );
    await tester.pumpAndSettle();

    final orderTile = find.text('카테고리 순서 편집');
    await tester.scrollUntilVisible(orderTile, 300);
    expect(orderTile, findsOneWidget);

    await tester.tap(orderTile);
    await tester.pumpAndSettle();
    expect(find.text('완료'), findsOneWidget);
  });
}
