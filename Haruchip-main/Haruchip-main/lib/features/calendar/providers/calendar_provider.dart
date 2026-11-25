import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_registry.dart';
import '../../categories/data/category_types.dart' as cat_types;
import '../../categories/providers/category_provider.dart';
import '../../hobby/providers/hobby_provider.dart';
import '../../plan/providers/plan_provider.dart';
import '../../travel/providers/travel_provider.dart';
import '../data/calendar_mock_data.dart';
import '../models/calendar_event.dart';

const Object _unset = Object();

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 캘린더 상단 뷰 전환 모드
enum CalendarViewMode { month, week, list }

final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

/// 캘린더 카테고리 단일 필터 (하위 호환용, null = '전체')
final calendarCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// 캘린더 카테고리 다중 선택 필터 (빈 Set = '전체' 선택, 비어있지 않으면 선택된 카테고리들만 동시 노출)
final calendarSelectedCategoriesProvider =
    StateProvider<Set<String>>((ref) => const <String>{});

/// 카테고리별 테마 Hex 색상 매핑 (파스텔 톤 통일)
String getCategoryColorHex(String categoryKey) {
  return cat_types.getCategoryColorHex(categoryKey);
}

/// 캘린더 화면에서 사용자가 보고 있는 연/월과 선택한 날짜.
class CalendarSelectionState {
  const CalendarSelectionState({
    required this.focusedMonth,
    this.selectedDate,
  });

  /// 현재 보고 있는 달의 1일 (연/월 내비게이션용).
  final DateTime focusedMonth;

  /// 사용자가 탭한 날짜. 아직 선택 안 했으면 null.
  final DateTime? selectedDate;

  CalendarSelectionState copyWith({
    DateTime? focusedMonth,
    Object? selectedDate = _unset,
  }) {
    return CalendarSelectionState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: identical(selectedDate, _unset)
          ? this.selectedDate
          : selectedDate as DateTime?,
    );
  }
}

class CalendarSelectionNotifier extends Notifier<CalendarSelectionState> {
  @override
  CalendarSelectionState build() {
    final today = _dateOnly(DateTime.now());
    return CalendarSelectionState(
      focusedMonth: DateTime(today.year, today.month, 1),
      selectedDate: today,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: _dateOnly(date));
  }

  /// 검색 결과 등 특정 날짜의 월과 일자로 즉시 포커스 이동
  void focusDate(DateTime date) {
    final target = _dateOnly(date);
    state = CalendarSelectionState(
      focusedMonth: DateTime(target.year, target.month, 1),
      selectedDate: target,
    );
  }

  void changeMonth(DateTime month) {
    state = state.copyWith(
      focusedMonth: DateTime(month.year, month.month, 1),
      selectedDate: null,
    );
  }

  void goToToday() {
    final today = _dateOnly(DateTime.now());
    state = state.copyWith(
      focusedMonth: DateTime(today.year, today.month, 1),
      selectedDate: today,
    );
  }

  void nextMonth() {
    final m = state.focusedMonth;
    changeMonth(DateTime(m.year, m.month + 1, 1));
  }

  void previousMonth() {
    final m = state.focusedMonth;
    changeMonth(DateTime(m.year, m.month - 1, 1));
  }
}

final calendarSelectionProvider =
    NotifierProvider<CalendarSelectionNotifier, CalendarSelectionState>(
  CalendarSelectionNotifier.new,
);

final selectedMonthProvider = Provider<DateTime>(
  (ref) => ref.watch(calendarSelectionProvider).focusedMonth,
);

final selectedDateProvider = Provider<DateTime?>(
  (ref) => ref.watch(calendarSelectionProvider).selectedDate,
);

