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

/// 미니멀 플랫 월간 캘린더 그리드 (무스크롤 Zero-Scroll + 순백 플랫 캔버스 + 좌측 세로 컬러 바 라벨)
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasEventOnDate,
    this.getEventsOnDate,
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
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool? startOnMonday;
  final CalendarDisplaySettings displaySettings;

  // 레퍼런스 스타일 다크 그레이 선택 하이라이트 & 포테이토 칩 소프트 크림 오늘 강조
  static const Color _kSelectedCardBg = Color(0xFF2C2C2E);
  static const Color _kTodayPillBg = Color(0xFFFFF3D6);
  static const Color _kTodayPillBorder = Color(0xFFF2C97D);
  static const Color _kTodayText = Color(0xFF3D2C10);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

  /// 연속 일정(여행 등) 여부 판별
  bool _isContinuousEvent(CalendarEvent ev) {
    return ev.id.startsWith('cal-trip-') ||
        ev.categoryKey == 'travel' ||
        ev.title.contains('일차)');
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
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
    final gridItemCount = rowCount * 7;

    final gridStartDate = firstOfMonth.subtract(Duration(days: leadingBlanks));

    final weekLabels = useMondayStart
        ? const ['월', '화', '수', '목', '금', '토', '일']
        : const ['일', '월', '화', '수', '목', '금', '토'];

    // 가로 넘김 방식으로 단일화
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
          // 요일 헤더 (플랫, 박스 없음)
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

          // 날짜 셀 그리드 — 격자 테두리 제거, 남은 높이를 주차 수로 동적 분배 (Zero-Scroll)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double mainSpacing = 2.0;
                const double crossSpacing = 1.0;
                final double availableHeight = constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : rowCount * 62.0;
                final double rawCellHeight =
                    (availableHeight - mainSpacing * (rowCount - 1)) / rowCount;
                final double cellHeight =
                    rawCellHeight > 14.0 ? rawCellHeight : 14.0;

                final double baseDayFont = cellHeight < 38
                    ? 10.5
                    : (cellHeight < 52 ? 12.0 : 13.0);
                final double dayFontSize =
                    (baseDayFont * settings.fontSize.scale).clamp(9.5, 15.0);
                final double baseChipFont = cellHeight < 46 ? 9.5 : 10.5;
                final double chipFontSize =
                    (baseChipFont * settings.fontSize.scale).clamp(8.5, 12.0);

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: mainSpacing,
                    crossAxisSpacing: crossSpacing,
                    mainAxisExtent: cellHeight,
                  ),
                  itemCount: gridItemCount,
                  itemBuilder: (context, index) {
                    final date = gridStartDate.add(Duration(days: index));
                    final isCurrentMonth = date.month == focusedMonth.month &&
                        date.year == focusedMonth.year;
                    final isToday = _isSameDay(date, today);
                    final isSelected = _isSameDay(date, selectedDate);
                    final dayEvents =
                        isCurrentMonth ? (getEventsOnDate?.call(date) ?? []) : <CalendarEvent>[];
                    final holidayName =
                        isCurrentMonth ? _getHolidayName(date) : null;
                    final isSunday = date.weekday == DateTime.sunday;
                    final isSaturday = date.weekday == DateTime.saturday;

                    Color dayTextColor;
                    if (isSelected) {
                      dayTextColor = Colors.white;
                    } else if (!isCurrentMonth) {
                      dayTextColor = const Color(0xFFC7C7CC);
                    } else if (isToday) {
                      dayTextColor = _kTodayText;
                    } else if (holidayName != null || isSunday) {
                      dayTextColor = const Color(0xFFE11D48);
                    } else if (isSaturday) {
                      dayTextColor = const Color(0xFF6B7280);
                    } else {
                      dayTextColor = const Color(0xFF111827);
                    }

                    return InkWell(
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
                              ? _kSelectedCardBg
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 날짜 숫자 (선택: 다크 라운드 카드 / 오늘: 소프트 크림 옐로우 칩)
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (isToday && !isSelected) ? 6 : 2,
                                    vertical: (isToday && !isSelected) ? 1.5 : 0.5,
                                  ),
                                  decoration: (isToday && !isSelected)
                                      ? BoxDecoration(
                                          color: _kTodayPillBg,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: _kTodayPillBorder,
                                            width: 1,
                                          ),
                                        )
                                      : null,
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
                                          cellHeight >= 46) ...[
                                        const SizedBox(width: 2),
                                        Text(
                                          _approxLunarLabel(date),
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: isSelected
                                                ? Colors.white60
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            if (dayEvents.isNotEmpty) ...[
                              const SizedBox(height: 2.5),
                              // 미니멀 플랫 일정 바 (좌측 얇은 세로 컬러 바 + 콤팩트 제목 / 연속 일정은 소프트 파스텔 띠)
                              Expanded(
                                child: LayoutBuilder(builder: (context, box) {
                                  if (box.maxHeight < 6) {
                                    return const SizedBox.shrink();
                                  }
                                  final scaler =
                                      MediaQuery.textScalerOf(context);
                                  final barH =
                                      scaler.scale(chipFontSize) + 4.0;
                                  final plusH = scaler.scale(7.5) + 1.5;
                                  final maxItems = dayEvents.length < 3
                                      ? dayEvents.length
                                      : 3;
                                  var shown = maxItems;
                                  while (shown > 0) {
                                    final totalH = shown * barH +
                                        (shown < dayEvents.length ? plusH : 0);
                                    if (totalH <= box.maxHeight) break;
                                    shown--;
                                  }
                                  final overflowCount =
                                      dayEvents.length - shown;

                                  if (shown == 0) {
                                    return Align(
                                      alignment: Alignment.topCenter,
                                      child: Wrap(
                                        spacing: 2,
                                        runSpacing: 1,
                                        children: [
                                          for (final ev in dayEvents.take(3))
                                            Container(
                                              width: 4.5,
                                              height: 4.5,
                                              decoration: BoxDecoration(
                                                color: _parseColor(ev.colorHex),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      for (int i = 0; i < shown; i++)
                                        Builder(builder: (context) {
                                          final ev = dayEvents[i];
                                          final chipColor =
                                              _parseColor(ev.colorHex);
                                          final isContinuous =
                                              _isContinuousEvent(ev);
                                          final labelText =
                                              (settings.showTime &&
                                                      ev.time != null)
                                                  ? '${ev.time} ${ev.title}'
                                                  : ev.title;

                                          return Container(
                                            height: barH - 1.5,
                                            margin: const EdgeInsets.only(
                                                bottom: 1.5),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                              vertical: 0.8,
                                            ),
                                            decoration: isContinuous
                                                ? BoxDecoration(
                                                    color: isSelected
                                                        ? chipColor.withValues(
                                                            alpha: 0.35)
                                                        : chipColor.withValues(
                                                            alpha: 0.22),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  )
                                                : null,
                                            child: Row(
                                              children: [
                                                // 좌측 얇은 세로 컬러 바 (| 헬스장 스타일)
                                                Container(
                                                  width: 2.2,
                                                  height: chipFontSize + 1,
                                                  decoration: BoxDecoration(
                                                    color: chipColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            1.5),
                                                  ),
                                                ),
                                                const SizedBox(width: 2.5),
                                                Expanded(
                                                  child: Text(
                                                    labelText,
                                                    style: TextStyle(
                                                      fontSize: chipFontSize,
                                                      fontWeight: settings
                                                          .fontWeight.weight,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF374151),
                                                      height: 1.05,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      if (overflowCount > 0 &&
                                          box.maxHeight >=
                                              shown * barH + plusH)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 2),
                                          child: Text(
                                            '+$overflowCount',
                                            style: TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white70
                                                  : const Color(0xFF9CA3AF),
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
