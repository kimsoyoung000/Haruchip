import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:haruchip/features/categories/controllers/baby_category_controller.dart';
import 'package:haruchip/features/categories/controllers/birthday_category_controller.dart';
import 'package:haruchip/features/categories/controllers/couple_category_controller.dart';
import 'package:haruchip/features/categories/controllers/exam_category_controller.dart';
import 'package:haruchip/features/categories/controllers/military_category_controller.dart';
import 'package:haruchip/features/categories/controllers/pet_category_controller.dart';
import 'package:haruchip/features/categories/controllers/plan_category_controller.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/models/dday_model.dart';
import 'package:haruchip/features/categories/models/exam_timeline.dart';

void main() {
  group('Data Models Test', () {
    test('CategoryModel JSON serialization and backward compatibility', () {
      final model = CategoryModel(
        id: 'cat-1',
        categoryKey: 'exam',
        name: '정보처리기사',
        icon: '📚',
        createdAt: DateTime(2026, 1, 1),
        typography: const TypographyConfig(fontFamily: 'Pretendard', textColor: '#FF0000', fontSize: 16),
        background: const BackgroundConfig(
          type: BackgroundType.singleColor,
          colorValues: ['#4A90E2'],
        ),
      );

      expect(model.emoji, equals('📚'));
      expect(model.colorHex, equals('#4A90E2'));

      final json = model.toJson();
      final restored = CategoryModel.fromJson(json);

      expect(restored.id, equals('cat-1'));
      expect(restored.name, equals('정보처리기사'));
      expect(restored.typography.textColor, equals('#FF0000'));
    });

    test('DDayModel JSON serialization', () {
      final dday = DDayModel(
        id: 'dday-1',
        categoryId: 'cat-1',
        title: '필기 시험',
        targetDate: DateTime(2026, 10, 15),
        displayType: DDayDisplayType.dday,
        repeatType: DDayRepeatType.none,
        isPredictiveListed: true,
      );

      final json = dday.toJson();
      final restored = DDayModel.fromJson(json);

      expect(restored.id, equals('dday-1'));
      expect(restored.title, equals('필기 시험'));
      expect(restored.isPredictiveListed, isTrue);
    });
  });

  group('CoupleCategoryController Test', () {
    const controller = CoupleCategoryController();
    final relativeTo = DateTime(2026, 9, 23);

    test('Calculates pure days together subtracting multiple breakups', () {
      final startDate = DateTime(2026, 1, 1); // 265일 경과
      final breakups = [
        BreakupPeriod(
          breakDate: DateTime(2026, 3, 1),
          reunionDate: DateTime(2026, 3, 11), // 10일 공백
        ),
        BreakupPeriod(
          breakDate: DateTime(2026, 6, 1),
          reunionDate: DateTime(2026, 6, 21), // 20일 공백
        ),
      ];

      final pureDays = controller.calculatePureDays(
        startDate: startDate,
        breakups: breakups,
        relativeTo: relativeTo,
      );

      // 총 265일 - 30일 공백 = 235일
      expect(pureDays, equals(235));
    });

    test('Generates predictive anniversaries (100~1000 days & 1~50 years)', () {
      final startDate = DateTime(2026, 1, 1);
      final annivs = controller.generatePredictiveAnniversaries(
        categoryId: 'couple-1',
        startDate: startDate,
        relativeTo: relativeTo,
      );

      expect(annivs, isNotEmpty);
      expect(annivs.first.title, equals('300일'));
      expect(annivs.any((a) => a.title == '1주년'), isTrue);
    });
  });

  group('BirthdayCategoryController Test', () {
    const controller = BirthdayCategoryController();
    final relativeTo = DateTime(2026, 9, 23);

    test('Calculates next birthday D-Day correctly', () {
      final birthDate = DateTime(1995, 10, 5); // 10월 5일 생일 (relativeTo=9/23)
      final label = controller.calculateBirthdayDDayLabel(birthDate, relativeTo);

      // 9월 23일부터 10월 5일까지 D-12
      expect(label, equals('D-12'));
    });
  });

  group('MilitaryCategoryController Test', () {
    const controller = MilitaryCategoryController();
    final relativeTo = DateTime(2026, 9, 23);

    test('Calculates service progress percentage and rank D-Days', () {
      final enlistmentDate = DateTime(2026, 1, 1);
      final dischargeDate = DateTime(2027, 7, 1);

      final progress = controller.calculateProgressPercentage(
        enlistmentDate: enlistmentDate,
        dischargeDate: dischargeDate,
        relativeTo: relativeTo,
      );

      expect(progress, greaterThan(0.0));
      expect(progress, lessThan(100.0));

      final ranks = controller.calculateRankDDays(
        enlistmentDate: enlistmentDate,
        relativeTo: relativeTo,
      );

      expect(ranks.length, equals(4)); // 이병, 일병, 상병, 병장
    });
  });

  group('ExamCategoryController Test', () {
    const controller = ExamCategoryController();
    final relativeTo = DateTime(2026, 9, 23);

    test('Sorts events by D-Day urgency (imminent events first)', () {
      final events = [
        ExamEventItem(
          id: 'e-1',
          title: '최종합격',
          date: DateTime(2026, 12, 1),
          stage: ExamStage.finalResult,
          eventType: ExamEventType.result,
          flowOrder: 5,
          subjectColorHex: '#4A90E2',
        ),
        ExamEventItem(
          id: 'e-2',
          title: '필기시험',
          date: DateTime(2026, 10, 1),
          stage: ExamStage.writtenTest,
          eventType: ExamEventType.exam,
          flowOrder: 2,
          subjectColorHex: '#4A90E2',
        ),
      ];

      final sorted = controller.sortEventsByUrgency(events, relativeTo);
      expect(sorted.first.id, equals('e-2')); // 10월 1일이 더 임박
    });
  });

  group('BabyCategoryController Test', () {
    const controller = BabyCategoryController();
    final relativeTo = DateTime(2026, 9, 23);

    test('Formats baby age as N일째 (X개월 Y일째)', () {
      final birthDate = DateTime(2026, 5, 20); // 약 4개월 전
      final formatted = controller.formatBabyAgeDetailed(birthDate, relativeTo);

      expect(formatted, contains('126일째'));
      expect(formatted, contains('4개월 3일째'));
    });
  });

  group('Pet & Plan Category Controllers Test', () {
    test('PetCategoryController provides species icons', () {
      const controller = PetCategoryController();
      final icons = controller.getAvailableIcons();

      expect(icons, isNotEmpty);
      expect(icons.any((i) => i.icon == '🐶'), isTrue);
    });

    test('PlanCategoryController calculates D-Time label', () {
      const controller = PlanCategoryController();
      final relativeTo = DateTime(2026, 9, 23, 10, 0);

      final label = controller.calculateDTimeLabel(
        targetDate: DateTime(2026, 9, 23),
        deadlineTime: const TimeOfDay(hour: 15, minute: 30),
        relativeTo: relativeTo,
      );

      expect(label, contains('5시간 30분 남음'));
    });
  });
}
