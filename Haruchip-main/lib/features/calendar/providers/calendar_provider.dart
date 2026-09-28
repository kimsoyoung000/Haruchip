import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../plan/providers/plan_provider.dart';
import '../data/calendar_mock_data.dart';
import '../models/calendar_event.dart';

const Object _unset = Object();

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 캘린더 상단 뷰 전환 모드
enum CalendarViewMode { month, week, list }

final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

/// 캘린더 카테고리 필터 (null = '전체')
final calendarCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// 카테고리별 테마 Hex 색상 매핑
String getCategoryColorHex(String categoryKey) {
  return switch (categoryKey) {
    'couple' => '#FF2D55', // Coral Pink
    'solo' => '#9333EA', // Violet/Purple
    'fandom' => '#F59E0B', // Gold / Amber
    'group' => '#10B981', // Emerald Green
    'exam' => '#4F46E5', // Indigo
    'military' => '#556B2F', // Olive / Khaki
    'birthday' => '#EC4899', // Pink
    'baby' => '#F59E0B', // Soft Warm Gold
    'pet' => '#D97706', // Warm Brown
    'plan' => '#007AFF', // Blue (내 일정 / 기본)
    _ => '#007AFF',
  };
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

/// PlanList와 MockCalendarEvents를 결합한 통합 일정 프로바이더
final allCalendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final planItems = ref.watch(planListProvider);
  final filter = ref.watch(calendarCategoryFilterProvider);

  final dynamicEvents = planItems.map((item) {
    return CalendarEvent(
      id: item.id,
      date: item.date,
      title: item.title,
      time: item.deadlineTime != null
          ? '${item.deadlineTime!.hour.toString().padLeft(2, '0')}:${item.deadlineTime!.minute.toString().padLeft(2, '0')}'
          : null,
      source: item.calendarSync.google
          ? 'google'
          : (item.calendarSync.naver ? 'naver' : 'personal'),
      colorHex: getCategoryColorHex(item.categoryKey),
      categoryKey: item.categoryKey,
      isPublic: false,
    );
  }).toList();

  final all = [...mockCalendarEvents, ...dynamicEvents];

  if (filter == null) {
    return all;
  }
  return all.where((e) => e.categoryKey == filter).toList();
});

/// 주어진 날짜의 CalendarEvent 목록.
final eventsForDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
  final target = _dateOnly(date);
  final allEvents = ref.watch(allCalendarEventsProvider);
  return allEvents.where((e) => _dateOnly(e.date) == target).toList();
});

