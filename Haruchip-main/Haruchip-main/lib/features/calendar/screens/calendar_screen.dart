import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  // 좌측: 감성적인 큰 '월' 숫자 (좌우 화살표로도 이동 가능)
                  Row(
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
                    ],
                  ),
                  const SizedBox(width: 8),

                  // 중앙/좌측 서브: 미니멀 [월간 | 주간 | 목록] 세그먼트 텍스트 탭
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
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

              // 2. 뷰 모드별 캘린더 본문 (확장된 뷰포트 높이 100% 활용 Zero-Scroll)
              Expanded(
                child: viewMode == CalendarViewMode.month
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final bool ultraCompact = constraints.maxHeight < 250;
                          final double detailPanelMaxH =
                              (constraints.maxHeight * 0.28).clamp(74.0, 185.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 월간 플랫 캘린더 그리드
                              Expanded(
                                child: MonthGrid(
                                  focusedMonth: focusedMonth,
                                  selectedDate: selectedDate,
                                  displaySettings: displaySettings,
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

                              // 하단 선택일 상세 섹션 (레퍼런스 스타일: 날짜 타이틀 + 세로 컬러 바 일정 + '+ 새로운 일정')
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: ultraCompact ? 42 : detailPanelMaxH,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                      if (events.isNotEmpty)
                                        Flexible(
                                          child: SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            child: Column(
                                              children: [
                                                for (final ev in events)
                                                  _buildMinimalEventCard(ev),
                                              ],
                                            ),
                                          ),
                                        ),
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
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: viewMode == CalendarViewMode.week
                            ? _buildWeekView(
                                context, ref, selectedDate, allEvents)
                            : _buildListView(context, ref, allEvents),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalEventCard(CalendarEvent ev) {
    final accent = _parseColor(ev.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
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
                  color: Color(0xFF374151),
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
            child: Text(
              ev.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
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
                      for (final ev in dayEvents) _buildMinimalEventCard(ev),
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
