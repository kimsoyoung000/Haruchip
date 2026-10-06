import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/controllers/baby_category_controller.dart';
import 'package:haruchip/features/categories/data/baby_health_database.dart';
import 'package:haruchip/features/categories/models/baby_profile.dart';

void main() {
  group('Baby Category - Age & Milestone Calculations', () {
    const controller = BabyCategoryController();

    test('formatBabyDaysCount calculates birth day as 1st day', () {
      final today = DateTime(2026, 10, 6);
      final birthToday = DateTime(2026, 10, 6);
      final birth100DaysAgo = DateTime(2026, 10, 6).subtract(const Duration(days: 99));

      expect(controller.formatBabyDaysCount(birthToday, today), '태어난 지 1일째');
      expect(controller.formatBabyDaysCount(birth100DaysAgo, today), '태어난 지 100일째');
    });

    test('formatBabyAgeDetailed generates detailed month, day, week string', () {
      final now = DateTime(2026, 10, 6);
      final birth = DateTime(2026, 6, 1); // June 1 to Oct 6 = 4 months 5 days

      final result = controller.formatBabyAgeDetailed(birth, now);
      expect(result.contains('4개월 5일차'), isTrue);
      expect(result.contains('주'), isTrue);
    });

    test('getGrowthMilestones contains 100일, 돌, 200일, etc.', () {
      final birth = DateTime(2026, 1, 1);
      final milestones = controller.getGrowthMilestones(birth, DateTime(2026, 1, 1));

      expect(milestones.any((m) => m.label == '100일'), isTrue);
      expect(milestones.any((m) => m.label.contains('첫돌')), isTrue);
      expect(milestones.firstWhere((m) => m.label == '100일').daysLeft, 99);
    });
  });

  group('Baby Category - Realtime Feeding Countdown', () {
    const controller = BabyCategoryController();

    test('calculateNextFeeding returns overdue when feeding interval passed', () {
      final now = DateTime(2026, 10, 6, 14, 0);
      final lastFeeding = DateTime(2026, 10, 6, 10, 0); // 4 hours ago (interval is 3h)

      final logs = [
        BabyCareLogItem(
          id: 'log-1',
          type: BabyCareLogType.feeding,
          timestamp: lastFeeding,
          amount: 160,
          subType: '분유',
        ),
      ];

      final status = controller.calculateNextFeeding(logs, 3, now);
      expect(status.isOverdue, isTrue);
      expect(status.statusText.contains('수유 텀'), isTrue);
      expect(status.statusText.contains('초과'), isTrue);
    });

    test('calculateNextFeeding returns due now when within 10 minutes', () {
      final now = DateTime(2026, 10, 6, 13, 0);
      final lastFeeding = DateTime(2026, 10, 6, 10, 0); // exactly 3 hours ago

      final logs = [
        BabyCareLogItem(
          id: 'log-1',
          type: BabyCareLogType.feeding,
          timestamp: lastFeeding,
        ),
      ];

      final status = controller.calculateNextFeeding(logs, 3, now);
      expect(status.isDueNow, isTrue);
      expect(status.statusText, '수유 시간 도래 (D-0)');
    });

    test('calculateNextFeeding returns remaining time before feeding due', () {
      final now = DateTime(2026, 10, 6, 11, 40);
      final lastFeeding = DateTime(2026, 10, 6, 10, 0); // 1h 40m ago, due at 13:00 (1h 20m left)

      final logs = [
        BabyCareLogItem(
          id: 'log-1',
          type: BabyCareLogType.feeding,
          timestamp: lastFeeding,
        ),
      ];

      final status = controller.calculateNextFeeding(logs, 3, now);
      expect(status.isOverdue, isFalse);
      expect(status.isDueNow, isFalse);
      expect(status.statusText.contains('다음 수유까지'), isTrue);
      expect(status.statusText.contains('1시간 20분 전'), isTrue);
    });
  });

  group('Baby Category - Vaccine & Health Checkup Database', () {
    test('kDefaultVaccineDoses contains standard KCDCA vaccines', () {
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('BCG')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('B형간염 1차')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('DTaP 1차')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('MMR 1차')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('수두')), isTrue);
      expect(kDefaultVaccineDoses.length, greaterThanOrEqualTo(20));
    });

    test('kDefaultHealthCheckupDoses contains 1 to 8 checkup stages', () {
      expect(kDefaultHealthCheckupDoses.length, 8);
      expect(kDefaultHealthCheckupDoses.first.stage, 1);
      expect(kDefaultHealthCheckupDoses.last.stage, 8);
    });

    test('BabyProfile JSON serialization works seamlessly', () {
      final profile = BabyProfile(
        name: '튼튼이',
        birthDate: DateTime(2026, 1, 15),
        birthTime: '13:45',
        gender: BabyGender.boy,
        bloodType: 'A',
        feedingIntervalHours: 4,
        careLogs: [
          BabyCareLogItem(
            id: 'c1',
            type: BabyCareLogType.babyFood,
            timestamp: DateTime(2026, 10, 6, 12, 0),
            amount: 100,
            subType: '중기',
          ),
        ],
        growthRecords: [
          GrowthRecord(
            id: 'g1',
            date: DateTime(2026, 10, 6),
            heightCm: 72.5,
            weightKg: 8.9,
            headCircumferenceCm: 44.0,
          ),
        ],
      );

      final json = profile.toJson();
      final restored = BabyProfile.fromJson(json);

      expect(restored.name, '튼튼이');
      expect(restored.gender, BabyGender.boy);
      expect(restored.bloodType, 'A');
      expect(restored.feedingIntervalHours, 4);
      expect(restored.careLogs.length, 1);
      expect(restored.careLogs.first.type, BabyCareLogType.babyFood);
      expect(restored.growthRecords.length, 1);
      expect(restored.growthRecords.first.heightCm, 72.5);
    });
  });
}
