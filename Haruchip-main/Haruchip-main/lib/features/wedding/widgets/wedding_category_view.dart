import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_extras_models.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_extras_provider.dart';
import '../providers/wedding_provider.dart';
import 'wedding_budget_section_widget.dart';
import 'wedding_invitation_meeting_section.dart';
import 'wedding_item_edit_modal.dart';
import 'wedding_template_manager_modal.dart';

/// 결혼 준비 전용 카테고리 뷰 위젯 (D-Day 임박순 단일 리스트 + 청모 + 통합 예산표)
///
/// 1) 웨딩 체크리스트: 인위적 폴더 그룹핑 폐기 → D-Day 임박순(오름차순) 단일 리스트 + 최하단 [날짜 미정 항목 (N개)] 접기/펼치기
/// 2) 청첩장 모임: D-Day 임박순 자동 정렬 + 보증인원 카운터
/// 3) 웨딩 예산·지출표: 본식 전 준비 지출 + 본식 당일/사후 정산 완전 통합
/// 4) 3대 메인 섹션 순서 편집 & 독립 숨김 커스터마이징
class WeddingCategoryView extends ConsumerStatefulWidget {
  const WeddingCategoryView({super.key});

  @override
  ConsumerState<WeddingCategoryView> createState() =>
      _WeddingCategoryViewState();
}

class _WeddingCategoryViewState extends ConsumerState<WeddingCategoryView> {
  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  /// 날짜 미정 항목 섹션 사용자 수동 접기/펼치기 상태 (null이면 날짜 지정 항목 유무에 따라 자동 결정)
  bool? _undatedExpandedOverride;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(weddingListProvider);
    final stats = ref.watch(weddingStatsProvider);
    final extras = ref.watch(weddingExtrasProvider);

    final order = extras.sectionOrder.isNotEmpty
        ? extras.sectionOrder
        : kDefaultWeddingSectionOrder;

