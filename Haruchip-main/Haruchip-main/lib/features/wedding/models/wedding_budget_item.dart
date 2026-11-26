import 'package:flutter/material.dart';

/// 지출 담당자 (신랑 / 신부 / 공동) — 차분한 하루칩 파스텔 럭셔리 톤
enum ExpensePayer {
  groom('신랑', Color(0xFF5B4A35), Color(0xFFF3EFE8)),
  bride('신부', Color(0xFF7A5643), Color(0xFFFAF1EC)),
  joint('공동', Color(0xFF3A2E1A), Color(0xFFFFF4CC));

  const ExpensePayer(this.label, this.color, this.bgColor);
  final String label;
  final Color color;
  final Color bgColor;
}

/// 결제 수단 (신용카드 / 체크카드 / 계좌이체 / 현금)
enum WeddingPaymentMethod {
  creditCard('신용카드'),
  debitCard('체크카드'),
  bankTransfer('계좌이체'),
  cash('현금');

  const WeddingPaymentMethod(this.labelKo);
  final String labelKo;

  static WeddingPaymentMethod fromName(String? raw) {
    return WeddingPaymentMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => WeddingPaymentMethod.creditCard,
    );
  }
}

/// 결혼 예산 8대 대분류 카테고리
enum WeddingBudgetCategory {
  greeting('상견례 & 인사', '👨‍👩‍👦', 1),
  hallAndMeal('웨딩홀 & 식대', '🏛️', 2),
  studioShoot('스튜디오 & 스냅', '📸', 3),
  dressAndSuit('드레스 & 예복', '👗', 4),
  hairAndBeauty('헤어 & 메이크업', '💄', 5),
  ceremonyDirecting('본식 연출 & 영상', '🎬', 6),
  homeAndAppliances('혼수 & 가전/가구', '🛋️', 7),
  giftsAndFavors('예물 & 예단/답례', '🎁', 8);

  const WeddingBudgetCategory(this.labelKo, this.emoji, this.order);
  final String labelKo;
  final String emoji;
  final int order;
}

/// 예산 항목 진행 상황 (미정 / 예약완료 / 완납) — 차분한 하루칩 뉴트럴/골드 톤
enum BudgetPaymentStatus {
  pending('미정', Color(0xFF8C7E6A), Color(0xFFF3F4F6)),
  contracted('예약완료', Color(0xFF8A6216), Color(0xFFFFF6D6)),
  fullyPaid('완납', Color(0xFF2E6B3E), Color(0xFFEBF7EE));

  const BudgetPaymentStatus(this.label, this.color, this.bgColor);
  final String label;
  final Color color;
  final Color bgColor;
}

/// 지출 시점 구분 (본식 전 준비 지출 / 본식 당일·사후 정산)
enum WeddingExpensePhase {
  preWedding('본식 전 준비 지출'),
  postWedding('본식 당일/사후 정산');

  const WeddingExpensePhase(this.labelKo);
  final String labelKo;

  static WeddingExpensePhase fromName(String? raw) {
    return WeddingExpensePhase.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => WeddingExpensePhase.preWedding,
    );
  }
}

/// 독립된 결혼 예산 & 지출 정리표 항목 모델 (모바일 엑셀 스마트 엔트리 + 사후 정산 통합)
class WeddingBudgetItem {
  const WeddingBudgetItem({
    required this.id,
    required this.title,
    required this.estimatedBudget,
    this.category = WeddingBudgetCategory.hallAndMeal,
    this.phase = WeddingExpensePhase.preWedding,
    this.deposit = 0,
    this.balance = 0,
    this.payer = ExpensePayer.joint,
    this.status = BudgetPaymentStatus.pending,
    this.isDepositPaid = false,
    this.isBalancePaid = false,
    this.memo = '',
    this.balanceDueDate,
    this.syncedBalancePlanId,
    this.paymentMethod = WeddingPaymentMethod.creditCard,
    this.installmentMonths = 0,
    this.cashReceiptIssued = false,
  });

  final String id;
  final String title;
  final WeddingBudgetCategory category; // 8대 구분 카테고리
  final WeddingExpensePhase phase; // 본식 전 준비 지출 vs 본식 당일/사후 정산
  final int estimatedBudget; // 총 견적 금액 (예상 예산)
  final int deposit; // 계약금 (이미 낸 돈)
  final int balance; // 남은 잔금
  final ExpensePayer payer; // 지출 담당자 (신랑/신부/공동)
  final BudgetPaymentStatus status; // 진행 상황 (미정/예약완료/완납)
  final bool isDepositPaid; // 계약금 결제 완료 여부 (하위 호환)
  final bool isBalancePaid; // 잔금 결제 완료 여부 (하위 호환)
  final String memo; // 상세 메모
  final DateTime? balanceDueDate; // 잔금 결제 예정일 (캘린더/D-Day 자동 연동)
  final String? syncedBalancePlanId; // 캘린더 동기화 플랜 ID
  final WeddingPaymentMethod paymentMethod; // 결제 수단
  final int installmentMonths; // 할부 개월 수 (0 = 일시불)
  final bool cashReceiptIssued; // 현금영수증 발행 여부

