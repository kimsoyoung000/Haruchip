import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_provider.dart';
import 'wedding_budget_section_widget.dart';
import 'wedding_item_edit_modal.dart';
import 'wedding_template_manager_modal.dart';

/// 결혼 준비 전용 카테고리 뷰 위젯
/// 1) 일정 등록/변경 시 D-Day 실시간 자동 재정렬 (임박순 우선, 미지정 하단 배치)
/// 2) 원터치 아코디언 메모/상세 토글 (인라인 메모, 상세 장소, 준비 팁 즉시 노출)
/// 3) [+ 항목/일정 추가] -> '결혼 준비 항목' 모달 연동
/// 4) 하단 60개 마스터 템플릿 기반 독립 예산 & 지출 정리표 섹션
class WeddingCategoryView extends ConsumerStatefulWidget {
  const WeddingCategoryView({super.key});

  @override
  ConsumerState<WeddingCategoryView> createState() => _WeddingCategoryViewState();
}

class _WeddingCategoryViewState extends ConsumerState<WeddingCategoryView> {
  WeddingStage? _selectedStageFilter;
  final Set<String> _expandedItemIds = {};

  void _toggleAccordion(String itemId) {
    setState(() {
      if (_expandedItemIds.contains(itemId)) {
        _expandedItemIds.remove(itemId);
      } else {
        _expandedItemIds.add(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(weddingListProvider);

    // 1. 카테고리 필터 적용
    final filteredItems = _selectedStageFilter == null
        ? items
        : items.where((i) => i.stage == _selectedStageFilter).toList();

    // 2. 실시간 D-Day 순서 재정렬 (날짜 지정된 임박순 우선, 일정 미지정 항목 하단 배치)
    final sortedItems = [...filteredItems]..sort(compareWeddingItemsByCloseness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 체크리스트 섹션 상단 헤더 & [+ 항목/일정 추가] 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '준비 항목 체크리스트 (${items.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => WeddingTemplateManagerModal.show(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                '항목/일정 추가',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. 단계 필터 탭
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildStageChip(null, '전체 (${items.length})'),
              for (final stage in WeddingStage.values)
                _buildStageChip(
                  stage,
                  '${stage.emoji} ${stage.labelKo} (${items.where((i) => i.stage == stage).length})',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. 준비 항목 카드 리스트 (실시간 D-Day 임박순 자동 정렬 + 원터치 아코디언 메모)
        if (sortedItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text('💍', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                const Text(
                  '선택된 결혼 준비 일정이 없습니다.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '상단의 [+ 항목/일정 추가] 버튼을 눌러\n원하는 결혼 일정을 담아보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => WeddingTemplateManagerModal.show(context),
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: const Text('결혼 일정 담기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in sortedItems) ...[
            _buildRefinedItemCard(item),
          ],

        const SizedBox(height: 28),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),

        // 4. 하단 독립된 [60개 마스터 템플릿 기반 결혼 예산 & 지출 정리표] 섹션
        const WeddingBudgetSectionWidget(),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 준비 항목 카드 UI (가독성 극대화 + 원터치 아코디언 메모/상세 인라인 토글)
  Widget _buildRefinedItemCard(WeddingItem item) {
    final isExpanded = _expandedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isCompleted
              ? const Color(0xFFE2E8F0)
              : (isExpanded ? const Color(0xFFE53E3E) : const Color(0xFFFED7D7)),
          width: isExpanded ? 1.8 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.04 : 0.02),
            blurRadius: isExpanded ? 10 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 카드 본문 행 (탭 시 아코디언 토글)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [좌측]: 완료 체크박스 (체크 토글 전용, 아코디언 탭 분리)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: InkWell(
                    onTap: () => ref.read(weddingListProvider.notifier).toggleItemCompletion(item.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.isCompleted ? const Color(0xFFE53E3E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: item.isCompleted ? const Color(0xFFE53E3E) : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: item.isCompleted
                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // [중앙]: 항목명 + 일시/장소 (탭 시 원터치 아코디언 펼침/접힘)
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleAccordion(item.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [중앙 상단]: 항목명 (#순번 태그 완전 제거)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: item.isCompleted
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF1E293B),
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: isExpanded ? const Color(0xFFE53E3E) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // [중앙 하단]: 일시 및 장소 (한눈에 확인)
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: [
                            // 📅 일시
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📅 ', style: TextStyle(fontSize: 12.5)),
                                Text(
                                  item.targetDate != null
                                      ? '${item.formattedDateTime} (${item.dDayLabel()})'
                                      : '일정 미지정',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: item.targetDate != null
                                        ? const Color(0xFF475569)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            // 📍 장소
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📍 ', style: TextStyle(fontSize: 12.5)),
                                Text(
                                  item.location.isNotEmpty ? item.location : '장소 미지정',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: item.location.isNotEmpty
                                        ? const Color(0xFF475569)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // [우측]: 편집(연필) 아이콘 (모달 열기)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                  tooltip: '일정 및 장소 수정',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => WeddingItemEditModal.show(context, item),
                ),
              ],
            ),
          ),

          // [아코디언 인라인 확장 상세 영역]
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // 1) 작성된 메모
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEDF2F7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 15, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Text(
                              '작성된 메모',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.memo.isNotEmpty
                              ? item.memo
                              : '작성된 메모가 없습니다. 우측 연필 아이콘을 눌러 메모를 작성해보세요.',
                          style: TextStyle(
                            fontSize: 13,
                            color: item.memo.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 2) 상세 장소 & 카테고리 팁 인라인
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              Text(item.stage.emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '카테고리: ${item.stage.labelKo}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF881337)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (item.weekdayNotice != null && item.weekdayNotice!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.weekdayNotice!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3) 빠른 일정/장소 수정 액션 바
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => WeddingItemEditModal.show(context, item),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 15, color: Color(0xFFE53E3E)),
                      label: const Text(
                        '일정 / 장소 / 메모 수정하기',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE53E3E)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageChip(WeddingStage? stage, String label) {
    final isSelected = _selectedStageFilter == stage;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFE53E3E),
        backgroundColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? const Color(0xFFE53E3E) : const Color(0xFFE2E8F0),
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedStageFilter = val ? stage : null;
          });
        },
      ),
    );
  }
}
