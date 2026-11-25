import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/calendar_provider.dart';
import 'themed_color_palette_sheet.dart';

/// 칩 캘린더 상단 우측 [카테고리 필터 아이콘] 탭 시 열리는 다중 선택 바텀시트
///
/// - 상단: [카테고리] 타이틀 + 우측 닫기(X) 버튼
/// - 좌측: 원형 체크박스 (다중 선택 토글)
/// - 중앙: 카테고리 명칭 (이모지 + 이름)
/// - 우측: (i) 아이콘 (탭 시 해당 카테고리 테마별 파스텔 색상 팔레트 변경 호출)
Future<void> showCalendarCategoryFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CalendarCategoryFilterSheet(),
  );
}

class _CalendarCategoryFilterSheet extends ConsumerWidget {
  const _CalendarCategoryFilterSheet();

  static const List<({String key, String label, Color color, String emoji})>
      _kDefaultCategories = [
    (key: 'plan', label: '내 일정', color: Color(0xFF60A5FA), emoji: '📝'),
    (key: 'couple', label: '커플', color: Color(0xFFFF8DA1), emoji: '❤️'),
    (key: 'solo', label: '솔로', color: Color(0xFFC084FC), emoji: '🌟'),
    (key: 'fandom', label: '덕질', color: Color(0xFFFBBF24), emoji: '⭐'),
    (key: 'group', label: '모임', color: Color(0xFF34D399), emoji: '👥'),
    (key: 'exam', label: '시험', color: Color(0xFF818CF8), emoji: '📚'),
    (key: 'birthday', label: '생일', color: Color(0xFFF472B6), emoji: '🎂'),
    (key: 'baby', label: '아기', color: Color(0xFFFDE047), emoji: '👶'),
    (key: 'pet', label: '반려동물', color: Color(0xFFFB923C), emoji: '🐾'),
    (key: 'military', label: '군대', color: Color(0xFFA3E635), emoji: '🎖️'),
    (key: 'wedding', label: '결혼', color: Color(0xFFFDA4AF), emoji: '💍'),
    (key: 'travel', label: '여행', color: Color(0xFF38BDF8), emoji: '✈️'),
    (key: 'hobby', label: '취미', color: Color(0xFF6EE7B7), emoji: '🎨'),
  ];

  String _colorToHex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCategories = ref.watch(categoryListProvider);
    final selectedCategories = ref.watch(calendarSelectedCategoriesProvider);
    final mediaQuery = MediaQuery.of(context);

    final List<({String id, String key, String label, Color color, String emoji})>
        items = userCategories.isNotEmpty
            ? userCategories
                .map((c) => (
                      id: c.id,
                      key: c.categoryKey.isNotEmpty ? c.categoryKey : c.id,
                      label: c.name,
                      color: colorFromHex(c.colorHex),
                      emoji: c.emoji,
                    ))
                .toList()
            : _kDefaultCategories
                .map((c) => (
                      id: '',
                      key: c.key,
                      label: c.label,
                      color: c.color,
                      emoji: c.emoji,
                    ))
                .toList();

    final allKeys = items.map((e) => e.key).toList();
    final isAllActive = selectedCategories.isEmpty;

    void toggleKey(String key) {
      ref.read(calendarCategoryFilterProvider.notifier).state = null;
      final notifier = ref.read(calendarSelectedCategoriesProvider.notifier);

      if (isAllActive) {
        // 전체 선택 상태에서 하나를 해제하면, 해당 항목을 제외한 나머지 모두 선택
        final remaining = allKeys.where((k) => k != key).toSet();
        notifier.state = remaining;
        return;
      }

      final next = Set<String>.from(selectedCategories);
      if (next.contains(key)) {
        next.remove(key);
      } else {
        next.add(key);
      }

      // 모두 선택되거나 모두 해제되면 전체 모드로 복귀
      if (next.isEmpty || allKeys.every((k) => next.contains(k))) {
        notifier.state = const <String>{};
      } else {
        notifier.state = next;
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.78),
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
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더: [카테고리] + 전체 선택 버튼 + 우측 닫기(X) 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 6),
                child: Row(
                  children: [
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    if (!isAllActive)
                      TextButton(
                        onPressed: () {
                          ref.read(calendarCategoryFilterProvider.notifier).state = null;
                          ref.read(calendarSelectedCategoriesProvider.notifier).state =
                              const <String>{};
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF476A92),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '전체 표시',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF374151)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 카테고리 체크 리스트
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 52,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isChecked =
                        isAllActive || selectedCategories.contains(item.key);
                    final checkIconColor = item.color.computeLuminance() > 0.65
                        ? const Color(0xFF1F2937)
                        : Colors.white;

                    return Row(
                      children: [
                        // 좌측(원형 체크박스) + 중앙(카테고리 명칭) -> 다중 토글
                        Expanded(
                          child: InkWell(
                            onTap: () => toggleKey(item.key),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isChecked ? item.color : Colors.transparent,
                                      border: Border.all(
                                        color: isChecked
                                            ? item.color
                                            : const Color(0xFFD1D5DB),
                                        width: 1.8,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: isChecked
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: checkIconColor,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(item.emoji, style: const TextStyle(fontSize: 15)),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isChecked
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isChecked
                                            ? const Color(0xFF111827)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 우측: (i) 정보/색상 팔레트 변경 아이콘
                        IconButton(
                          key: Key('filter_category_info_${item.key}'),
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: Color(0xFF9CA3AF),
                          ),
                          tooltip: '${item.label} 색상 설정',
                          onPressed: () async {
                            final pickedHex = await showThemedColorPickerSheet(
                              context,
                              title: '${item.emoji} ${item.label} 색상 변경',
                              currentHex: _colorToHex(item.color),
                            );
                            if (pickedHex != null) {
                              ref
                                  .read(categoryListProvider.notifier)
                                  .updateCategoryColor(
                                    categoryKey: item.key,
                                    id: item.id,
                                    name: item.label,
                                    emoji: item.emoji,
                                    colorHex: pickedHex,
                                  );
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
