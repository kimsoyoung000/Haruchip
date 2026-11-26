import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/local_store.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../data/wedding_budget_master_items.dart';
import '../models/wedding_budget_item.dart';

const String _kWeddingTargetBudgetKey = 'haruchip.wedding.target_budget.v1';
const int kDefaultWeddingTargetBudget = 40000000; // 기본 목표 예산 4,000만 원

/// 사용자가 설정한 총 결혼 목표 예산 Notifier (로컬 영속화)
class WeddingTargetBudgetNotifier extends Notifier<int> {
  @override
  int build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) {
      store.writeString(_kWeddingTargetBudgetKey, next.toString());
    });
    final raw = store.readString(_kWeddingTargetBudgetKey);
    final parsed = raw != null ? int.tryParse(raw) : null;
    return (parsed != null && parsed > 0) ? parsed : kDefaultWeddingTargetBudget;
  }

  void setTargetBudget(int amount) {
    if (amount >= 0) {
      state = amount;
    }
  }
}

final weddingTargetBudgetProvider =
    NotifierProvider<WeddingTargetBudgetNotifier, int>(
  WeddingTargetBudgetNotifier.new,
);

/// 표준 한국 결혼 예산 기본 초기 템플릿 항목
List<WeddingBudgetItem> createDefaultWeddingBudgetItems() {
  return [
    const WeddingBudgetItem(
      id: 'budget-1',
      title: '웨딩홀 대관료 & 식대',
      category: WeddingBudgetCategory.hallAndMeal,
      estimatedBudget: 25000000,
      deposit: 3000000,
      balance: 22000000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.bankTransfer,
      memo: '식대 350명 보증 인원 기준',
    ),
    const WeddingBudgetItem(
      id: 'budget-2',
      title: '스드메 패키지 (스튜디오+드레스+메이크업)',
      category: WeddingBudgetCategory.studioShoot,
      estimatedBudget: 3800000,
      deposit: 800000,
      balance: 3000000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.creditCard,
      installmentMonths: 3,
      memo: '스튜디오 원본/수정본 별도',
    ),
    const WeddingBudgetItem(
      id: 'budget-3',
      title: '본식 스냅 & DVD 영상',
      category: WeddingBudgetCategory.ceremonyDirecting,
      estimatedBudget: 1900000,
      deposit: 400000,
      balance: 1500000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.bankTransfer,
      cashReceiptIssued: true,
      memo: '1인 2캠 4K 촬영',
    ),
    const WeddingBudgetItem(
      id: 'budget-4',
      title: '웨딩 밴드 (결혼반지)',
      category: WeddingBudgetCategory.giftsAndFavors,
      estimatedBudget: 3200000,
      deposit: 1200000,
      balance: 2000000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.creditCard,
      installmentMonths: 6,
      memo: '백화점 브랜드 투어 및 각인 서비스',
    ),
    const WeddingBudgetItem(
      id: 'budget-5',
      title: '신랑 맞춤 예복 & 수제화',
      category: WeddingBudgetCategory.dressAndSuit,
      estimatedBudget: 1600000,
      deposit: 500000,
      balance: 1100000,
      payer: ExpensePayer.bride,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.creditCard,
      memo: '이태리 원단 맞춤 정장',
    ),
    const WeddingBudgetItem(
      id: 'budget-6',
      title: '신혼여행 (항공편 + 숙소 + 경비)',
      category: WeddingBudgetCategory.greeting,
      estimatedBudget: 8000000,
      deposit: 3500000,
      balance: 4500000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.creditCard,
      installmentMonths: 6,
      memo: '발리 풀빌라 5박 7일',
    ),
    const WeddingBudgetItem(
      id: 'budget-7',
      title: '혼주 한복 대여 및 헤어/메이크업',
      category: WeddingBudgetCategory.hairAndBeauty,
      estimatedBudget: 1400000,
      deposit: 300000,
      balance: 1100000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.contracted,
      isDepositPaid: true,
      paymentMethod: WeddingPaymentMethod.debitCard,
      memo: '양가 어머님 한복 대여',
    ),
    const WeddingBudgetItem(
      id: 'budget-8',
      title: '종이 청첩장 & 모바일 청첩장',
      category: WeddingBudgetCategory.giftsAndFavors,
      estimatedBudget: 350000,
      deposit: 350000,
      balance: 0,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.fullyPaid,
      isDepositPaid: true,
      isBalancePaid: true,
      paymentMethod: WeddingPaymentMethod.creditCard,
      memo: '종이 300장 + 모바일 무제한',
    ),
    const WeddingBudgetItem(
      id: 'budget-9',
      title: '사회자 · 축가 · 헬퍼 이모님 수고비',
      category: WeddingBudgetCategory.ceremonyDirecting,
      phase: WeddingExpensePhase.postWedding,
      estimatedBudget: 1100000,
      deposit: 0,
      balance: 1100000,
      payer: ExpensePayer.groom,
      status: BudgetPaymentStatus.pending,
      paymentMethod: WeddingPaymentMethod.cash,
      memo: '당일 현금 봉투 준비 (부케·가방순이 포함)',
    ),
    const WeddingBudgetItem(
      id: 'budget-10',
      title: '지방 하객 차비(교통비) 정산',
      category: WeddingBudgetCategory.greeting,
      phase: WeddingExpensePhase.postWedding,
      estimatedBudget: 500000,
      deposit: 0,
      balance: 500000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.pending,
      paymentMethod: WeddingPaymentMethod.bankTransfer,
      memo: '원거리 하객 교통비 송금 확인',
    ),
    const WeddingBudgetItem(
      id: 'budget-11',
      title: '직장 · 지인 답례품 전달',
      category: WeddingBudgetCategory.giftsAndFavors,
      phase: WeddingExpensePhase.postWedding,
      estimatedBudget: 600000,
      deposit: 0,
      balance: 600000,
      payer: ExpensePayer.joint,
      status: BudgetPaymentStatus.pending,
      paymentMethod: WeddingPaymentMethod.creditCard,
      memo: '본식 직후 회사 및 지인 답례품 정산',
    ),
  ];
}

