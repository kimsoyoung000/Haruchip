import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/providers/calendar_provider.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';

void main() {
  group('calendarSelectionProvider', () {
    test('초기 상태는 오늘이 focusedMonth/selectedDate로 잡혀 있다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final focused = container.read(selectedMonthProvider);
      final selected = container.read(selectedDateProvider);

      expect(focused.year, now.year);
      expect(focused.month, now.month);
      expect(focused.day, 1);
      expect(selected, isNotNull);
      expect(selected!.day, now.day);
    });

    test('selectDate 호출 시 선택 날짜가 바뀐다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(calendarSelectionProvider.notifier);

      notifier.selectDate(DateTime(2026, 8, 20));

      expect(container.read(selectedDateProvider), DateTime(2026, 8, 20));
    });

    test('nextMonth/previousMonth 호출 시 focusedMonth가 이동하고 selectedDate는 초기화된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(calendarSelectionProvider.notifier);
      notifier.changeMonth(DateTime(2026, 8, 1));

      notifier.nextMonth();
      expect(container.read(selectedMonthProvider), DateTime(2026, 9, 1));
      expect(container.read(selectedDateProvider), isNull);

      notifier.previousMonth();
      expect(container.read(selectedMonthProvider), DateTime(2026, 8, 1));
    });

    test('goToToday 호출 시 현재 년월 및 오늘 날짜로 선택이 이동한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(calendarSelectionProvider.notifier);

      notifier.changeMonth(DateTime(2020, 1, 1));
      notifier.selectDate(DateTime(2020, 1, 15));

      notifier.goToToday();
      final now = DateTime.now();
      expect(container.read(selectedMonthProvider).year, now.year);
      expect(container.read(selectedMonthProvider).month, now.month);
      expect(container.read(selectedDateProvider)?.day, now.day);
    });
  });

  group('Calendar View & Category Filters', () {
    test('calendarViewModeProvider 기본값은 month이고 변경 가능하다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(calendarViewModeProvider), CalendarViewMode.month);
      container.read(calendarViewModeProvider.notifier).state = CalendarViewMode.week;
      expect(container.read(calendarViewModeProvider), CalendarViewMode.week);
      container.read(calendarViewModeProvider.notifier).state = CalendarViewMode.list;
      expect(container.read(calendarViewModeProvider), CalendarViewMode.list);
    });

    test('calendarCategoryFilterProvider 기본값은 null(전체)이며 특정 카테고리로 필터링된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(calendarCategoryFilterProvider), isNull);

      // Add a couple item and an exam item
      final planNotifier = container.read(planListProvider.notifier);
      planNotifier.addItem(PlanItem(
        id: 'couple-event',
        title: '커플 데이트',
        date: DateTime(2026, 9, 15),
        categoryKey: 'couple',
      ));
      planNotifier.addItem(PlanItem(
        id: 'exam-event',
        title: '토익 시험',
        date: DateTime(2026, 9, 20),
        categoryKey: 'exam',
      ));

      // Filter null (all): contains both
      final allEvents = container.read(allCalendarEventsProvider);
      expect(allEvents.any((e) => e.title == '커플 데이트'), isTrue);
      expect(allEvents.any((e) => e.title == '토익 시험'), isTrue);

      // Filter couple: only couple
      container.read(calendarCategoryFilterProvider.notifier).state = 'couple';
      final coupleEvents = container.read(allCalendarEventsProvider);
      expect(coupleEvents.any((e) => e.title == '커플 데이트'), isTrue);
      expect(coupleEvents.any((e) => e.title == '토익 시험'), isFalse);
    });
  });

  group('eventsForDateProvider', () {
    test('mock 데이터 중 해당 날짜의 이벤트만 반환한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events =
          container.read(eventsForDateProvider(DateTime(2026, 8, 14)));

      expect(events, hasLength(1));
      expect(events.single.title, '민수와 데이트');
    });

    test('일정이 없는 날짜는 빈 리스트를 반환한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events =
          container.read(eventsForDateProvider(DateTime(2099, 1, 1)));

      expect(events, isEmpty);
    });
  });
}
