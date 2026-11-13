import 'package:flutter/material.dart';

/// 지출 담당자 (신랑 / 신부 / 공동)
enum ExpensePayer {
  groom('신랑 부담', Color(0xFF2563EB), Color(0xFFEFF6FF)),
  bride('신부 부담', Color(0xFFDB2777), Color(0xFFFDF2F8)),
  joint('공동 부담', Color(0xFF059669), Color(0xFFECFDF5));

  const ExpensePayer(this.label, this.color, this.bgColor);
  final String label;
  final Color color;
  final Color bgColor;
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

/// 예산 항목 진행 상황 (미정 / 예약완료 / 완납)
enum BudgetPaymentStatus {
  pending('미정', Color(0xFF94A3B8), Color(0xFFF1F5F9)),
  contracted('예약완료', Color(0xFF2563EB), Color(0xFFEFF6FF)),
  fullyPaid('완납', Color(0xFF059669), Color(0xFFECFDF5));

  const BudgetPaymentStatus(this.label, this.color, this.bgColor);
  final String label;
  final Color color;
  final Color bgColor;
}

/// 독립된 결혼 예산 & 지출 정리표 항목 모델
class WeddingBudgetItem {
  const WeddingBudgetItem({
    required this.id,
    required this.title,
    required this.estimatedBudget,
    this.category = WeddingBudgetCategory.hallAndMeal,
    this.deposit = 0,
    this.balance = 0,
    this.payer = ExpensePayer.joint,
    this.status = BudgetPaymentStatus.pending,
    this.isDepositPaid = false,
    this.isBalancePaid = false,
    this.memo = '',
  });

  final String id;
  final String title;
  final WeddingBudgetCategory category; // 8대 구분 카테고리
  final int estimatedBudget; // 예상 예산
  final int deposit; // 계약금 (예약금)
  final int balance; // 잔금
  final ExpensePayer payer; // 지출 담당자 (신랑/신부/공동)
  final BudgetPaymentStatus status; // 진행 상황 (미정/예약완료/완납)
  final bool isDepositPaid; // 계약금 결제 완료 여부 (하위 호환)
  final bool isBalancePaid; // 잔금 결제 완료 여부 (하위 호환)
  final String memo; // 상세 메모

  /// 총 실제 지출액 (계약금 + 잔금, 없으면 예상 예산 참조)
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
    int? estimatedBudget,
    int? deposit,
    int? balance,
    ExpensePayer? payer,
    BudgetPaymentStatus? status,
    bool? isDepositPaid,
    bool? isBalancePaid,
    String? memo,
  }) {
    return WeddingBudgetItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      deposit: deposit ?? this.deposit,
      balance: balance ?? this.balance,
      payer: payer ?? this.payer,
      status: status ?? this.status,
      isDepositPaid: isDepositPaid ?? this.isDepositPaid,
      isBalancePaid: isBalancePaid ?? this.isBalancePaid,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'estimatedBudget': estimatedBudget,
      'deposit': deposit,
      'balance': balance,
      'payer': payer.name,
      'status': status.name,
      'isDepositPaid': isDepositPaid || status != BudgetPaymentStatus.pending,
      'isBalancePaid': isBalancePaid || status == BudgetPaymentStatus.fullyPaid,
      'memo': memo,
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
    );
  }
}