/// 필터 적용 전 전체 캘린더 일정 프로바이더 (일정 검색 엔진에서 전체 과거/미래 일정 검색에 사용)
final allUnfilteredCalendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final planItems = ref.watch(planListProvider);
  final categories = ref.watch(categoryListProvider);
  final travelTrips = ref.watch(travelTripListProvider);
  final interPlans = ref.watch(interTripPlanListProvider);
  final hobbyList = ref.watch(hobbyListProvider);
  final hobbySchedules = ref.watch(hobbyScheduleListProvider);

  String resolveCategoryColor(String categoryKey, String fallbackHex) {
    final matches = categories.where(
      (c) => c.categoryKey == categoryKey || c.id == categoryKey,
    );
    return matches.isNotEmpty ? matches.first.colorHex : fallbackHex;
  }

  bool resolveCategoryFillBg(String categoryKey) {
    final matches = categories.where(
      (c) => c.categoryKey == categoryKey || c.id == categoryKey,
    );
    return matches.isNotEmpty ? matches.first.fillCalendarLabelBg : false;
  }

  String safeInlineEmoji(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith(HaruChipIconRegistry.filePrefix) ||
        HaruChipIconRegistry.isSafeRegistryKey(trimmed) ||
        HaruChipIconRegistry.isAssetKeyAttempt(trimmed)) {
      return '';
    }
    return '$trimmed ';
  }

  final dynamicEvents = planItems.map((item) {
    final colorHex = resolveCategoryColor(
      item.categoryKey,
      getCategoryColorHex(item.categoryKey),
    );
    final fillBg = resolveCategoryFillBg(item.categoryKey);

    return CalendarEvent(
      id: item.id,
      date: item.date,
      endDate: item.endDate,
      title: item.title,
      time: item.deadlineTime != null && !item.isAllDay
          ? '${item.deadlineTime!.hour.toString().padLeft(2, '0')}:${item.deadlineTime!.minute.toString().padLeft(2, '0')}'
          : null,
      source: item.calendarSync.google
          ? 'google'
          : (item.calendarSync.naver ? 'naver' : 'personal'),
      colorHex: colorHex,
      categoryKey: item.categoryKey,
      isPublic: false,
      fillLabelBackground: fillBg,
      planItemId: item.id,
    );
  }).toList();

  final travelColorHex = resolveCategoryColor('travel', '#0284C7');
  final travelFillBg = resolveCategoryFillBg('travel');
  final travelEvents = <CalendarEvent>[];
  for (final trip in travelTrips) {
    final s = _dateOnly(trip.startDate);
    final e = _dateOnly(trip.endDate);
    final hasCustomTravelCat =
        categories.any((c) => c.categoryKey == 'travel');
    final tripColor = hasCustomTravelCat ? travelColorHex : trip.themeColorHex;
    final prefix = safeInlineEmoji(trip.emoji);
    travelEvents.add(CalendarEvent(
      id: 'cal-trip-${trip.id}',
      date: s,
      endDate: e,
      title: '$prefix${trip.destination}',
      time: null,
      source: 'personal',
      colorHex: tripColor,
      categoryKey: 'travel',
      isPublic: false,
      fillLabelBackground: travelFillBg || e.isAfter(s),
    ));
  }

  for (final plan in interPlans) {
    travelEvents.add(CalendarEvent(
      id: 'cal-inter-${plan.id}',
      date: plan.date,
      title: '📍 ${plan.title}',
      time: plan.time,
      source: 'personal',
      colorHex: travelColorHex,
      categoryKey: 'travel',
      isPublic: false,
      fillLabelBackground: travelFillBg,
    ));
  }

  final hobbyColorHex = resolveCategoryColor('hobby', '#354235');
  final hobbyFillBg = resolveCategoryFillBg('hobby');
  final hobbyEvents = <CalendarEvent>[];
  for (final sched in hobbySchedules) {
    final matching = hobbyList.where((h) => h.id == sched.hobbyId);
    final hobby = matching.isNotEmpty ? matching.first : null;
    final prefix = safeInlineEmoji(hobby?.icon ?? '🎨');
    final timeStr = sched.hasTime
        ? '${sched.date.hour.toString().padLeft(2, '0')}:${sched.date.minute.toString().padLeft(2, '0')}'
        : null;

    hobbyEvents.add(CalendarEvent(
      id: 'cal-hobby-${sched.id}',
      date: sched.date,
      title: '$prefix${sched.title}',
      time: timeStr,
      source: 'personal',
      colorHex: hobbyColorHex,
      categoryKey: 'hobby',
      isPublic: false,
      fillLabelBackground: hobbyFillBg,
    ));
  }

  final syncedMockEvents = mockCalendarEvents.map((ev) {
    final resolvedHex = resolveCategoryColor(ev.categoryKey, ev.colorHex);
    final fillBg = resolveCategoryFillBg(ev.categoryKey);
    return CalendarEvent(
      id: ev.id,
      date: ev.date,
      endDate: ev.endDate,
      title: ev.title,
      time: ev.time,
      source: ev.source,
      colorHex: resolvedHex,
      categoryKey: ev.categoryKey,
      isPublic: ev.isPublic,
      fillLabelBackground: fillBg,
    );
  }).toList();

  return [...syncedMockEvents, ...dynamicEvents, ...travelEvents, ...hobbyEvents];
});

/// PlanList, MockCalendarEvents, 여행(Travel) 및 사이 계획(Inter-Trip Plans)을 결합한 필터 적용 일정 프로바이더
final allCalendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final all = ref.watch(allUnfilteredCalendarEventsProvider);
  final legacyFilter = ref.watch(calendarCategoryFilterProvider);
  final selectedCategories = ref.watch(calendarSelectedCategoriesProvider);

  if (selectedCategories.isNotEmpty) {
    return all.where((e) => selectedCategories.contains(e.categoryKey)).toList();
  }
  if (legacyFilter != null) {
    return all.where((e) => e.categoryKey == legacyFilter).toList();
  }
  return all;
});

/// 주어진 날짜의 CalendarEvent 목록 (다일 연속 일정의 시작~종료 범위 포함).
final eventsForDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
  final target = _dateOnly(date);
  final allEvents = ref.watch(allCalendarEventsProvider);
  return allEvents.where((e) {
    final start = e.startDateOnly;
    final end = e.effectiveEndDate;
    return !target.isBefore(start) && !target.isAfter(end);
  }).toList();
});

