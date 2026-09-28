import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../calendar/widgets/calendar_sync_dialog.dart';
import '../../categories/models/category_model.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/screens/category_detail_screen.dart';
import '../../couple/providers/couple_provider.dart';
import '../../military/widgets/military_dashboard_card.dart';
import '../../onboarding/providers/dashboard_view_mode_provider.dart';
import '../../plan/providers/plan_provider.dart';
import '../widgets/add_category_dashboard_card.dart';
import '../widgets/add_category_dashboard_modal.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';
import '../widgets/baby_dashboard_card.dart';
import '../widgets/birthday_dashboard_card.dart';
import '../widgets/couple_dashboard_card.dart';
import '../widgets/dashboard_greeting_card.dart';
import '../widgets/dashboard_view_mode_toggle.dart';
import '../widgets/exam_dashboard_card.dart';
import '../widgets/generic_category_dashboard_card.dart';
import '../widgets/pet_dashboard_card.dart';

import '../../categories/screens/couple_category_detail_screen.dart';

/// 메인 셸의 "대시보드" 탭 — 시각적 브리핑 & 요약 영역
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const String _mockUserName = '김하루';
  static const String _mockUserAvatar = '🌻';

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
    final anniversaries = ref.watch(upcomingAnniversariesProvider);
    final allCategories = ref.watch(categoryListProvider);
    final allPlanItems = ref.watch(planListProvider);

    final cards = <Widget>[];

    if (ref.watch(hasCategoryOfKeyProvider('couple'))) {
      final coupleCat = allCategories.firstWhere(
        (c) => c.categoryKey == 'couple',
        orElse: () => CategoryModel(
          id: 'cat-couple',
          categoryKey: 'couple',
          name: '커플',
          icon: '💕',
          createdAt: DateTime.now(),
        ),
      );

      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, coupleCat),
          child: CoupleDashboardCard(
            totalDays: totalDays,
            nextAnniversary: anniversaries.isEmpty ? null : anniversaries.first,
            onTap: () => _navigateToCategoryDetail(context, coupleCat),
            onSyncCalendar: () => showCalendarSyncDialog(context, '커플 1주년'),
          ),
        ),
      );
    }

    if (ref.watch(hasCategoryOfKeyProvider('exam'))) {
      final examItems = ref.watch(planItemsByCategoryProvider('exam'));
      final examCat = allCategories.firstWhere(
        (c) => c.categoryKey == 'exam',
        orElse: () => CategoryModel(
          id: 'cat-exam',
          categoryKey: 'exam',
          name: '시험',
          icon: '📚',
          createdAt: DateTime.now(),
        ),
      );

      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, examCat),
          child: ExamDashboardCard(
            items: examItems,
            onAdd: () => showAddEventBottomSheet(context, categoryKey: 'exam'),
            onSyncItem: (item) => showCalendarSyncDialog(context, item.title),
          ),
        ),
      );
    }

    if (ref.watch(hasCategoryOfKeyProvider('birthday'))) {
      final birthdayItems = ref.watch(planItemsByCategoryProvider('birthday'));
      final bdayCat = allCategories.firstWhere(
        (c) => c.categoryKey == 'birthday',
        orElse: () => CategoryModel(
          id: 'cat-birthday',
          categoryKey: 'birthday',
          name: '생일',
          icon: '🎂',
          createdAt: DateTime.now(),
        ),
      );

      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, bdayCat),
          child: BirthdayDashboardCard(
            items: birthdayItems,
            onAdd: () => showAddEventBottomSheet(context, categoryKey: 'birthday'),
          ),
        ),
      );
    }

    if (ref.watch(hasCategoryOfKeyProvider('pet'))) {
      final petItems = ref.watch(planItemsByCategoryProvider('pet'));
      final petCat = allCategories.firstWhere(
        (c) => c.categoryKey == 'pet',
        orElse: () => CategoryModel(
          id: 'cat-pet',
          categoryKey: 'pet',
          name: '반려동물',
          icon: '🐾',
          createdAt: DateTime.now(),
        ),
      );

      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, petCat),
          child: PetDashboardCard(items: petItems),
        ),
      );
    }

    if (ref.watch(hasCategoryOfKeyProvider('military'))) {
      final militaryCat = allCategories.firstWhere(
        (c) => c.categoryKey == 'military',
        orElse: () => CategoryModel(
          id: 'cat-military',
          categoryKey: 'military',
          name: '군대',
          icon: '🪖',
          createdAt: DateTime.now(),
        ),
      );

      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, militaryCat),
          child: const MilitaryDashboardCard(),
        ),
      );
    }

    if (ref.watch(hasCategoryOfKeyProvider('baby'))) {
      final babyItems = ref.watch(planItemsByCategoryProvider('baby'));
      final babyCat = allCategories.firstWhere(
        (c) => c.categoryKey == 'baby',
        orElse: () => CategoryModel(
          id: 'cat-baby',
          categoryKey: 'baby',
          name: '아기',
          icon: '👶',
          createdAt: DateTime.now(),
        ),
      );

      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, babyCat),
          child: BabyDashboardCard(items: babyItems),
        ),
      );
    }

    // 전용 카드가 없는 나머지 카테고리 (범용 카드로 그리며 클릭 시 상세 진입)
    const dedicatedKeys = {'couple', 'exam', 'birthday', 'pet', 'military', 'baby'};
    for (final category in allCategories) {
      if (dedicatedKeys.contains(category.categoryKey)) continue;
      final items = ref.watch(planItemsByCategoryInstanceProvider(category.id));
      cards.add(
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, category),
          child: GenericCategoryDashboardCard(category: category, items: items),
        ),
      );
    }

    cards.add(
      AddCategoryDashboardCard(
        onTap: () => showAddCategoryDashboardModal(context),
      ),
    );

    // 임박 D-Day 필터링 (가장 빠른 3개 일정)
    final upcomingItems = allPlanItems.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardGreetingCard(
                userName: _mockUserName,
                avatarEmoji: _mockUserAvatar,
              ),
              const SizedBox(height: 16),

              // 대시보드 역할 A: 임박한 주요 일정 한눈에 시각적 브리핑 바
              if (upcomingItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.protoCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.protoCardSelectedBg, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '한눈에 보는 임박 D-Day 브리핑',
                            style: AppTypography.cardLabel.copyWith(
                              color: AppColors.protoHeading,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final item in upcomingItems) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.protoButtonBg.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.protoButtonBg),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.protoHeading,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.protoButtonBg,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        dDayLabel(item.date),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.protoButtonText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              DashboardViewModeToggle(
                selectedKey: viewMode,
                onSelect: (key) =>
                    ref.read(dashboardViewModeProvider.notifier).select(key),
              ),
              const SizedBox(height: 16),
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
                      const SizedBox(height: 14),
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
