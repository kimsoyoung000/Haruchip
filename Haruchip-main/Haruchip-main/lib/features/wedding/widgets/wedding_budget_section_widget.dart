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

/// 만원 단위 축약 포맷터 (예: 40000000 -> '4,000만 원', 2500000 -> '250만 원')
String _formatManWon(int amount) {
  if (amount == 0) return '0원';
  final abs = amount.abs();
  if (abs >= 10000) {
    final man = abs ~/ 10000;
    final rem = abs % 10000;
    final manStr = man.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    if (rem == 0) return '$manStr만 원';
    final remStr = rem.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$manStr만 $remStr원';
  }
  return _formatWon(abs);
}

/// 독립된 하단 [결혼 예산 & 지출 정리표] 섹션 위젯
///
/// 1) 목표 예산 집계 요약 대시보드 (Executive Summary Card):
///    - 목표 예산 vs 실제 확정액 + 절약/초과 뱃지
///    - 지출 흐름 2분할 듀얼 가로 바 (기지불 완료 vs 남은 잔금 총액)
///    - 부담 주체별 실시간 소계 미니 칩 (신랑 | 신부 | 공동)
/// 2) 8대 대분류 필터 + 컴팩트 무테두리 모바일 엑셀 지출 카드
class WeddingBudgetSectionWidget extends ConsumerStatefulWidget {
  const WeddingBudgetSectionWidget({super.key});

  @override
  ConsumerState<WeddingBudgetSectionWidget> createState() =>
      _WeddingBudgetSectionWidgetState();
}

