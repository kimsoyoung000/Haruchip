import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/models/category_model.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/screens/category_detail_screen.dart';
import '../../categories/screens/couple_category_detail_screen.dart';
import '../../couple/providers/couple_provider.dart';
import '../../onboarding/providers/dashboard_view_mode_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../widgets/add_category_dashboard_card.dart';
import '../widgets/add_category_dashboard_modal.dart';
import '../widgets/category_summary_dashboard_card.dart';
import '../widgets/dashboard_view_mode_toggle.dart';

/// 메인 셸의 "대시보드" 탭 — 카테고리별 핵심 디데이 요약 뷰 (Summary Hub)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _navigateToCategoryDetail(BuildContext context, CategoryModel category) {
    if (category.categoryKey == 'couple') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoupleCategoryDetailScreen(category: category),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(category: category),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(resolvedDashboardViewModeProvider);
    final totalDays = ref.watch(totalDaysTogetherProvider);
    final allCategories = ref.watch(categoryListProvider);
    final allPlanItems = ref.watch(planListProvider);

    final cards = <Widget>[];

    for (final category in allCategories) {
      final items = ref.watch(planItemsByCategoryProvider(category.categoryKey));
      final countUpItems = items.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
      final countDownItems = items.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();

      String? customCountUp;
      if (category.categoryKey == 'couple') {
        customCountUp = '만난 지 D+$totalDays일째';
      }

      cards.add(
        CategorySummaryDashboardCard(
          category: category,
          countUpItems: countUpItems,
          countDownItems: countDownItems,
          customCountUpText: customCountUp,
          onTap: () => _navigateToCategoryDetail(context, category),
        ),
      );
    }

    cards.add(
      AddCategoryDashboardCard(
        onTap: () => showAddCategoryDashboardModal(context),
      ),
    );

    // 임박 D-Day 필터링 (가장 빠른 3개 일정)
    final upcomingItems = allPlanItems
        .where((i) => i.displayMode != DdayDisplayMode.daysCount)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 심플·감성 대시보드 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '하루칩',
                        style: AppTypography.heading1.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.protoHeading,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '한눈에 보는 나의 디데이 요약',
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.protoSubtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 임박한 주요 일정 브리핑 바 (간결한 상단 칩)
              if (upcomingItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in upcomingItems) ...[
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: AppColors.protoHeading,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF007AFF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          dDayLabel(item.date),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. 뷰 모드 토글 (박스형 / 리스트형)
              DashboardViewModeToggle(
                selectedKey: viewMode,
                onSelect: (key) =>
                    ref.read(dashboardViewModeProvider.notifier).select(key),
              ),
              const SizedBox(height: 16),

              // 4. 카테고리별 표준 요약 카드 그리드/리스트
              if (viewMode == 'box')
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: cards,
                )
              else
                Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
