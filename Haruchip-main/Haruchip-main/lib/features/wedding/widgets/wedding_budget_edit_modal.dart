import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/wedding_budget_item.dart';
import '../providers/wedding_budget_provider.dart';

/// 스마트 지출 상세 관리 바텀시트 (모바일 엑셀 데이터 엔트리)
///
/// 1) 기본 정보: 항목명, 8대 분류 선택
/// 2) 금액 분할 입력: [총 견적 금액] + [계약금] -> [남은 잔금] 실시간 자동 계산 + [잔금 결제 예정일](캘린더/D-Day 연동)
/// 3) 결제 수단 및 혜택 관리: [신용카드/체크카드/계좌이체/현금], 할부(일시불/3/6/12개월), 현금영수증 토글
/// 4) 정산 주체([공동/신랑/신부]) + 진행 상황([미정/예약완료/완납]) + 상세 메모
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
  ConsumerState<WeddingBudgetEditModal> createState() =>
      _WeddingBudgetEditModalState();
}

class _WeddingBudgetEditModalState
    extends ConsumerState<WeddingBudgetEditModal> {
  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  late final TextEditingController _titleController;
  late final TextEditingController _estimatedController;
  late final TextEditingController _depositController;
  late final TextEditingController _balanceController;
  late final TextEditingController _memoController;

  late WeddingBudgetCategory _selectedCategory;
  late WeddingExpensePhase _selectedPhase;
  late ExpensePayer _selectedPayer;
  late BudgetPaymentStatus _selectedStatus;
  late WeddingPaymentMethod _paymentMethod;
  late int _installmentMonths;
  late bool _cashReceiptIssued;
  DateTime? _balanceDueDate;

  bool _balanceManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _estimatedController = TextEditingController(
      text: item != null && item.estimatedBudget > 0
          ? item.estimatedBudget.toString()
          : '',
    );
    _depositController = TextEditingController(
      text: item != null && item.deposit > 0 ? item.deposit.toString() : '',
    );
    _balanceController = TextEditingController(
      text: item != null && item.balance > 0 ? item.balance.toString() : '',
    );
    _memoController = TextEditingController(text: item?.memo ?? '');

    _selectedCategory = item?.category ?? WeddingBudgetCategory.hallAndMeal;
    _selectedPhase = item?.phase ?? WeddingExpensePhase.preWedding;
    _selectedPayer = item?.payer ?? ExpensePayer.joint;
    _selectedStatus = item?.status ?? BudgetPaymentStatus.contracted;
    _paymentMethod = item?.paymentMethod ?? WeddingPaymentMethod.creditCard;
    _installmentMonths = item?.installmentMonths ?? 0;
    _cashReceiptIssued = item?.cashReceiptIssued ?? false;
    _balanceDueDate = item?.balanceDueDate;
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

  int _parseAmount(String raw) =>
      int.tryParse(raw.replaceAll(',', '').trim()) ?? 0;

  /// 총 견적 또는 계약금 변경 시 남은 잔금(총액 - 계약금) 자동 계산
  void _recalculateBalance() {
    if (_balanceManuallyEdited) return;
    final total = _parseAmount(_estimatedController.text);
    final deposit = _parseAmount(_depositController.text);
    final autoBalance = (total - deposit).clamp(0, 9999999999);
    _balanceController.text = autoBalance > 0 ? autoBalance.toString() : '0';
    setState(() {});
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBalanceDueDate() async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: _balanceDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null && mounted) {
      setState(() => _balanceDueDate = picked);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('항목명을 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final estimated = _parseAmount(_estimatedController.text);
    final deposit = _parseAmount(_depositController.text);
    final balance = _parseAmount(_balanceController.text);

    final isDepositPaid = _selectedStatus == BudgetPaymentStatus.contracted ||
        _selectedStatus == BudgetPaymentStatus.fullyPaid;
    final isBalancePaid = _selectedStatus == BudgetPaymentStatus.fullyPaid;

    if (widget.item != null) {
      final updated = widget.item!.copyWith(
        title: title,
        category: _selectedCategory,
        phase: _selectedPhase,
        estimatedBudget: estimated,
        deposit: deposit,
        balance: balance,
        payer: _selectedPayer,
        status: _selectedStatus,
        isDepositPaid: isDepositPaid,
        isBalancePaid: isBalancePaid,
        memo: _memoController.text.trim(),
        balanceDueDate: _balanceDueDate,
        clearBalanceDueDate: _balanceDueDate == null,
        paymentMethod: _paymentMethod,
        installmentMonths: _installmentMonths,
        cashReceiptIssued: _cashReceiptIssued,
      );
      ref.read(weddingBudgetListProvider.notifier).updateItem(updated);
    } else {
      final newItem = WeddingBudgetItem(
        id: 'budget-custom-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        category: _selectedCategory,
        phase: _selectedPhase,
        estimatedBudget: estimated,
        deposit: deposit,
        balance: balance,
        payer: _selectedPayer,
        status: _selectedStatus,
        isDepositPaid: isDepositPaid,
        isBalancePaid: isBalancePaid,
        memo: _memoController.text.trim(),
        balanceDueDate: _balanceDueDate,
        paymentMethod: _paymentMethod,
        installmentMonths: _installmentMonths,
        cashReceiptIssued: _cashReceiptIssued,
      );
      ref.read(weddingBudgetListProvider.notifier).addItem(newItem);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.item != null ? '지출 항목이 수정되었습니다.' : '새 지출 항목이 추가되었습니다.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _delete() {
    if (widget.item == null) return;
    ref.read(weddingBudgetListProvider.notifier).removeItem(widget.item!.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('지출 항목이 삭제되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // 컴팩트 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 14, 8),
            child: Column(
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
                    Text(
                      isEditing ? '지출 상세 수정' : '새 지출 상세 입력',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _deepBrown,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
          ),
          const Divider(height: 1, color: Color(0xFFF1F1EE)),

          // 본문 폼
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 0. 지출 시점 (본식 전 준비 지출 / 본식 당일·사후 정산)
                  _buildLabel('지출 시점'),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final ph in WeddingExpensePhase.values) ...[
                        Expanded(
                          child: InkWell(
                            key: Key('wedding_budget_edit_phase_${ph.name}'),
                            onTap: () => setState(() => _selectedPhase = ph),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedPhase == ph
                                    ? _butterYellow
                                    : _softGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ph.labelKo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedPhase == ph
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _selectedPhase == ph
                                      ? _deepBrown
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (ph != WeddingExpensePhase.values.last)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 11),

                  // 1. 기본 정보: 분류 + 항목명
                  _buildLabel('분류'),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final cat in WeddingBudgetCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => setState(() => _selectedCategory = cat),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedCategory == cat
                                      ? _butterYellow
                                      : _softGray,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  cat.labelKo,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _selectedCategory == cat
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _selectedCategory == cat
                                        ? _deepBrown
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  _buildLabel('항목명'),
                  const SizedBox(height: 4),
                  TextField(
                    key: const Key('wedding_budget_title_input'),
                    controller: _titleController,
                    style: const TextStyle(fontSize: 13.5, color: _deepBrown),
                    decoration: _inputDecoration('예: 웨딩홀 대관료, 스튜디오 잔금'),
                  ),
                  const SizedBox(height: 12),

                  // 2. 금액 분할 입력: 총 견적 + 계약금 -> 남은 잔금 자동 계산
                  _buildLabel('총 견적 금액'),
                  const SizedBox(height: 4),
                  TextField(
                    key: const Key('wedding_budget_total_input'),
                    controller: _estimatedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _deepBrown,
                    ),
                    onChanged: (_) => _recalculateBalance(),
                    decoration: _inputDecoration('예: 25000000', suffixText: '원'),
                  ),
                  const SizedBox(height: 9),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('계약금 (이미 낸 돈)'),
                            const SizedBox(height: 4),
                            TextField(
                              key: const Key('wedding_budget_deposit_input'),
                              controller: _depositController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _deepBrown,
                              ),
                              onChanged: (_) => _recalculateBalance(),
                              decoration: _inputDecoration(
                                '예: 3000000',
                                suffixText: '원',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('남은 잔금 (자동 계산)'),
                            const SizedBox(height: 4),
                            TextField(
                              key: const Key('wedding_budget_balance_input'),
                              controller: _balanceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _deepBrown,
                              ),
                              onChanged: (_) => _balanceManuallyEdited = true,
                              decoration: _inputDecoration(
                                '자동 계산',
                                suffixText: '원',
                                fillColor: const Color(0xFFFFFBF0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),

                  // 잔금 결제 예정일 (캘린더/D-Day 자동 연동)
                  _buildLabel('잔금 결제 예정일 (캘린더 · D-Day 자동 등록)'),
                  const SizedBox(height: 4),
                  InkWell(
                    key: const Key('wedding_budget_due_date_picker'),
                    onTap: _pickBalanceDueDate,
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _softGray,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: Color(0xFF8C7E6A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _balanceDueDate != null
                                  ? _fmtDate(_balanceDueDate!)
                                  : '예정일 선택 안 함',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _balanceDueDate != null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _balanceDueDate != null
                                    ? _deepBrown
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          if (_balanceDueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _balanceDueDate = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. 결제 수단 및 혜택 관리
                  _buildLabel('결제 수단'),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final m in WeddingPaymentMethod.values) ...[
                        Expanded(
                          child: InkWell(
                            key: Key('wedding_payment_method_${m.name}'),
                            onTap: () => setState(() {
                              _paymentMethod = m;
                              if (m != WeddingPaymentMethod.creditCard) {
                                _installmentMonths = 0;
                              }
                            }),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _paymentMethod == m
                                    ? _butterYellow
                                    : _softGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                m.labelKo,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _paymentMethod == m
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _paymentMethod == m
                                      ? _deepBrown
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (m != WeddingPaymentMethod.values.last)
                          const SizedBox(width: 5),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),

                  // 할부 정보
                  _buildLabel('할부 정보'),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final months in const [0, 3, 6, 12]) ...[
                        Expanded(
                          child: InkWell(
                            key: Key('wedding_installment_$months'),
                            onTap: () =>
                                setState(() => _installmentMonths = months),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 7.5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _installmentMonths == months
                                    ? _butterYellow
                                    : _softGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                months == 0 ? '일시불' : '$months개월',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _installmentMonths == months
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _installmentMonths == months
                                      ? _deepBrown
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (months != 12) const SizedBox(width: 5),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),

                  // 현금영수증 발행 여부 토글
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _softGray,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '현금영수증 발행 여부',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _deepBrown,
                          ),
                        ),
                        Switch.adaptive(
                          key: const Key('wedding_cash_receipt_switch'),
                          value: _cashReceiptIssued,
                          activeTrackColor: _butterYellow,
                          activeThumbColor: _deepBrown,
                          onChanged: (v) =>
                              setState(() => _cashReceiptIssued = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. 정산 주체 ([공동] / [신랑] / [신부])
                  _buildLabel('정산 주체'),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final p in const [
                        ExpensePayer.joint,
                        ExpensePayer.groom,
                        ExpensePayer.bride,
                      ]) ...[
                        Expanded(
                          child: InkWell(
                            key: Key('wedding_payer_${p.name}'),
                            onTap: () => setState(() => _selectedPayer = p),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedPayer == p
                                    ? _butterYellow
                                    : _softGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _selectedPayer == p
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _selectedPayer == p
                                      ? _deepBrown
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (p != ExpensePayer.bride) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 진행 상황 (미정 / 예약완료 / 완납)
                  _buildLabel('진행 상황'),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final st in BudgetPaymentStatus.values) ...[
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedStatus = st),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedStatus == st
                                    ? _butterYellow
                                    : _softGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                st.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedStatus == st
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _selectedStatus == st
                                      ? _deepBrown
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (st != BudgetPaymentStatus.values.last)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 상세 메모
                  _buildLabel('상세 메모'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _memoController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, color: _deepBrown),
                    decoration: _inputDecoration('계약 조건, 특약 사항, 담당자 메모'),
                  ),
                  const SizedBox(height: 16),

                  // 하단 저장 / 삭제 버튼
                  Row(
                    children: [
                      if (isEditing) ...[
                        TextButton(
                          onPressed: _delete,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9CA3AF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            '삭제',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            key: const Key('wedding_budget_save_btn'),
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _butterYellow,
                              foregroundColor: _deepBrown,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isEditing ? '수정 내용 저장' : '지출표에 추가하기',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8C7E6A),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    String? suffixText,
    Color fillColor = _softGray,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8C7E6A),
      ),
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
    );
  }
}
