import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/military/models/military_rank.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';

void main() {
  group('CategoryModel & Metadata Tests', () {
    test('CategoryModel metadata serialization works cleanly', () {
      final category = CategoryModel(
        id: 'cat-test-1',
        categoryKey: 'military',
        name: '군대 (곰신)',
        createdAt: DateTime(2025, 1, 1),
        metadata: {
          'isInitialized': true,
          'branch': 'publicService',
          'enlistDate': '2025-01-10T00:00:00.000',
          'dischargeDate': '2026-10-10T00:00:00.000',
        },
      );

      final json = category.toJson();
      expect(json['metadata']['isInitialized'], isTrue);
      expect(json['metadata']['branch'], 'publicService');

      final restored = CategoryModel.fromJson(json);
      expect(restored.id, 'cat-test-1');
      expect(restored.metadata?['branch'], 'publicService');
      expect(restored.metadata?['isInitialized'], isTrue);
    });

    test('MilitaryBranch includes publicService with 21 months service', () {
      expect(MilitaryBranch.publicService.labelKo, '사회복무요원');
      expect(totalServiceMonths[MilitaryBranch.publicService], 21);

      final enlist = DateTime(2025, 1, 15);
      final discharge = defaultDischargeDate(enlist, MilitaryBranch.publicService);
      expect(discharge, DateTime(2026, 10, 15));
    });
  });

  group('Dual List Partitioning Tests', () {
    test('Items partition correctly into count-up (daysCount) and count-down (dday)', () {
      final items = [
        PlanItem(
          id: '1',
          title: '입대일',
          date: DateTime.now().subtract(const Duration(days: 100)),
          categoryKey: 'military',
          displayMode: DdayDisplayMode.daysCount,
        ),
        PlanItem(
          id: '2',
          title: '전역일',
          date: DateTime.now().add(const Duration(days: 440)),
          categoryKey: 'military',
          displayMode: DdayDisplayMode.dday,
        ),
        PlanItem(
          id: '3',
          title: '첫 휴가',
          date: DateTime.now().add(const Duration(days: 30)),
          categoryKey: 'military',
          displayMode: DdayDisplayMode.dday,
        ),
      ];

      final countUpItems = items.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
      final countDownItems = items.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();

      expect(countUpItems.length, 1);
      expect(countUpItems.first.title, '입대일');

      expect(countDownItems.length, 2);
      expect(countDownItems.map((i) => i.title), containsAll(['전역일', '첫 휴가']));
    });
  });
}