class WeddingBudgetNotifier extends StateNotifier<List<WeddingBudgetItem>> {
  WeddingBudgetNotifier(this._ref) : super(createDefaultWeddingBudgetItems());

  final Ref _ref;

  void addItem(WeddingBudgetItem item) {
    final synced = _syncBalanceDueDateToCalendar(item);
    state = [...state, synced];
  }

  /// 60개 마스터 템플릿 항목을 내 예산표에 즉시 추가
  void addTemplateItem(WeddingBudgetMasterTemplate template) {
    final newItem = template.toBudgetItem();
    state = [...state, newItem];
  }

  void updateItem(WeddingBudgetItem updated) {
    final synced = _syncBalanceDueDateToCalendar(updated);
    state = state.map((i) => i.id == synced.id ? synced : i).toList();
  }

  void removeItem(String id) {
    final existing = state.where((i) => i.id == id).firstOrNull;
    if (existing?.syncedBalancePlanId != null) {
      try {
        _ref
            .read(planListProvider.notifier)
            .removeItem(existing!.syncedBalancePlanId!);
      } catch (_) {}
    }
    state = state.where((i) => i.id != id).toList();
  }

  void resetDefaults() {
    state = createDefaultWeddingBudgetItems();
  }

  /// 잔금 결제 예정일 설정 시 칩 캘린더 및 D-Day 자동 동기화
  WeddingBudgetItem _syncBalanceDueDateToCalendar(WeddingBudgetItem item) {
    try {
      final planNotifier = _ref.read(planListProvider.notifier);
      final planId = item.syncedBalancePlanId ?? 'plan-wedding-balance-${item.id}';
      if (item.balanceDueDate != null &&
          item.status != BudgetPaymentStatus.fullyPaid) {
        final d = DateTime(
          item.balanceDueDate!.year,
          item.balanceDueDate!.month,
          item.balanceDueDate!.day,
        );
        final plan = PlanItem(
          id: planId,
          title: '💳 ${item.title} 잔금',
          date: d,
          isAllDay: true,
          categoryKey: 'wedding',
          displayMode: DdayDisplayMode.dday,
        );
        final exists =
            _ref.read(planListProvider).any((p) => p.id == planId);
        if (exists) {
          planNotifier.updateItem(plan);
        } else {
          planNotifier.addItem(plan);
        }
        return item.copyWith(syncedBalancePlanId: planId);
      } else if (item.syncedBalancePlanId != null) {
        planNotifier.removeItem(item.syncedBalancePlanId!);
        return item.copyWith(clearSyncedBalancePlanId: true);
      }
    } catch (_) {
      // planListProvider 미초기화 환경에서도 안전 동작
    }
    return item;
  }
}

final weddingBudgetListProvider =
    StateNotifierProvider<WeddingBudgetNotifier, List<WeddingBudgetItem>>((ref) {
  return WeddingBudgetNotifier(ref);
});

/// 예산 총계 및 목표 예산 대비 절감/초과, 기지불/잔금, 부담자별 요약 정보
final weddingBudgetSummaryProvider = Provider<({
  int targetBudget,
  int totalEstimated,
  int totalActual,
  int budgetDiff,
  int totalPaid,
  int remainingBalance,
  int groomShare,
  int brideShare,
  int jointShare,
})>((ref) {
  final targetBudget = ref.watch(weddingTargetBudgetProvider);
  final items = ref.watch(weddingBudgetListProvider);

  int totalEstimated = 0;
  int totalActual = 0;
  int totalPaid = 0;
  int remainingBalance = 0;
  int groomShare = 0;
  int brideShare = 0;
  int jointShare = 0;

  for (final item in items) {
    totalEstimated += item.estimatedBudget;
    final cost = item.totalActualCost;
    totalActual += cost;
    totalPaid += item.paidAmount;
    remainingBalance += item.remainingBalance;

    switch (item.payer) {
      case ExpensePayer.groom:
        groomShare += cost;
        break;
      case ExpensePayer.bride:
        brideShare += cost;
        break;
      case ExpensePayer.joint:
        jointShare += cost;
        break;
    }
  }

  return (
    targetBudget: targetBudget,
    totalEstimated: totalEstimated,
    totalActual: totalActual,
    budgetDiff: targetBudget - totalActual,
    totalPaid: totalPaid,
    remainingBalance: remainingBalance,
    groomShare: groomShare,
    brideShare: brideShare,
    jointShare: jointShare,
  );
});
