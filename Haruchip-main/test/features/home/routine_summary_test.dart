import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/logic/repeat_rule.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';

void main() {
  group('Routine Category Summary Dashboard Card Tests', () {
    testWidgets('renders routine card with upcoming daily and weekly routine items', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final routineCat = CategoryModel(
        id: 'cat-routine-1',
        categoryKey: 'routine',
        name: '루틴 / 계획표',
        icon: '🔄',
        colorHex: '#0284C7',
        createdAt: DateTime.now(),
      );

      final routineItem1 = PlanItem(
        id: 'routine-item-1',
        title: '필라테스 운동',
        date: today,
        categoryKey: 'routine',
        deadlineTime: const TimeOfDay(hour: 19, minute: 0),
        repeatConfig: const RepeatConfig(type: RepeatType.daily),
      );

      final routineItem2 = PlanItem(
        id: 'routine-item-2',
        title: '영어 회화 스터디',
        date: today.add(const Duration(days: 1)),
        categoryKey: 'routine',
        deadlineTime: const TimeOfDay(hour: 10, minute: 0),
        repeatConfig: const RepeatConfig(type: RepeatType.weekly, weekdays: [1, 3, 5]),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategorySummaryDashboardCard(
                category: routineCat,
                countUpItems: const [],
                countDownItems: [routineItem1, routineItem2],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card Header
      expect(find.text('루틴 / 계획표'), findsOneWidget);
      expect(find.text('🔄'), findsOneWidget);

      // Item titles rendered
      expect(find.text('필라테스 운동'), findsOneWidget);
      expect(find.text('영어 회화 스터디'), findsOneWidget);
    });

    testWidgets('renders empty state when no routine items are registered', (tester) async {
      final routineCat = CategoryModel(
        id: 'cat-routine-2',
        categoryKey: 'routine',
        name: '루틴',
        icon: '🔄',
        colorHex: '#0284C7',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategorySummaryDashboardCard(
                category: routineCat,
                countUpItems: const [],
                countDownItems: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('등록된 루틴 일정이 없어요'), findsOneWidget);
    });
  });
}