class _WeddingBudgetSectionWidgetState
    extends ConsumerState<WeddingBudgetSectionWidget> {
  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _chipGold = Color(0xFFF2B84B);
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  WeddingExpensePhase? _selectedPhaseFilter;
  WeddingBudgetCategory? _selectedCategoryFilter;

  Future<void> _showTargetBudgetEditSheet(
    BuildContext context,
    int currentTarget,
  ) async {
    final ctrl = TextEditingController(
      text: (currentTarget ~/ 10000).toString(),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  '총 결혼 목표 예산 설정',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _deepBrown,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('wedding_target_budget_input'),
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _deepBrown,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 4000',
                    suffixText: '만 원',
                    suffixStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C7E6A),
                    ),
                    filled: true,
                    fillColor: _softGray,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final presetMan in const [3000, 4000, 5000, 6000, 8000])
                      InkWell(
                        onTap: () => ctrl.text = presetMan.toString(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${presetMan ~/ 1000},000만',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _deepBrown,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('wedding_target_budget_save_btn'),
                    onPressed: () {
                      final man =
                          int.tryParse(ctrl.text.replaceAll(',', '').trim()) ??
                              0;
                      if (man > 0) {
                        ref
                            .read(weddingTargetBudgetProvider.notifier)
                            .setTargetBudget(man * 10000);
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _butterYellow,
                      foregroundColor: _deepBrown,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '목표 예산 저장',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(weddingBudgetListProvider);
    final summary = ref.watch(weddingBudgetSummaryProvider);

    final phaseItems = _selectedPhaseFilter == null
        ? items
        : items.where((i) => i.phase == _selectedPhaseFilter).toList();
    final filteredItems = _selectedCategoryFilter == null
        ? phaseItems
        : phaseItems
            .where((i) => i.category == _selectedCategoryFilter)
            .toList();

    final isOverBudget = summary.budgetDiff < 0;
    final totalFlow = summary.totalPaid + summary.remainingBalance;
    final paidRatio = totalFlow > 0
        ? (summary.totalPaid / totalFlow).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 섹션 컴팩트 헤더 + [예산 추가] 버터 옐로우 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text(
                    '웨딩 예산 · 지출표',
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
                      '${items.length}건',
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
              key: const Key('wedding_budget_template_add_btn'),
              onTap: () => WeddingBudgetTemplateModal.show(context),
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
        const SizedBox(height: 10),

        // 2. 목표 예산 집계 요약 대시보드 (Executive Summary Card)
        Container(
          key: const Key('wedding_executive_summary_card'),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFFBF0),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 목표 예산 (탭하여 수정) + 예산 상태 뱃지
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('wedding_target_budget_tap'),
                      onTap: () => _showTargetBudgetEditSheet(
                        context,
                        summary.targetBudget,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '목표 예산',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8C7E6A),
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: Color(0xFFB5A68E),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _formatManWon(summary.targetBudget),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _deepBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 예산 상태 뱃지 (절약 중 vs 초과)
                  Container(
                    key: const Key('wedding_budget_status_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOverBudget
                          ? '🔴 ${_formatManWon(summary.budgetDiff.abs())} 초과'
                          : '🟢 ${_formatManWon(summary.budgetDiff)} 절약 중',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isOverBudget
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF1E7B56),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 실제 확정액 대형 강조 수치
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '실제 확정액',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C7E6A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatWon(summary.totalActual),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: _deepBrown,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),

              // 지출 흐름 가로 2분할 듀얼 바 (기지불 완료 | 남은 잔금 총액)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (paidRatio > 0)
                        Flexible(
                          flex: (paidRatio * 1000).round().clamp(1, 1000),
                          child: Container(color: _chipGold),
                        ),
                      if (paidRatio < 1.0)
                        Flexible(
                          flex: ((1.0 - paidRatio) * 1000)
                              .round()
                              .clamp(1, 1000),
                          child: Container(color: const Color(0xFFFFF0C2)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _chipGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '기지불 완료 ${_formatManWon(summary.totalPaid)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _deepBrown,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _butterYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '남은 잔금 ${_formatManWon(summary.remainingBalance)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8C7E6A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 9),

              // 부담 주체별 실시간 소계 미니 텍스트 칩 (신랑 | 신부 | 공동)
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _buildMiniShareChip('신랑 부담', summary.groomShare),
                  _buildMiniShareChip('신부 부담', summary.brideShare),
                  _buildMiniShareChip('공동 부담', summary.jointShare),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),

        // 3. 지출 시점 3단 탭 ([전체] | [본식 전 준비 지출] | [본식 당일/사후 정산])
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F1EA),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              _buildPhaseTab(
                key: const Key('wedding_budget_phase_all'),
                phase: null,
                label: '전체 (${items.length})',
              ),
              _buildPhaseTab(
                key: const Key('wedding_budget_phase_preWedding'),
                phase: WeddingExpensePhase.preWedding,
                label: '본식 전 준비 지출',
              ),
              _buildPhaseTab(
                key: const Key('wedding_budget_phase_postWedding'),
                phase: WeddingExpensePhase.postWedding,
                label: '본식 당일/사후 정산',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 4. 8대 대분류 필터 칩 (무테두리 컴팩트 핏)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildCategoryChip(null, '전체 (${phaseItems.length})'),
              for (final cat in WeddingBudgetCategory.values)
                _buildCategoryChip(
                  cat,
                  '${cat.labelKo} (${phaseItems.where((i) => i.category == cat).length})',
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. 세부 지출 항목 리스트 (컴팩트 모바일 엑셀 카드)
        if (filteredItems.isEmpty)
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
              '등록된 예산 항목이 없습니다. 상단 [예산 추가]에서 담아보세요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          )
        else
          for (final item in filteredItems)
            _buildBudgetItemCard(context, item),
      ],
    );
  }

  Widget _buildBudgetItemCard(BuildContext context, WeddingBudgetItem item) {
    String? dueBadge;
    if (item.balanceDueDate != null &&
        item.status != BudgetPaymentStatus.fullyPaid) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(
        item.balanceDueDate!.year,
        item.balanceDueDate!.month,
        item.balanceDueDate!.day,
      );
      final diff = due.difference(today).inDays;
      dueBadge = diff == 0
          ? '잔금 D-Day'
          : (diff > 0 ? '잔금 D-$diff' : '잔금 D+${diff.abs()}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          key: Key('wedding_budget_card_${item.id}'),
          onTap: () => WeddingBudgetEditModal.show(context, item),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1줄: 제목 + 진행상태 + 부담자 + 잔금 D-Day
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _deepBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.status.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: item.status.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.payer.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.payer.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: item.payer.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // 2줄: 결제 수단 · 할부 · 현금영수증 · 잔금 예정일 메타 태그
                Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  children: [
                    Text(
                      item.category.labelKo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    Text(
                      '· ${item.paymentMethod.labelKo}(${item.installmentLabel})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8C7E6A),
                      ),
                    ),
                    if (item.cashReceiptIssued)
                      const Text(
                        '· 현금영수증',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A6216),
                        ),
                      ),
                    if (dueBadge != null)
                      Text(
                        '· $dueBadge',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _deepBrown,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),

                // 3줄: 컴팩트 3단 금액 그리드 (총 견적 | 계약금 | 남은 잔금)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _softGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAmountColumn(
                          '총 견적',
                          item.estimatedBudget,
                          const Color(0xFF6B7280),
                        ),
                      ),
                      Expanded(
                        child: _buildAmountColumn(
                          '계약금',
                          item.deposit,
                          const Color(0xFF8A6216),
                        ),
                      ),
                      Expanded(
                        child: _buildAmountColumn(
                          '남은 잔금',
                          item.remainingBalance,
                          _deepBrown,
                          isBold: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn(
    String label,
    int amount,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _formatWon(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniShareChip(String label, int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${_formatManWon(amount)}',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: _deepBrown,
        ),
      ),
    );
  }

  Widget _buildPhaseTab({
    required Key key,
    required WeddingExpensePhase? phase,
    required String label,
  }) {
    final isSelected = _selectedPhaseFilter == phase;
    return Expanded(
      child: InkWell(
        key: key,
        onTap: () => setState(() => _selectedPhaseFilter = phase),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.5, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _butterYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _deepBrown : const Color(0xFF8C7E6A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(WeddingBudgetCategory? cat, String label) {
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
            color: isSelected ? _butterYellow : Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
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
