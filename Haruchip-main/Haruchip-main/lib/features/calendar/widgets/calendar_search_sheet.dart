import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/providers/category_provider.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';

/// 칩 캘린더 일정 검색 모달/페이지 (과거·미래 전 카테고리 실시간 검색 & 해당 날짜 즉시 이동)
Future<void> showCalendarSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CalendarSearchSheet(),
  );
}

class _CalendarSearchSheet extends ConsumerStatefulWidget {
  const _CalendarSearchSheet();

  @override
  ConsumerState<_CalendarSearchSheet> createState() =>
      _CalendarSearchSheetState();
}

class _CalendarSearchSheetState extends ConsumerState<_CalendarSearchSheet> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  String _formatDate(DateTime d) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w = weekdays[d.weekday - 1];
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ($w)';
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = ref.watch(allUnfilteredCalendarEventsProvider);
    final categories = ref.watch(categoryListProvider);
    final mediaQuery = MediaQuery.of(context);

    final q = _query.trim().toLowerCase();
    final List<CalendarEvent> results = q.isEmpty
        ? ([...allEvents]..sort((a, b) => a.date.compareTo(b.date)))
        : (allEvents.where((e) {
            final titleMatch = e.title.toLowerCase().contains(q);
            final keyMatch = e.categoryKey.toLowerCase().contains(q);
            final catName = categories
                .where((c) => c.categoryKey == e.categoryKey || c.id == e.categoryKey)
                .map((c) => c.name.toLowerCase())
                .join(' ');
            return titleMatch || keyMatch || catName.contains(q);
          }).toList()
            ..sort((a, b) => a.date.compareTo(b.date)));

    String categoryLabelOf(String key) {
      final match = categories.where((c) => c.categoryKey == key || c.id == key);
      if (match.isNotEmpty) return match.first.name;
      const fallback = {
        'plan': '내 일정',
        'couple': '커플',
        'solo': '솔로',
        'fandom': '덕질',
        'group': '모임',
        'exam': '시험',
        'birthday': '생일',
        'baby': '아기',
        'pet': '반려동물',
        'military': '군대',
        'wedding': '결혼',
        'travel': '여행',
        'hobby': '취미',
      };
      return fallback[key] ?? key;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.86),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 상단 검색 입력 바
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          autofocus: true,
                          onChanged: (val) => setState(() => _query = val),
                          decoration: InputDecoration(
                            hintText: '일정 제목 또는 카테고리 검색',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    onPressed: () {
                                      _queryController.clear();
                                      setState(() => _query = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '닫기',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 결과 카운트
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        q.isEmpty
                            ? '전체 일정 (${results.length}건)'
                            : '검색 결과 (${results.length}건)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // 검색 결과 리스트
                Flexible(
                  child: results.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 32, color: Color(0xFFD1D5DB)),
                              SizedBox(height: 8),
                              Text(
                                '일치하는 일정이 없습니다.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFF3F4F6),
                          ),
                          itemBuilder: (context, index) {
                            final ev = results[index];
                            final accent = _parseColor(ev.colorHex);
                            return InkWell(
                              onTap: () {
                                // 선택한 일정 날짜로 캘린더 월/일 포커스 즉시 이동
                                ref.read(calendarViewModeProvider.notifier).state =
                                    CalendarViewMode.month;
                                ref
                                    .read(calendarSelectionProvider.notifier)
                                    .focusDate(ev.date);
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    // 좌측 세로 컬러 바
                                    Container(
                                      width: 3,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ev.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: accent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                categoryLabelOf(ev.categoryKey),
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatDate(ev.date),
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (ev.time != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        ev.time!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
