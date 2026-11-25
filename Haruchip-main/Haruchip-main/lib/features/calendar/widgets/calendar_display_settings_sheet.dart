import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_display_settings.dart';
import '../providers/calendar_display_settings_provider.dart';

/// 칩 캘린더 표시 설정 바텀시트 (최초 진입 1회 안내 및 프로필 & 설정 > 앱 환경설정에서 재진입 공용)
///
/// 글꼴 크기 / 글자 굵기 / 라벨 형식 (시간 표시, 시간 일정 간단히 표시, 음력) + 실시간 1주 미리보기
/// (가로 넘김 단일화 및 하루칩 파스텔 톤 고정 — 세로 스크롤/테마 색상 옵션 제거)
Future<void> showCalendarDisplaySettingsSheet(
  BuildContext context, {
  bool isOnboarding = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CalendarDisplaySettingsSheet(isOnboarding: isOnboarding),
  );
}

class _CalendarDisplaySettingsSheet extends ConsumerWidget {
  const _CalendarDisplaySettingsSheet({required this.isOnboarding});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarDisplaySettingsProvider);
    final notifier = ref.read(calendarDisplaySettingsProvider.notifier);
    final mediaQuery = MediaQuery.of(context);
    const accent = Color(0xFF2C2C2E);

    final double chipFontSize = 9.5 * settings.fontSize.scale;
    final double dayFontSize = 11.5 * settings.fontSize.scale;
    final FontWeight chipWeight = settings.fontWeight.weight;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 상단 네비게이션 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF374151),
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () {
                          notifier.markOnboardingSeen();
                          Navigator.of(context).pop();
                        },
                      ),
                      const Expanded(
                        child: Text(
                          '글꼴 크기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          notifier.markOnboardingSeen();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isOnboarding ? '건너뛰기' : '완료',
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // 본문 스크롤 영역
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 실시간 1주 플랫 미리보기 바
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _previewDayCell(
                                day: '22',
                                lunar: '10.14',
                                isSunday: true,
                                dayFontSize: dayFontSize,
                                showLunar: settings.showLunar,
                                chips: const [],
                              ),
                              _previewDayCell(
                                day: '23',
                                lunar: '10.15',
                                dayFontSize: dayFontSize,
                                showLunar: settings.showLunar,
                                chips: [
                                  _previewBar(
                                    settings.showTime ? '09:00 정기 일정' : '정기 일정',
                                    const Color(0xFFE84A7F),
                                    chipFontSize,
                                    chipWeight,
                                  ),
                                ],
                              ),
                              _previewDayCell(
                                day: '24',
                                lunar: '10.16',
                                isToday: true,
                                dayFontSize: dayFontSize,
                                showLunar: settings.showLunar,
                                chips: const [],
                              ),
                              _previewDayCell(
                                day: '25',
                                lunar: '10.17',
                                dayFontSize: dayFontSize,
                                showLunar: settings.showLunar,
                                chips: [
                                  _previewBar(
                                    settings.showTime ? '12:00 점심' : '점심',
                                    const Color(0xFFF59E0B),
                                    chipFontSize,
                                    chipWeight,
                                  ),
                                ],
                              ),
                              _previewDayCell(
                                day: '26',
                                lunar: '10.18',
                                dayFontSize: dayFontSize,
                                showLunar: settings.showLunar,
                                chips: [
                                  _previewBar(
                                    '회의',
                                    const Color(0xFF3B82F6),
                                    chipFontSize,
                                    chipWeight,
                                  ),
                                  _previewBar(
                                    '운동',
                                    const Color(0xFFA855F7),
                                    chipFontSize,
                                    chipWeight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 글꼴 크기 & 글자 굵기 카드
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '글꼴 크기',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SegmentedBar<CalendarFontSize>(
                                values: CalendarFontSize.values,
                                selected: settings.fontSize,
                                labelOf: (v) => v.labelKo,
                                onSelected: notifier.setFontSize,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                '글자 굵기',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SegmentedBar<CalendarFontWeight>(
                                values: CalendarFontWeight.values,
                                selected: settings.fontWeight,
                                labelOf: (v) => v.labelKo,
                                onSelected: notifier.setFontWeight,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 라벨 형식 섹션
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            '라벨 형식',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _SwitchRow(
                                label: '시간 표시',
                                value: settings.showTime,
                                activeColor: accent,
                                onChanged: notifier.setShowTime,
                              ),
                              const Divider(
                                  height: 1, indent: 14, color: Color(0xFFF1F5F9)),
                              _SwitchRow(
                                label: '시간 일정 간단히 표시',
                                value: settings.compactTimeEvent,
                                activeColor: accent,
                                onChanged: notifier.setCompactTimeEvent,
                              ),
                              const Divider(
                                  height: 1, indent: 14, color: Color(0xFFF1F5F9)),
                              _SwitchRow(
                                label: '음력',
                                value: settings.showLunar,
                                activeColor: accent,
                                onChanged: notifier.setShowLunar,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            '*이 설정은 프로필 & 설정 > 앱 환경설정에서 언제든 변경할 수 있습니다.',
                            style:
                                TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단 완료 CTA 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        notifier.markOnboardingSeen();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewDayCell({
    required String day,
    required String lunar,
    required double dayFontSize,
    required bool showLunar,
    required List<Widget> chips,
    bool isSunday = false,
    bool isToday = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF2C2C2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: dayFontSize,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday
                        ? Colors.white
                        : (isSunday
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF1F2937)),
                  ),
                ),
                if (showLunar) ...[
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      lunar,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: isToday
                            ? Colors.white70
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            ...chips,
          ],
        ),
      ),
    );
  }

  Widget _previewBar(
    String text,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.5),
      child: Row(
        children: [
          Container(
            width: 2.5,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 2.5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: weight,
                color: const Color(0xFF1F2937),
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar<T> extends StatelessWidget {
  const _SegmentedBar({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final item in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: item == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: item == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        labelOf(item),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: item == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: item == selected
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
