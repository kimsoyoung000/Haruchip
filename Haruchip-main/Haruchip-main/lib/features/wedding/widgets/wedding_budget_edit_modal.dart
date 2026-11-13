import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_budget_item.dart';
import '../providers/wedding_budget_provider.dart';

/// 결혼 예산 항목 추가/수정 바텀시트 모달
/// 세부 입력 필드 8종:
/// 1) 구분 카테고리 (8대 카테고리)
/// 2) 항목명
/// 3) 예상 예산
/// 4) 계약금(예약금)
/// 5) 잔금
/// 6) 신랑/신부/공동 부담 선택
/// 7) 진행 상황(미정/예약완료/완납)
/// 8) 상세 메모
class WeddingBudgetEditModal extends ConsumerStatefulWidget {
  const WeddingBudgetEditModal({super.key, this.item});

  final WeddingBudgetItem? item;

  static Future<void> show(BuildContext context, [WeddingBudgetItem? item]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeddingBudgetEditModal(item: item),
    );
  }

  @override
  ConsumerState<WeddingBudgetEditModal> createState() => _WeddingBudgetEditModalState();
}

class _WeddingBudgetEditModalState extends ConsumerState<WeddingBudgetEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _estimatedController;
  late final TextEditingController _depositController;
  late final TextEditingController _balanceController;
  late final TextEditingController _memoController;

  late WeddingBudgetCategory _selectedCategory;
  late ExpensePayer _selectedPayer;
  late BudgetPaymentStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _estimatedController = TextEditingController(
      text: item != null && item.estimatedBudget > 0 ? item.estimatedBudget.toString() : '',
    );
    _depositController = TextEditingController(
      text: item != null && item.deposit > 0 ? item.deposit.toString() : '',
    );
    _balanceController = TextEditingController(
      text: item != null && item.balance > 0 ? item.balance.toString() : '',
    );
    _memoController = TextEditingController(text: item?.memo ?? '');

    _selectedCategory = item?.category ?? WeddingBudgetCategory.hallAndMeal;
    _selectedPayer = item?.payer ?? ExpensePayer.joint;
    _selectedStatus = item?.status ?? BudgetPaymentStatus.pending;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _estimatedController.dispose();
    _depositController.dispose();
    _balanceController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('항목명을 입력해주세요.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final estimated = int.tryParse(_estimatedController.text.replaceAll(',', '').trim()) ?? 0;
    final deposit = int.tryParse(_depositController.text.replaceAll(',', '').trim()) ?? 0;
    final balance = int.tryParse(_balanceController.text.replaceAll(',', '').trim()) ?? 0;

    final isDepositPaid = _selectedStatus == BudgetPaymentStatus.contracted ||
        _selectedStatus == BudgetPaymentStatus.fullyPaid;
    final isBalancePaid = _selectedStatus == BudgetPaymentStatus.fullyPaid;

    if (widget.item != null) {
      final updated = widget.item!.copyWith(
        title: title,
        category: _selectedCategory,
        estimatedBudget: estimated,
        deposit: deposit,
        balance: balance,
        payer: _selectedPayer,
        status: _selectedStatus,
        isDepositPaid: isDepositPaid,
        isBalancePaid: isBalancePaid,
        memo: _memoController.text.trim(),
      );
      ref.read(weddingBudgetListProvider.notifier).updateItem(updated);
    } else {
      final newItem = WeddingBudgetItem(
        id: 'budget-custom-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        category: _selectedCategory,
        estimatedBudget: estimated,
        deposit: deposit,
        balance: balance,
        payer: _selectedPayer,
        status: _selectedStatus,
        isDepositPaid: isDepositPaid,
        isBalancePaid: isBalancePaid,
        memo: _memoController.text.trim(),
      );
      ref.read(weddingBudgetListProvider.notifier).addItem(newItem);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.item != null ? '예산 항목이 수정되었습니다.' : '새 예산 항목이 추가되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _delete() {
    if (widget.item == null) return;
    ref.read(weddingBudgetListProvider.notifier).removeItem(widget.item!.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예산 항목이 삭제되었습니다.'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // 드래그 바 및 상단 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 12),
            child: Column(
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
                    Text(
                      isEditing ? '예산 항목 수정' : '예산 항목 직접 추가',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 폼 입력 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 구분 카테고리
                  const Text(
                    '1. 구분 카테고리',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final cat in WeddingBudgetCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${cat.emoji} ${cat.labelKo}'),
                              selected: _selectedCategory == cat,
                              selectedColor: const Color(0xFFE53E3E),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedCategory == cat ? Colors.white : const Color(0xFF475569),
                              ),
                              showCheckmark: false,
                              onSelected: (val) {
                                if (val) setState(() => _selectedCategory = cat);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. 항목명
                  const Text(
                    '2. 항목명',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '예: 본식 스냅 & 원판 촬영',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. 예상 예산
                  const Text(
                    '3. 예상 예산 (원)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _estimatedController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '예: 25000000',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.calculate_outlined, size: 20, color: Color(0xFF94A3B8)),
                      suffixText: '원',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 & 5. 계약금(예약금) 및 잔금
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '4. 계약금(예약금)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _depositController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '예: 3000000',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                suffixText: '원',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '5. 잔금',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _balanceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '예: 22000000',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                suffixText: '원',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. 신랑/신부/공동 부담 선택
                  const Text(
                    '6. 부담 구분',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final p in ExpensePayer.values) ...[
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPayer = p),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedPayer == p ? p.bgColor : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPayer == p ? p.color : const Color(0xFFE2E8F0),
                                  width: _selectedPayer == p ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPayer == p ? p.color : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (p != ExpensePayer.values.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 7. 진행 상황 (미정 / 예약완료 / 완납)
                  const Text(
                    '7. 진행 상황',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final st in BudgetPaymentStatus.values) ...[
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedStatus = st),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedStatus == st ? st.bgColor : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedStatus == st ? st.color : const Color(0xFFE2E8F0),
                                  width: _selectedStatus == st ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                st.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedStatus == st ? st.color : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (st != BudgetPaymentStatus.values.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 8. 상세 메모
                  const Text(
                    '8. 상세 메모',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _memoController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '계약 조건, 특약 사항, 현금 영수증 여부 등 상세 메모',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 하단 저장 및 삭제 버튼
                  Row(
                    children: [
                      if (isEditing) ...[
                        OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE53E3E),
                            side: const BorderSide(color: Color(0xFFFECDD3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          ),
                          child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isEditing ? '수정 내용 저장' : '예산표에 추가하기',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
