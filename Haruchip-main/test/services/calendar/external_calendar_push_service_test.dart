import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/services/calendar/external_calendar_push_service.dart';

void main() {
  group('ExternalCalendarPushService', () {
    final service = ExternalCalendarPushService.instance;

    test('Google and Naver calendar targets are initialized with default options', () {
      final googleTargets = service.googleCalendars;
      expect(googleTargets, isNotEmpty);
      expect(googleTargets.any((t) => t.isDefault), isTrue);

      final naverTargets = service.naverCalendars;
      expect(naverTargets, isNotEmpty);
      expect(naverTargets.any((t) => t.isDefault), isTrue);
    });

    test('Google Color mapping returns valid color ID string (1~11)', () {
      final coupleColor = service.mapCategoryToGoogleColorId('couple');
      expect(coupleColor, '4'); // Flamingo/Pink

      final examColor = service.mapCategoryToGoogleColorId('exam');
      expect(examColor, '9'); // Blueberry/Indigo

      final fallbackColor = service.mapCategoryToGoogleColorId('unknown_key');
      expect(fallbackColor, '1'); // Lavender
    });

    test('Pushing PlanItem with google: true and naver: true returns push results', () async {
      final item = PlanItem(
        id: 'test-push-1',
        title: '커플 기념일 데이트',
        date: DateTime(2026, 10, 1),
        categoryKey: 'couple',
        calendarSync: const CalendarSyncFlags(google: true, naver: true),
      );

      final results = await service.pushPlanItem(
        item: item,
        googleCalendarId: 'primary',
        naverCalendarId: 'default',
      );

      expect(results, hasLength(2));
      expect(results.every((r) => r.isSuccess), isTrue);
      expect(results.any((r) => r.targetService == 'google'), isTrue);
      expect(results.any((r) => r.targetService == 'naver'), isTrue);
    });

    test('Pushing PlanItem with external sync disabled returns empty results', () async {
      final item = PlanItem(
        id: 'test-push-2',
        title: '개인 공부',
        date: DateTime(2026, 10, 2),
        categoryKey: 'exam',
        calendarSync: const CalendarSyncFlags(google: false, naver: false),
      );

      final results = await service.pushPlanItem(
        item: item,
      );

      expect(results, isEmpty);
    });
  });
}
