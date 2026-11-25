import 'package:flutter/material.dart';

import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

import '../models/calendar_display_settings.dart';
import '../models/calendar_event.dart';

/// 한국 주요 양력 공휴일 맵 (MM-DD)
const Map<String, String> kKoreanHolidays = {
  '01-01': '신정',
  '03-01': '삼일절',
  '05-05': '어린이날',
  '06-06': '현충일',
  '08-15': '광복절',
  '10-03': '개천절',
  '10-09': '한글날',
  '12-25': '성탄절',
};

/// 주(Week) 단위 연속 이벤트 바 배치 정보
class _WeekEventSegment {
  const _WeekEventSegment({
    required this.event,
    required this.startCol,
    required this.endCol,
    required this.lane,
    required this.continuesFromPrevWeek,
    required this.continuesToNextWeek,
  });

  final CalendarEvent event;
  final int startCol;
  final int endCol;
  final int lane;
  final bool continuesFromPrevWeek;
  final bool continuesToNextWeek;
}

/// 미니멀 플랫 월간 캘린더 그리드
///
/// - 선택일: 하루칩 시그니처 웜 파스텔 옐로우(#FFE699) + 딥 브라운(#3A2E1A) 텍스트
/// - 오늘(Today): 얇고 부드러운 칩 골드(#F2B84B) 아웃라인 인디케이터
/// - 다일(Multi-day) 일정: 주(Week) 행을 가로로 관통하는 단일 연속 라벨 바로 렌더링
/// - 카테고리별 라벨 배경 채우기 토글:
///   - OFF(투명형): 좌측 세로 컬러 바 + 투명 배경 + 다크 텍스트(#2C2C2E)
///   - ON(배경 채움형): 카테고리 색상 기반 자동 파스텔 배경 + 다크 텍스트(#2C2C2E)
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasEventOnDate,
    this.getEventsOnDate,
    this.allEvents,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.startOnMonday,
    this.displaySettings = const CalendarDisplaySettings(),
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final bool Function(DateTime date) hasEventOnDate;
  final List<CalendarEvent> Function(DateTime date)? getEventsOnDate;
  final List<CalendarEvent>? allEvents;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool? startOnMonday;
  final CalendarDisplaySettings displaySettings;

  // 하루칩 시그니처 웜 파스텔 옐로우 선택 하이라이트 & 칩 골드 오늘 아웃라인
  static const Color kSelectedCellBg = Color(0xFFFFE699);
  static const Color kSelectedText = Color(0xFF3A2E1A);
  static const Color kTodayOutline = Color(0xFFF2B84B);
  static const Color kTodayText = Color(0xFF3A2E1A);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String? _getHolidayName(DateTime date) {
    final key =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return kKoreanHolidays[key];
  }

  String _approxLunarLabel(DateTime date) {
    final approx = date.subtract(const Duration(days: 29));
    return '${approx.month}.${approx.day}';
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  /// 특정 주(7일)에 걸치는 고유 일정 목록을 수집하고 레인(행)에 겹치지 않게 배치한다.
  ({List<_WeekEventSegment> segments, List<int> totalCountPerCol})
      _layoutWeekEvents(DateTime weekStart, int maxLanes) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final seenIds = <String>{};
    final weekEvents = <CalendarEvent>[];

    if (allEvents != null) {
      for (final ev in allEvents!) {
        final s = ev.startDateOnly;
        final e = ev.effectiveEndDate;
        if (!e.isBefore(weekStart) && !s.isAfter(weekEnd)) {
          if (seenIds.add(ev.id)) {
            weekEvents.add(ev);
          }
        }
      }
    } else if (getEventsOnDate != null) {
      for (int c = 0; c < 7; c++) {
        final day = weekStart.add(Duration(days: c));
        for (final ev in getEventsOnDate!(day)) {
          if (seenIds.add(ev.id)) {
            weekEvents.add(ev);
          }
        }
      }
    }

    // 다일 일정 우선(긴 기간 우선) → 시작일 빠른 순 → 시간 순 정렬
    weekEvents.sort((a, b) {
      final spanA = a.effectiveEndDate.difference(a.startDateOnly).inDays;
      final spanB = b.effectiveEndDate.difference(b.startDateOnly).inDays;
      if (spanA != spanB) return spanB.compareTo(spanA);
      final cmpStart = a.startDateOnly.compareTo(b.startDateOnly);
      if (cmpStart != 0) return cmpStart;
      return (a.time ?? '').compareTo(b.time ?? '');
    });

    final totalCountPerCol = List<int>.filled(7, 0);
    final occupied = <List<bool>>[];
    final segments = <_WeekEventSegment>[];

    for (final ev in weekEvents) {
      final evStart = ev.startDateOnly;
      final evEnd = ev.effectiveEndDate;
      final clampedStart = evStart.isBefore(weekStart) ? weekStart : evStart;
      final clampedEnd = evEnd.isAfter(weekEnd) ? weekEnd : evEnd;
      final startCol = clampedStart.difference(weekStart).inDays.clamp(0, 6);
      final endCol = clampedEnd.difference(weekStart).inDays.clamp(0, 6);

      for (int c = startCol; c <= endCol; c++) {
        totalCountPerCol[c]++;
      }

      int assignedLane = -1;
      for (int lane = 0; lane < occupied.length; lane++) {
        bool free = true;
        for (int c = startCol; c <= endCol; c++) {
          if (occupied[lane][c]) {
            free = false;
            break;
          }
        }
        if (free) {
          assignedLane = lane;
          break;
        }
      }

      if (assignedLane == -1) {
        assignedLane = occupied.length;
        occupied.add(List<bool>.filled(7, false));
      }
      for (int c = startCol; c <= endCol; c++) {
        occupied[assignedLane][c] = true;
      }

      if (assignedLane < maxLanes) {
        segments.add(_WeekEventSegment(
          event: ev,
          startCol: startCol,
          endCol: endCol,
          lane: assignedLane,
          continuesFromPrevWeek: evStart.isBefore(weekStart),
          continuesToNextWeek: evEnd.isAfter(weekEnd),
        ));
      }
    }

    return (segments: segments, totalCountPerCol: totalCountPerCol);
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final settings = displaySettings;
    final useMondayStart = startOnMonday ?? settings.startOnMonday;

    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final leadingBlanks = useMondayStart
        ? (firstOfMonth.weekday - 1) % 7
        : firstOfMonth.weekday % 7;

    final totalSlots = leadingBlanks + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();
    final gridStartDate = firstOfMonth.subtract(Duration(days: leadingBlanks));

    final weekLabels = useMondayStart
        ? const ['월', '화', '수', '목', '금', '토', '일']
        : const ['일', '월', '화', '수', '목', '금', '토'];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -220) {
          onNextMonth();
        } else if (velocity > 220) {
          onPreviousMonth();
        }
      },
      child: Column(
        children: [
          // 요일 헤더 (선택된 요일은 딥 브라운 강조)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (int i = 0; i < weekLabels.length; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        weekLabels[i],
                        style: TextStyle(
                          color: (useMondayStart ? i == 6 : i == 0)
                              ? const Color(0xFF9CA3AF)
                              : (i == (useMondayStart ? 5 : 6)
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF1F2937)),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 주(Week) 단위 행 렌더링 — 다일 연속 일정 가로 관통 바 지원
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double rowSpacing = 2.0;
                final double availableHeight = constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : rowCount * 66.0;
                final double rawRowHeight =
                    (availableHeight - rowSpacing * (rowCount - 1)) / rowCount;
                final double rowHeight =
                    rawRowHeight > 22.0 ? rawRowHeight : 22.0;
                final double colWidth = constraints.maxWidth / 7;

                final double baseDayFont = rowHeight < 38
                    ? 10.5
                    : (rowHeight < 54 ? 12.0 : 13.0);
                final double dayFontSize =
                    (baseDayFont * settings.fontSize.scale).clamp(9.5, 15.0);
                final double baseChipFont = rowHeight < 48 ? 9.5 : 10.5;
                final double chipFontSize =
                    (baseChipFont * settings.fontSize.scale).clamp(8.5, 12.0);

                final scaler = MediaQuery.textScalerOf(context);
                final double dayHeaderH = scaler.scale(dayFontSize) + 10.0;
                final double barH = scaler.scale(chipFontSize) + 4.5;
                final double plusH = scaler.scale(8.0) + 2.0;
                final double eventAreaH =
                    (rowHeight - dayHeaderH - 2.0).clamp(0.0, rowHeight);
                final int maxLanes =
                    eventAreaH >= barH ? (eventAreaH / barH).floor().clamp(0, 3) : 0;

                return Column(
                  children: [
                    for (int weekIdx = 0; weekIdx < rowCount; weekIdx++) ...[
                      if (weekIdx > 0) const SizedBox(height: rowSpacing),
                      SizedBox(
                        height: rowHeight,
                        child: _buildWeekRow(
                          context: context,
                          weekStart:
                              gridStartDate.add(Duration(days: weekIdx * 7)),
                          firstOfMonth: firstOfMonth,
                          today: today,
                          colWidth: colWidth,
                          rowHeight: rowHeight,
                          dayHeaderH: dayHeaderH,
                          barH: barH,
                          plusH: plusH,
                          maxLanes: maxLanes,
                          dayFontSize: dayFontSize,
                          chipFontSize: chipFontSize,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow({
    required BuildContext context,
    required DateTime weekStart,
    required DateTime firstOfMonth,
    required DateTime today,
    required double colWidth,
    required double rowHeight,
    required double dayHeaderH,
    required double barH,
    required double plusH,
    required int maxLanes,
    required double dayFontSize,
    required double chipFontSize,
  }) {
    final settings = displaySettings;
    final layout = _layoutWeekEvents(weekStart, maxLanes);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // 1. 배경 날짜 셀 레이어 (선택: 웜 파스텔 옐로우 #FFE699, 오늘: 칩 골드 아웃라인 #F2B84B)
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int col = 0; col < 7; col++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final date = weekStart.add(Duration(days: col));
                    final isCurrentMonth =
                        date.month == focusedMonth.month &&
                            date.year == focusedMonth.year;
                    final isToday = _isSameDay(date, today);
                    final isSelected = _isSameDay(date, selectedDate);
                    final holidayName =
                        isCurrentMonth ? _getHolidayName(date) : null;
                    final isSunday = date.weekday == DateTime.sunday;
                    final isSaturday = date.weekday == DateTime.saturday;

                    Color dayTextColor;
                    if (isSelected) {
                      dayTextColor = kSelectedText;
                    } else if (!isCurrentMonth) {
                      dayTextColor = const Color(0xFFC7C7CC);
                    } else if (isToday) {
                      dayTextColor = kTodayText;
                    } else if (holidayName != null || isSunday) {
                      dayTextColor = const Color(0xFFE11D48);
                    } else if (isSaturday) {
                      dayTextColor = const Color(0xFF6B7280);
                    } else {
                      dayTextColor = const Color(0xFF111827);
                    }

                    final hasHiddenDots =
                        maxLanes == 0 && layout.totalCountPerCol[col] > 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: InkWell(
                        onTap: () {
                          if (!isCurrentMonth) {
                            if (date.isBefore(firstOfMonth)) {
                              onPreviousMonth();
                            } else {
                              onNextMonth();
                            }
                          }
                          onDateSelected(date);
                        },
                        onDoubleTap: () {
                          onDateSelected(date);
                          showAddEventBottomSheet(
                            context,
                            categoryKey: 'plan',
                            initialDate: date,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kSelectedCellBg
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: (isToday && !isSelected)
                                ? Border.all(
                                    color: kTodayOutline,
                                    width: 1.4,
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontWeight: (isToday || isSelected)
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: dayTextColor,
                                          fontSize: dayFontSize,
                                          height: 1.1,
                                        ),
                                      ),
                                      if (settings.showLunar &&
                                          isCurrentMonth &&
                                          rowHeight >= 46) ...[
                                        const SizedBox(width: 2),
                                        Text(
                                          _approxLunarLabel(date),
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: isSelected
                                                ? kSelectedText.withValues(
                                                    alpha: 0.72)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (hasHiddenDots) ...[
                                const SizedBox(height: 2),
                                Center(
                                  child: Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: const BoxDecoration(
                                      color: kTodayOutline,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),

        // 2. 가로 연속 라벨 바 및 단일 일정 오버레이 (터치 이벤트는 하단 날짜 셀로 통과)
        if (maxLanes > 0)
          IgnorePointer(
            child: Stack(
              children: [
                for (final seg in layout.segments)
                  _buildEventSegmentBar(
                    seg: seg,
                    colWidth: colWidth,
                    dayHeaderH: dayHeaderH,
                    barH: barH,
                    chipFontSize: chipFontSize,
                  ),

                // 초과 일정 수 (+N) 표시
                for (int col = 0; col < 7; col++)
                  if (layout.totalCountPerCol[col] > maxLanes &&
                      rowHeight >= dayHeaderH + maxLanes * barH + plusH)
                    Positioned(
                      left: col * colWidth + 4,
                      top: dayHeaderH + maxLanes * barH,
                      width: colWidth - 6,
                      child: Text(
                        '+${layout.totalCountPerCol[col] - maxLanes}',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                          height: 1.0,
                        ),
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEventSegmentBar({
    required _WeekEventSegment seg,
    required double colWidth,
    required double dayHeaderH,
    required double barH,
    required double chipFontSize,
  }) {
    final ev = seg.event;
    final chipColor = _parseColor(ev.colorHex);
    final isMultiDay = ev.isMultiDay;
    final shouldFillBg = ev.fillLabelBackground || isMultiDay;

    final double leftInset = seg.continuesFromPrevWeek ? 0.0 : 2.5;
    final double rightInset = seg.continuesToNextWeek ? 0.0 : 2.5;
    final double left = seg.startCol * colWidth + leftInset;
    final double width = ((seg.endCol - seg.startCol + 1) * colWidth -
            leftInset -
            rightInset)
        .clamp(8.0, colWidth * 7);
    final double top = dayHeaderH + seg.lane * barH;

    final labelText = (displaySettings.showTime &&
            ev.time != null &&
            !isMultiDay)
        ? '${ev.time} ${ev.title}'
        : ev.title;

    final borderRadius = BorderRadius.horizontal(
      left: seg.continuesFromPrevWeek ? Radius.zero : const Radius.circular(4),
      right: seg.continuesToNextWeek ? Radius.zero : const Radius.circular(4),
    );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: barH - 1.5,
      child: Container(
        padding: EdgeInsets.only(
          left: seg.continuesFromPrevWeek ? 4 : 2,
          right: 3,
          top: 0.5,
          bottom: 0.5,
        ),
        decoration: BoxDecoration(
          color: shouldFillBg
              ? resolveCalendarLabelPastelBg(chipColor)
              : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            if (!seg.continuesFromPrevWeek) ...[
              Container(
                width: 2.4,
                height: chipFontSize + 1.5,
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 2.5),
            ],
            Expanded(
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: chipFontSize,
                  fontWeight: displaySettings.fontWeight.weight,
                  color: kCalendarLabelDarkText,
                  height: 1.05,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
