import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/layout_tokens.dart';
import '../../../design_system/typography.dart';
import '../../categories/models/category_model.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/screens/category_detail_screen.dart';
import '../../categories/screens/couple_category_detail_screen.dart';
import '../../couple/providers/couple_provider.dart';
import '../../onboarding/providers/dashboard_view_mode_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../providers/dashboard_filter_provider.dart';
import '../widgets/category_summary_dashboard_card.dart';
import '../widgets/dashboard_category_filter_sheet.dart';

/// 메인 셸의 1번째 탭 "칩 데이(메인 대시보드)" — 규격 단일화 & 높이 고정 요약 허브
///
/// - 상단 가로 카테고리 칩 바 / 뷰 모드 토글 / 순서 편집 버튼 제거 (모두 필터 모달 및 프로필 & 설정 탭으로 이관)
/// - 모든 카테고리 카드의 세로 높이를 [CategorySummaryDashboardCard.kFixedCardHeight]로 완전 통일
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _navigateToCategoryDetail(CategoryModel category) {
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

  void _hideCategoryWithFeedback(CategoryModel category) {
    ref.read(categoryListProvider.notifier).hideCategory(category.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✨ [${category.name}] 카테고리가 대시보드에서 숨겨졌습니다. (설정 > 숨김 보관함에서 언제든 복구 가능)',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCategoryActionSheet(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: HaruChipIconViewer(
                      iconKey: category.icon,
                      size: 20,
                      circular: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        Text(
                          '카테고리 카드 관리 옵션',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.protoSubtitle,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF007AFF),
                ),
                title: const Text(
                  '카테고리 상세 보기',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _navigateToCategoryDetail(category);
                },
              ),
              const Divider(height: 10, color: Color(0xFFF3F4F6)),
              ListTile(
                leading: const Icon(
                  Icons.sort_rounded,
                  size: 16,
                  color: Color(0xFF8B5CF6),
                ),
                title: const Text(
                  '카테고리 순서 편집',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                onTap: () {
                  Navigator.of(ctx).pop();
                  showCategoryOrderEditSheet(context);
                },
              ),
              const Divider(height: 10, color: Color(0xFFF3F4F6)),
              ListTile(
                leading: const Icon(
                  Icons.visibility_off_outlined,
                  size: 16,
                  color: Color(0xFFE11D48),
                ),
                title: const Text(
                  '대시보드에서 숨기기',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Color(0xFFE11D48),
                  ),
                ),
                subtitle: const Text(
                  '데이터는 100% 영구 보존되며, 홈에서만 감춰집니다.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _hideCategoryWithFeedback(category);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(resolvedDashboardViewModeProvider);
    final totalDays = ref.watch(totalDaysTogetherProvider);
    final visibleCategories = ref.watch(visibleCategoriesProvider);
    final selectedKeys = ref.watch(dashboardCategoryFilterProvider);

    final displayedCategories = selectedKeys.isEmpty
        ? visibleCategories
        : visibleCategories
            .where((c) => selectedKeys.contains(c.categoryKey))
            .toList();

    final isBoxGrid = viewMode == 'box' || viewMode == 'grid';

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayoutTokens.dashboardScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 모든 카테고리 카드: 높이 완전 고정 & 럭셔리 화이트 컴팩트 여백
              if (isBoxGrid) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppLayoutTokens.cardVerticalGap,
                    crossAxisSpacing: AppLayoutTokens.cardVerticalGap,
                    mainAxisExtent:
                        CategorySummaryDashboardCard.kFixedCardHeight,
                  ),
                  itemCount: displayedCategories.length,
                  itemBuilder: (context, index) {
                    final category = displayedCategories[index];
                    final items = ref.watch(
                        planItemsByCategoryProvider(category.categoryKey));
                    final countUpItems = items
                        .where((i) => i.displayMode == DdayDisplayMode.daysCount)
                        .toList();
                    final countDownItems = items
                        .where((i) => i.displayMode != DdayDisplayMode.daysCount)
                        .toList();

                    String? customCountUp;
                    if (category.categoryKey == 'couple') {
                      customCountUp = '함께한 지 $totalDays일째';
                    }

                    return CategorySummaryDashboardCard(
                      key: ValueKey(category.id),
                      category: category,
                      countUpItems: countUpItems,
                      countDownItems: countDownItems,
                      customCountUpText: customCountUp,
                      isEditMode: false,
                      isWideList: false,
                      onTap: () => _navigateToCategoryDetail(category),
                      onLongPress: () => _showCategoryActionSheet(category),
                      onHide: () => _hideCategoryWithFeedback(category),
                    );
                  },
                ),
              ] else ...[
                Column(
                  children: [
                    for (int i = 0; i < displayedCategories.length; i++) ...[
                      Builder(builder: (context) {
                        final category = displayedCategories[i];
                        final items = ref.watch(
                            planItemsByCategoryProvider(category.categoryKey));
                        final countUpItems = items
                            .where((item) =>
                                item.displayMode == DdayDisplayMode.daysCount)
                            .toList();
                        final countDownItems = items
                            .where((item) =>
                                item.displayMode != DdayDisplayMode.daysCount)
                            .toList();

                        String? customCountUp;
                        if (category.categoryKey == 'couple') {
                          customCountUp = '함께한 지 $totalDays일째';
                        }

                        return CategorySummaryDashboardCard(
                          key: ValueKey(category.id),
                          category: category,
                          countUpItems: countUpItems,
                          countDownItems: countDownItems,
                          customCountUpText: customCountUp,
                          isEditMode: false,
                          isWideList: true,
                          onTap: () => _navigateToCategoryDetail(category),
                          onLongPress: () => _showCategoryActionSheet(category),
                          onHide: () => _hideCategoryWithFeedback(category),
                        );
                      }),
                      if (i < displayedCategories.length - 1)
                        const SizedBox(height: AppLayoutTokens.cardVerticalGap),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
