import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_budget_item.dart';
import '../providers/wedding_budget_provider.dart';
import 'wedding_budget_edit_modal.dart';
import 'wedding_budget_template_modal.dart';

/// 금액 천단위 쉼표 포맷터
String _formatWon(int amount) {
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
}

/// 독립된 하단 [결혼 예산 & 지출 정리표] 섹션 위젯
/// - 상단 예산 요약 대시보드: [총 예상 예산] vs [총 실제 지출액] vs [남은 잔금 총액] + 신랑/신부/공동 분담 요약 칩
/// - [+ 예산 추가] 버튼 -> 60개 마스터 템플릿 모달 연결
/// - 8대 대분류 필터링 및 고가독성 모바일 카드 UI
class WeddingBudgetSectionWidget extends ConsumerStatefulWidget {
  const WeddingBudgetSectionWidget({super.key});

  @override
  ConsumerState<WeddingBudgetSectionWidget> createState() => _WeddingBudgetSectionWidgetState();
}

class _WeddingBudgetSectionWidgetState extends ConsumerState<WeddingBudgetSectionWidget> {
  WeddingBudgetCategory? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(weddingBudgetListProvider);
    final summary = ref.watch(weddingBudgetSummaryProvider);

    final filteredItems = _selectedCategoryFilter == null
        ? items
        : items.where((i) => i.category == _selectedCategoryFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 섹션 헤더 & [+ 예산 추가] 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '결혼 예산 & 지출 정리표 (${items.length})',
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
              onPressed: () => WeddingBudgetTemplateModal.show(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('예산 추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

        // 2. 상단 예산 요약 대시보드
        // [총 예상 예산] vs [총 실제 지출액] vs [남은 잔금 총액] & 분담 요약 칩
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFED7D7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53E3E).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3단 KPI 카드
              Row(
                children: [
                  // 총 예상 예산
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '총 예상 예산',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatWon(summary.totalEstimated),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFFE2E8F0),
                  ),
                  // 총 실제 지출액
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '총 실제 지출액',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFFE53E3E), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatWon(summary.totalActual),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFFE2E8F0),
                  ),
                  // 남은 잔금 총액
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '남은 잔금 총액',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatWon(summary.remainingBalance),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // 분담 요약 칩: 신랑 총 부담금 / 신부 총 부담금 / 공동 부담금
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildShareChip(
                    label: '👦 신랑 총 부담금',
                    amount: summary.groomShare,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                  ),
                  _buildShareChip(
                    label: '👧 신부 총 부담금',
                    amount: summary.brideShare,
                    color: const Color(0xFFDB2777),
                    bg: const Color(0xFFFDF2F8),
                  ),
                  _buildShareChip(
                    label: '🤝 공동 부담금',
                    amount: summary.jointShare,
                    color: const Color(0xFF059669),
                    bg: const Color(0xFFECFDF5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. 8대 대분류 카테고리 필터
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildCategoryChip(null, '전체 (${items.length})'),
              for (final cat in WeddingBudgetCategory.values)
                _buildCategoryChip(
                  cat,
                  '${cat.emoji} ${cat.labelKo} (${items.where((i) => i.category == cat).length})',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. 세부 지출 항목 리스트 (모바일 카드 형식)
        if (filteredItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text('📝', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                const Text(
                  '등록된 예산 항목이 없습니다.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 4),
                const Text(
                  '상단의 [+ 예산 추가]를 눌러 60개 마스터 템플릿에서 담아보세요!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => WeddingBudgetTemplateModal.show(context),
                  icon: const Icon(Icons.playlist_add_rounded, size: 16),
                  label: const Text('60개 템플릿 보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in filteredItems) ...[
            _buildBudgetItemCard(context, ref, item),
          ],
      ],
    );
  }

  Widget _buildBudgetItemCard(BuildContext context, WidgetRef ref, WeddingBudgetItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 카테고리 태그 + 진행상황 뱃지 + 부담자 뱃지 + 편집/삭제
          Row(
            children: [
              // 카테고리
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.category.emoji} ${item.category.labelKo}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 6),

              // 진행 상황 뱃지 (미정 / 예약완료 / 완납)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.status.bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: item.status.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.status.color,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 부담자 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.payer.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.payer.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.payer.color,
                  ),
                ),
              ),

              const Spacer(),

              // 편집(연필) 아이콘
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '수정',
                onPressed: () => WeddingBudgetEditModal.show(context, item),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 제목
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          // 금액 그리드: [예상 예산] [계약금] [잔금] [실제 합계]
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('예상 예산', item.estimatedBudget, const Color(0xFF64748B)),
                _buildAmountColumn('계약금', item.deposit, const Color(0xFF2563EB)),
                _buildAmountColumn('남은 잔금', item.remainingBalance, const Color(0xFFE53E3E)),
                _buildAmountColumn(
                  '실제 합계',
                  item.totalActualCost,
                  const Color(0xFF0F172A),
                  isBold: true,
                ),
              ],
            ),
          ),

          // 상세 메모 (있을 경우)
          if (item.memo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📝 ', style: TextStyle(fontSize: 11)),
                Expanded(
                  child: Text(
                    item.memo,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountColumn(String label, int amount, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          _formatWon(amount),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildShareChip({
    required String label,
    required int amount,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            _formatWon(amount),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(WeddingBudgetCategory? cat, String label) {
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
            _selectedCategoryFilter = val ? cat : null;
          });
        },
      ),
    );
  }
}