  /// 할부 라벨 ('일시불' | '3개월' | '6개월' | '12개월' 등)
  String get installmentLabel =>
      installmentMonths <= 0 ? '일시불' : '$installmentMonths개월 할부';

  /// 총 실제 확정액 (계약금 + 잔금, 없으면 예상 예산 참조)
  int get totalActualCost {
    final contractTotal = deposit + balance;
    if (contractTotal > 0) return contractTotal;
    if (status == BudgetPaymentStatus.fullyPaid) return estimatedBudget;
    return 0;
  }

  /// 남은 잔금 총액
  int get remainingBalance {
    if (status == BudgetPaymentStatus.fullyPaid || isBalancePaid) {
      return 0;
    }
    if (balance > 0) {
      return balance;
    }
    if (status == BudgetPaymentStatus.contracted && estimatedBudget > deposit) {
      return estimatedBudget - deposit;
    }
    return 0;
  }

  /// 현재까지 실제 결제/지출 완료된 금액
  int get paidAmount {
    if (status == BudgetPaymentStatus.fullyPaid || (isDepositPaid && isBalancePaid)) {
      return deposit + balance > 0 ? deposit + balance : estimatedBudget;
    }
    if (status == BudgetPaymentStatus.contracted || isDepositPaid) {
      return deposit;
    }
    return 0;
  }

  WeddingBudgetItem copyWith({
    String? id,
    String? title,
    WeddingBudgetCategory? category,
    WeddingExpensePhase? phase,
    int? estimatedBudget,
    int? deposit,
    int? balance,
    ExpensePayer? payer,
    BudgetPaymentStatus? status,
    bool? isDepositPaid,
    bool? isBalancePaid,
    String? memo,
    DateTime? balanceDueDate,
    bool clearBalanceDueDate = false,
    String? syncedBalancePlanId,
    bool clearSyncedBalancePlanId = false,
    WeddingPaymentMethod? paymentMethod,
    int? installmentMonths,
    bool? cashReceiptIssued,
  }) {
    return WeddingBudgetItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      phase: phase ?? this.phase,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      deposit: deposit ?? this.deposit,
      balance: balance ?? this.balance,
      payer: payer ?? this.payer,
      status: status ?? this.status,
      isDepositPaid: isDepositPaid ?? this.isDepositPaid,
      isBalancePaid: isBalancePaid ?? this.isBalancePaid,
      memo: memo ?? this.memo,
      balanceDueDate:
          clearBalanceDueDate ? null : (balanceDueDate ?? this.balanceDueDate),
      syncedBalancePlanId: clearSyncedBalancePlanId
          ? null
          : (syncedBalancePlanId ?? this.syncedBalancePlanId),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      cashReceiptIssued: cashReceiptIssued ?? this.cashReceiptIssued,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'phase': phase.name,
      'estimatedBudget': estimatedBudget,
      'deposit': deposit,
      'balance': balance,
      'payer': payer.name,
      'status': status.name,
      'isDepositPaid': isDepositPaid || status != BudgetPaymentStatus.pending,
      'isBalancePaid': isBalancePaid || status == BudgetPaymentStatus.fullyPaid,
      'memo': memo,
      if (balanceDueDate != null)
        'balanceDueDate': balanceDueDate!.toIso8601String(),
      if (syncedBalancePlanId != null)
        'syncedBalancePlanId': syncedBalancePlanId,
      'paymentMethod': paymentMethod.name,
      'installmentMonths': installmentMonths,
      'cashReceiptIssued': cashReceiptIssued,
    };
  }

  factory WeddingBudgetItem.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final isDepPaid = json['isDepositPaid'] as bool? ?? false;
    final isBalPaid = json['isBalancePaid'] as bool? ?? false;

    BudgetPaymentStatus resolvedStatus;
    if (statusName != null) {
      resolvedStatus = BudgetPaymentStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => BudgetPaymentStatus.pending,
      );
    } else if (isBalPaid) {
      resolvedStatus = BudgetPaymentStatus.fullyPaid;
    } else if (isDepPaid) {
      resolvedStatus = BudgetPaymentStatus.contracted;
    } else {
      resolvedStatus = BudgetPaymentStatus.pending;
    }

    return WeddingBudgetItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: WeddingBudgetCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => WeddingBudgetCategory.hallAndMeal,
      ),
      phase: WeddingExpensePhase.fromName(json['phase'] as String?),
      estimatedBudget: json['estimatedBudget'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,
      balance: json['balance'] as int? ?? 0,
      payer: ExpensePayer.values.firstWhere(
        (p) => p.name == json['payer'],
        orElse: () => ExpensePayer.joint,
      ),
      status: resolvedStatus,
      isDepositPaid: isDepPaid,
      isBalancePaid: isBalPaid,
      memo: json['memo'] as String? ?? '',
      balanceDueDate: json['balanceDueDate'] != null
          ? DateTime.tryParse(json['balanceDueDate'] as String)
          : null,
      syncedBalancePlanId: json['syncedBalancePlanId'] as String?,
      paymentMethod:
          WeddingPaymentMethod.fromName(json['paymentMethod'] as String?),
      installmentMonths: json['installmentMonths'] as int? ?? 0,
      cashReceiptIssued: json['cashReceiptIssued'] as bool? ?? false,
    );
  }
}
