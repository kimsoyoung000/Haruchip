import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_display_settings_provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_category_filter_sheet.dart';
import '../widgets/calendar_search_sheet.dart';
import '../widgets/month_grid.dart';

/// 칩 캘린더 메인 화면 (미니멀 플랫 리스타일링 + 상단 아이콘화 + Zero-Scroll 뷰포트)
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  String _weekdayKo(DateTime d) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedCategories = ref.watch(calendarSelectedCategoriesProvider);
    final focusedMonth = ref.watch(selectedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider) ?? DateTime.now();
    final events = ref.watch(eventsForDateProvider(selectedDate));
    final allEvents = ref.watch(allCalendarEventsProvider);
    final displaySettings = ref.watch(calendarDisplaySettingsProvider);
    final notifier = ref.read(calendarSelectionProvider.notifier);

    final hasActiveFilter = selectedCategories.isNotEmpty;
    final defaultAddCategoryKey =
        selectedCategories.length == 1 ? selectedCategories.first : 'plan';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 미니멀 플랫 최상단 헤더: [큰 월 숫자] + [월간|주간|목록] + [검색 🔍 | 카테고리 필터 📅]
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 좌측: 감성적인 큰 '월' 숫자 (터치 시 연/월 인라인 휠 피커 호출)
                  InkWell(
                    key: const Key('calendar_year_month_picker_button'),
                    onTap: () => _showYearMonthWheelPicker(
                      context,
                      ref,
                      focusedMonth,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${focusedMonth.month}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${focusedMonth.year}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 우측 정렬 고정: [월간 | 주간 | 목록] 세그먼트 + [검색 🔍] + [카테고리 필터 📅]
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildViewModeTab(context, ref, '월간',
                                  CalendarViewMode.month, viewMode),
                              _buildViewModeTab(context, ref, '주간',
                                  CalendarViewMode.week, viewMode),
                              _buildViewModeTab(context, ref, '목록',
                                  CalendarViewMode.list, viewMode),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // 우측 액션 아이콘 모음: [검색 🔍] + [카테고리 필터 📅] (톱니바퀴 제거)
                  IconButton(
                    key: const Key('calendar_search_button'),
                    onPressed: () => showCalendarSearchSheet(context),
                    icon: const Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: Color(0xFF111827),
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: '일정 검색',
                  ),
                  const SizedBox(width: 2),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        key: const Key('calendar_category_filter_button'),
                        onPressed: () =>
                            showCalendarCategoryFilterSheet(context),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 19,
                          color: Color(0xFF111827),
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        tooltip: '카테고리 필터',
                      ),
                      if (hasActiveFilter)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4B63),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 2. 뷰 모드별 캘린더 본문 (적응형 전체 스크롤: 일정 없을 땐 Zero-Scroll, 많을 땐 전체 페이지 확장)
              Expanded(
                child: viewMode == CalendarViewMode.month
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final bool ultraCompact = constraints.maxHeight < 250;
                          // 일정이 없을 때 하단 날짜 헤더 + '+ 새로운 일정' 버튼이 뷰포트 안에 딱 맞아 Zero-Scroll 유지
                          final double reservedBottomH =
                              ultraCompact ? 42.0 : 84.0;
                          final double calendarHeight =
                              (constraints.maxHeight - reservedBottomH)
                                  .clamp(190.0, 520.0);

                          return ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context)
                                .copyWith(scrollbars: false),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 월간 플랫 캘린더 그리드
                                  SizedBox(
                                    height: calendarHeight,
                                    child: MonthGrid(
                                      focusedMonth: focusedMonth,
                                      selectedDate: selectedDate,
                                      displaySettings: displaySettings,
                                      allEvents: allEvents,
                                      hasEventOnDate: (date) => ref
                                          .watch(eventsForDateProvider(date))
                                          .isNotEmpty,
                                      getEventsOnDate: (date) =>
                                          ref.watch(eventsForDateProvider(date)),
                                      onDateSelected: notifier.selectDate,
                                      onPreviousMonth: notifier.previousMonth,
                                      onNextMonth: notifier.nextMonth,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // 하단 선택일 상세 섹션 (고정 스크롤 박스 제거 → 일정 수만큼 자연 확장)
                                  Text(
                                    '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 (${_weekdayKo(selectedDate)})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (!ultraCompact) ...[
                                    const SizedBox(height: 6),
                                    for (final ev in events)
                                      _buildMinimalEventCard(context, ref, ev),
                                    const SizedBox(height: 4),
                                    // '+ 새로운 일정' 미니멀 버튼
                                    InkWell(
                                      onTap: () => showAddEventBottomSheet(
                                        context,
                                        categoryKey: defaultAddCategoryKey,
                                        initialDate: selectedDate,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              size: 16,
                                              color: Color(0xFF374151),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '새로운 일정',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (events.isNotEmpty)
                                      const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: viewMode == CalendarViewMode.week
                              ? _buildWeekView(
                                  context, ref, selectedDate, allEvents)
                              : _buildListView(context, ref, allEvents),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showYearMonthWheelPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime focusedMonth,
  ) {
    const int minYear = 2020;
    const int maxYear = 2035;
    final years = List<int>.generate(maxYear - minYear + 1, (i) => minYear + i);
    int selectedYear = focusedMonth.year.clamp(minYear, maxYear);
    int selectedMonth = focusedMonth.month;

    final yearCtrl = FixedExtentScrollController(
      initialItem: selectedYear - minYear,
    );
    final monthCtrl = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$selectedYear년 $selectedMonth월',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(calendarSelectionProvider.notifier)
                                  .changeMonth(
                                    DateTime(selectedYear, selectedMonth, 1),
                                  );
                              Navigator.of(sheetCtx).pop();
                            },
                            child: const Text(
                              '확인',
                              style: TextStyle(
                                color: AppColors.chipYellowText,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    SizedBox(
                      height: 210,
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: yearCtrl,
                              itemExtent: 40,
                              selectionOverlay: Container(
                                margin: const EdgeInsets.only(left: 16),
                                decoration: const BoxDecoration(
                                  color: Color(0x66FFE699),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  ),
                                ),
                              ),
                              onSelectedItemChanged: (idx) {
                                setSheetState(() => selectedYear = years[idx]);
                              },
                              children: [
                                for (final y in years)
                                  Center(
                                    child: Text(
                                      '$y년',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: monthCtrl,
                              itemExtent: 40,
                              selectionOverlay: Container(
                                margin: const EdgeInsets.only(right: 16),
                                decoration: const BoxDecoration(
                                  color: Color(0x66FFE699),
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(12),
                                  ),
                                ),
                              ),
                              onSelectedItemChanged: (idx) {
                                setSheetState(() => selectedMonth = idx + 1);
                              },
                              children: [
                                for (int m = 1; m <= 12; m++)
                                  Center(
                                    child: Text(
                                      '$m월',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      yearCtrl.dispose();
      monthCtrl.dispose();
    });
  }

  void _openEditEventModal(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent ev,
  ) {
    final planItems = ref.read(planListProvider);
    final lookupId = ev.planItemId ?? ev.id;
    PlanItem? matched;
    for (final item in planItems) {
      if (item.id == lookupId) {
        matched = item;
        break;
      }
    }

    showAddEventBottomSheet(
      context,
      categoryKey: matched?.categoryKey ?? ev.categoryKey,
      categoryInstanceId: matched?.categoryInstanceId,
      initialDate: matched?.date ?? ev.date,
      initialTitle: matched == null ? ev.title : null,
      existingItem: matched,
    );
  }

  Widget _buildMinimalEventCard(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent ev,
  ) {
    final accent = _parseColor(ev.colorHex);
    final bgColor = ev.fillLabelBackground
        ? resolveCalendarLabelPastelBg(accent)
        : const Color(0xFFF9FAFB);

    String? dateRangeLabel;
    if (ev.isMultiDay) {
      final s = ev.startDateOnly;
      final e = ev.effectiveEndDate;
      dateRangeLabel = '${s.month}.${s.day} ~ ${e.month}.${e.day}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _openEditEventModal(context, ref, ev),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (ev.time != null) ...[
                  SizedBox(
                    width: 42,
                    child: Text(
                      ev.time!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kCalendarLabelDarkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ev.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: kCalendarLabelDarkText,
                        ),
                      ),
                      if (dateRangeLabel != null)
                        Text(
                          dateRangeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    CalendarViewMode mode,
    CalendarViewMode currentMode,
  ) {
    final isSelected = mode == currentMode;
    return GestureDetector(
      onTap: () => ref.read(calendarViewModeProvider.notifier).state = mode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color:
                isSelected ? const Color(0xFF111827) : const Color(0xFF6B7280),
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<CalendarEvent> allEvents,
  ) {
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final weekDays =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        for (final day in weekDays)
          Builder(
            builder: (ctx) {
              final dayEvents = allEvents.where((e) {
                return e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day;
              }).toList();
              final isToday = day.year == DateTime.now().year &&
                  day.month == DateTime.now().month &&
                  day.day == DateTime.now().day;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${day.month}.${day.day} (${_weekdayKo(day)})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: isToday
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded,
                              size: 18, color: Color(0xFF6B7280)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => showAddEventBottomSheet(
                            context,
                            categoryKey: 'plan',
                            initialDate: day,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (dayEvents.isEmpty)
                      const Text('일정 없음',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF)))
                    else
                      for (final ev in dayEvents)
                        _buildMinimalEventCard(context, ref, ev),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<CalendarEvent> allEvents,
  ) {
    if (allEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('등록된 일정이 없습니다.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        ),
      );
    }

    final sorted = [...allEvents]..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '전체 일정 (${sorted.length}개)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              InkWell(
                onTap: () => showAddEventBottomSheet(
                  context,
                  categoryKey: 'plan',
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: Color(0xFF374151)),
                    SizedBox(width: 2),
                    Text('일정 추가',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 12, color: Color(0xFFF1F5F9)),
        for (final ev in sorted)
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _parseColor(ev.colorHex),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${ev.date.year}.${ev.date.month}.${ev.date.day} (${_weekdayKo(ev.date)})${ev.time != null ? ' · ${ev.time}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
