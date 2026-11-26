import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../data/wedding_budget_master_items.dart';
import '../models/wedding_budget_item.dart';
import '../models/wedding_item.dart' show matchesKoreanQuery;
import '../providers/wedding_budget_provider.dart';
import 'wedding_budget_edit_modal.dart';

/// 금액 천단위 쉼표 포맷터
String _formatWon(int amount) {
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
}

/// 60개 표준 마스터 템플릿 기반 예산 항목 추가 및 커스텀 추가 바텀시트 모달
class WeddingBudgetTemplateModal extends ConsumerStatefulWidget {
  const WeddingBudgetTemplateModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeddingBudgetTemplateModal(),
    );
  }

  @override
  ConsumerState<WeddingBudgetTemplateModal> createState() =>
      _WeddingBudgetTemplateModalState();
}

class _WeddingBudgetTemplateModalState
    extends ConsumerState<WeddingBudgetTemplateModal> {
  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  late final List<WeddingBudgetMasterTemplate> _allTemplates;
  WeddingBudgetCategory? _selectedCategoryFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allTemplates = create60WeddingBudgetMasterTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addedItems = ref.watch(weddingBudgetListProvider);
    final addedTitles = addedItems.map((i) => i.title).toSet();

    final filtered = _allTemplates.where((tpl) {
      if (_selectedCategoryFilter != null &&
          tpl.category != _selectedCategoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !matchesKoreanQuery(tpl.title, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // 1. 헤더 (타이틀, 직접 입력 버튼, 닫기)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결혼 예산 항목',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _deepBrown,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          '60개 표준 템플릿에서 담거나 직접 추가해보세요',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8C7E6A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            WeddingBudgetEditModal.show(context);
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 15),
                          label: const Text(
                            '직접 입력',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _butterYellow,
                            foregroundColor: _deepBrown,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 검색 바 (키워드/초성 지원)
                TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13, color: _deepBrown),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: '예산 항목 검색 (예: 웨딩홀, 스드메, ㅎㅂ)',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF8C7E6A),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _softGray,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 8대 대분류 카테고리 필터 칩
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildCategoryFilterChip(null, '전체 (60)'),
                      for (final cat in WeddingBudgetCategory.values)
                        _buildCategoryFilterChip(
                          cat,
                          '${cat.labelKo} (${_allTemplates.where((t) => t.category == cat).length})',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F1EE)),

          // 2. 60개 마스터 템플릿 리스트 (무테두리 컴팩트 카드)
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      '일치하는 예산 템플릿이 없습니다.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tpl = filtered[index];
                      final isAdded = addedTitles.contains(tpl.title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isAdded
                              ? const Color(0xFFFFFBF0)
                              : _softGray,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tpl.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isAdded
                                          ? const Color(0xFF8C7E6A)
                                          : _deepBrown,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        tpl.category.labelKo,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const Text(
                                        ' · ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFD1D5DB),
                                        ),
                                      ),
                                      Text(
                                        '평균 ${_formatWon(tpl.defaultEstimatedBudget)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF8A6216),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isAdded)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Color(0xFF8C7E6A),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      '담김',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF8C7E6A),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(weddingBudgetListProvider.notifier)
                                      .addTemplateItem(tpl);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '"${tpl.title}" 항목이 예산표에 추가되었습니다.',
                                      ),
                                      duration: const Duration(milliseconds: 900),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _butterYellow,
                                  foregroundColor: _deepBrown,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 13),
                                    SizedBox(width: 2),
                                    Text(
                                      '담기',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(WeddingBudgetCategory? cat, String label) {
    final isSelected = _selectedCategoryFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryFilter = isSelected ? null : cat;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
          decoration: BoxDecoration(
            color: isSelected ? _butterYellow : _softGray,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? _deepBrown : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}