    final children = <Widget>[];
    for (final secKey in order) {
      if (extras.hiddenSections.contains(secKey)) continue;
      Widget? section;
      switch (secKey) {
        case 'checklist':
          section = _buildChronologicalChecklistSection(items, stats);
          break;
        case 'invitationMeetings':
          section = const WeddingInvitationMeetingSection();
          break;
        case 'budget':
          section = const WeddingBudgetSectionWidget();
          break;
      }
      if (section != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 18));
        }
        children.add(section);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  /// 단일 D-Day 임박순(오름차순) 체크리스트 + 하단 [날짜 미정 항목 (N개)] 접기/펼치기
  Widget _buildChronologicalChecklistSection(
    List<WeddingItem> items,
    ({int completed, int total, double ratio}) stats,
  ) {
    final datedItems = items.where((i) => i.targetDate != null).toList()
      ..sort(compareWeddingItemsByCloseness);
    final undatedItems = items.where((i) => i.targetDate == null).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final isUndatedExpanded =
        _undatedExpandedOverride ?? datedItems.isEmpty;

    return Column(
      key: const Key('wedding_checklist_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더 + 단일 [+] 라운드 아이콘 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text(
                    '웨딩 체크리스트',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _deepBrown,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${stats.completed}/${stats.total}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              key: const Key('wedding_open_smart_picker_btn'),
              onTap: () => WeddingTemplateManagerModal.show(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _butterYellow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: _deepBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),

        // 1. D-Day 임박순(오름차순) 단일 리스트
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '등록된 결혼 준비 일정이 없습니다. 우측 [+]로 담아보세요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          )
        else ...[
          if (datedItems.isNotEmpty)
            Container(
              key: const Key('wedding_chronological_list'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final item in datedItems) _buildSlimChecklistTile(item),
                ],
              ),
            ),

          // 2. 최하단 [날짜 미정 항목 (N개)] 접기/펼치기 섹션
          if (undatedItems.isNotEmpty) ...[
            if (datedItems.isNotEmpty) const SizedBox(height: 8),
            Container(
              key: const Key('wedding_undated_section'),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    key: const Key('wedding_undated_section_header'),
                    onTap: () {
                      setState(() {
                        _undatedExpandedOverride = !isUndatedExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '날짜 미정 항목 (${undatedItems.length}개)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8C7E6A),
                              ),
                            ),
                          ),
                          Icon(
                            isUndatedExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isUndatedExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(9, 0, 9, 5),
                      child: Column(
                        children: [
                          for (final item in undatedItems)
                            _buildSlimChecklistTile(item),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// 체크리스트 1줄 슬림 타일
  /// - 날짜 미지정: `[ 미정 ]`
  /// - 날짜 지정: `[ 2026.05.14(목) · D-35 ]`
  Widget _buildSlimChecklistTile(WeddingItem item) {
    final badgeText = item.formattedDateWithWeekdayAndDday();
    final hasDate = item.targetDate != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: _softGray,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: Key('wedding_slim_tile_${item.id}'),
          onTap: () => WeddingItemEditModal.show(context, item),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              children: [
                // 라운드 체크박스
                InkWell(
                  key: Key('wedding_tile_checkbox_${item.id}'),
                  onTap: () => ref
                      .read(weddingListProvider.notifier)
                      .toggleItemCompletion(item.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: item.isCompleted ? _butterYellow : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: item.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: _deepBrown,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // 일정명 (장소 있으면 함께 1줄 압축)
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: item.isCompleted
                                ? const Color(0xFF9CA3AF)
                                : _deepBrown,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (item.location.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '· 📍${item.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isCompleted
                                  ? const Color(0xFFB0B7C3)
                                  : const Color(0xFF8C7E6A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // 우측 날짜(요일) · D-Day 슬림 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: item.isCompleted
                        ? const Color(0xFFECEEF1)
                        : (hasDate ? const Color(0xFFFFF4CC) : Colors.white),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: item.isCompleted
                          ? const Color(0xFF9CA3AF)
                          : (hasDate ? _deepBrown : const Color(0xFF9CA3AF)),
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
}

/// 결혼 준비 카테고리 3대 메인 섹션 순서 변경 & 숨김 관리 바텀시트
Future<void> showWeddingSectionManagementModal(
  BuildContext context,
  WidgetRef ref,
) async {
  final current = ref.read(weddingExtrasProvider);
  final order = List<String>.from(
    current.sectionOrder.isNotEmpty
        ? current.sectionOrder
            .where((k) => kDefaultWeddingSectionOrder.contains(k))
        : kDefaultWeddingSectionOrder,
  );
  for (final k in kDefaultWeddingSectionOrder) {
    if (!order.contains(k)) order.add(k);
  }
  final hidden = Set<String>.from(current.hiddenSections);

  const sectionLabels = <String, ({String title, String subtitle})>{
    'checklist': (
      title: '웨딩 체크리스트',
      subtitle: 'D-Day 임박순 자동 정렬 & 날짜 미정 관리',
    ),
    'invitationMeetings': (
      title: '청첩장 모임',
      subtitle: '임박순 청모 리스트 및 보증인원 카운터',
    ),
    'budget': (
      title: '웨딩 예산 · 지출표',
      subtitle: '본식 전 준비 + 당일/사후 정산 통합 예산 관리',
    ),
  };

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '결혼 준비 섹션 순서 및 숨김 관리',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.chipYellowText,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '드래그로 순서를 바꾸거나 스위치를 꺼서 원하는 섹션을 숨길 수 있어요.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF8C7E6A)),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: order.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setModalState(() {
                      final moved = order.removeAt(oldIndex);
                      order.insert(newIndex, moved);
                    });
                  },
                  itemBuilder: (context, index) {
                    final key = order[index];
                    final meta =
                        sectionLabels[key] ?? (title: key, subtitle: '');
                    final isVisible = !hidden.contains(key);
                    return Container(
                      key: ValueKey('wed_sec_$key'),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                size: 20,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.chipYellowText,
                                  ),
                                ),
                                Text(
                                  meta.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF8C7E6A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            key: Key('wedding_section_toggle_$key'),
                            value: isVisible,
                            activeTrackColor: AppColors.chipYellowBg,
                            activeThumbColor: AppColors.chipYellowText,
                            onChanged: (val) {
                              setModalState(() {
                                if (val) {
                                  hidden.remove(key);
                                } else {
                                  hidden.add(key);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  key: const Key('wedding_section_save_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chipYellowBg,
                    foregroundColor: AppColors.chipYellowText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(weddingExtrasProvider.notifier)
                        .updateSectionConfig(order: order, hidden: hidden);
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    '적용하기',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
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
