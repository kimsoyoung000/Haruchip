import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../data/wedding_budget_master_items.dart';
import '../models/wedding_budget_item.dart';
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
  ConsumerState<WeddingBudgetTemplateModal> createState() => _WeddingBudgetTemplateModalState();
}

class _WeddingBudgetTemplateModalState extends ConsumerState<WeddingBudgetTemplateModal> {
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
      if (_selectedCategoryFilter != null && tpl.category != _selectedCategoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !tpl.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 1. 헤더 (타이틀, 직접 추가 버튼, 닫기)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '60개 표준 템플릿에서 담거나 직접 추가해보세요',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
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
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text('직접 입력', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 검색 바
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: '예산 항목 검색 (예: 웨딩홀, 스드메, 부케...)',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

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
                          '${cat.emoji} ${cat.labelKo} (${_allTemplates.where((t) => t.category == cat).length})',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 2. 60개 마스터 템플릿 리스트
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      '일치하는 예산 템플릿이 없습니다.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tpl = filtered[index];
                      final isAdded = addedTitles.contains(tpl.title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdded ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAdded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            // 카테고리 이모지 박스
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(tpl.category.emoji, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),

                            // 제목, 카테고리 및 추천 예산, 팁
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tpl.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isAdded
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        tpl.category.labelKo,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                      Text(
                                        '평균 ${_formatWon(tpl.defaultEstimatedBudget)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE53E3E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (tpl.tip.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      tpl.tip,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // [+] 담기 / [✓ 담김] 버튼
                            if (isAdded)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, size: 14, color: Color(0xFF2563EB)),
                                    SizedBox(width: 4),
                                    Text(
                                      '담김',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(weddingBudgetListProvider.notifier).addTemplateItem(tpl);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✨ "${tpl.title}" 항목이 예산표에 추가되었습니다.'),
                                      duration: const Duration(milliseconds: 900),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53E3E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 14),
                                    SizedBox(width: 2),
                                    Text('담기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFFF1F5F9),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFFE53E3E) : Colors.transparent,
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedCategoryFilter = val ? cat : null;
          });
        },
      ),
    );
  }
}
