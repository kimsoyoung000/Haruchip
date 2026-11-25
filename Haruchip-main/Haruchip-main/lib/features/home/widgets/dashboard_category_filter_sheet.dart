import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/dashboard_filter_provider.dart';

/// 메인 대시보드(칩 데이) 상단 우측 [카테고리 필터 아이콘] 탭 시 열리는 바텀시트
/// (대시보드에 노출할 카테고리를 다중 체크 토글)
Future<void> showDashboardCategoryFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _DashboardCategoryFilterSheet(),
  );
}

class _DashboardCategoryFilterSheet extends ConsumerWidget {
  const _DashboardCategoryFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleCategories = ref.watch(visibleCategoriesProvider);
    final selectedKeys = ref.watch(dashboardCategoryFilterProvider);
    final mediaQuery = MediaQuery.of(context);

    final allKeys = visibleCategories.map((c) => c.categoryKey).toSet().toList();
    final isAllActive = selectedKeys.isEmpty;

    void toggleKey(String key) {
      final notifier = ref.read(dashboardCategoryFilterProvider.notifier);
      if (isAllActive) {
        final remaining = allKeys.where((k) => k != key).toSet();
        notifier.state = remaining;
        return;
      }
      final next = Set<String>.from(selectedKeys);
      if (next.contains(key)) {
        next.remove(key);
      } else {
        next.add(key);
      }
      if (next.isEmpty || allKeys.every((k) => next.contains(k))) {
        notifier.state = const <String>{};
      } else {
        notifier.state = next;
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.76),
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
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 6),
                child: Row(
                  children: [
                    const Text(
                      '카테고리 표시',
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
                          ref
                              .read(dashboardCategoryFilterProvider.notifier)
                              .state = const <String>{};
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF476A92),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '전체 표시',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 22, color: Color(0xFF374151)),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              if (visibleCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    '등록된 카테고리가 없습니다.',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: visibleCategories.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 52,
                      color: Color(0xFFF3F4F6),
                    ),
                    itemBuilder: (context, index) {
                      final cat = visibleCategories[index];
                      final color = colorFromHex(cat.colorHex);
                      final isChecked = isAllActive ||
                          selectedKeys.contains(cat.categoryKey);
                      final checkColor = color.computeLuminance() > 0.65
                          ? const Color(0xFF1F2937)
                          : Colors.white;

                      return InkWell(
                        onTap: () => toggleKey(cat.categoryKey),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isChecked ? color : Colors.transparent,
                                  border: Border.all(
                                    color: isChecked
                                        ? color
                                        : const Color(0xFFD1D5DB),
                                    width: 1.8,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isChecked
                                    ? Icon(Icons.check_rounded,
                                        size: 14, color: checkColor)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  cat.name,
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

/// [프로필 & 설정] > [앱 환경설정] > [카테고리 순서 편집] 바텀시트
Future<void> showCategoryOrderEditSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CategoryOrderEditSheet(),
  );
}

class _CategoryOrderEditSheet extends ConsumerWidget {
  const _CategoryOrderEditSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(visibleCategoriesProvider);
    final mediaQuery = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.80),
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
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 6),
                child: Row(
                  children: [
                    const Text(
                      '카테고리 순서 편집',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    '편집할 카테고리가 없습니다.',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                  ),
                )
              else
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: categories.length,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(categoryListProvider.notifier)
                          .reorderCategories(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return ListTile(
                        key: ValueKey('order_${cat.id}'),
                        leading: Text(cat.emoji,
                            style: const TextStyle(fontSize: 18)),
                        title: Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_off_outlined,
                                  size: 18, color: Color(0xFF9CA3AF)),
                              tooltip: '숨기기',
                              onPressed: () => ref
                                  .read(categoryListProvider.notifier)
                                  .hideCategory(cat.id),
                            ),
                            const Icon(Icons.drag_handle_rounded,
                                color: Color(0xFF9CA3AF)),
                          ],
                        ),
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
