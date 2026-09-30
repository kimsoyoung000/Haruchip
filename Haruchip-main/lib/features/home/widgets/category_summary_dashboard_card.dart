import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/models/category_model.dart';
import '../../military/providers/military_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart' show dDayLabel;

/// 카테고리별 감성 소프트 파스텔 테마 팔레트 (10~30대 타깃 톤온톤 디자인)
class CategoryThemePalette {
  const CategoryThemePalette({
    required this.bg,
    required this.border,
    required this.chipBg,
    required this.primary,
    required this.text,
  });

  final Color bg;
  final Color border;
  final Color chipBg;
  final Color primary;
  final Color text;

  static CategoryThemePalette forCategoryKey(String key) {
    switch (key) {
      case 'couple':
        return const CategoryThemePalette(
          bg: Color(0xFFFFF1F2),
          border: Color(0xFFFFE4E6),
          chipBg: Color(0xFFFFE4E6),
          primary: Color(0xFFE11D48),
          text: Color(0xFF881337),
        );
      case 'military':
        return const CategoryThemePalette(
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFDCFCE7),
          chipBg: Color(0xFFDCFCE7),
          primary: Color(0xFF16A34A),
          text: Color(0xFF14532D),
        );
      case 'baby':
        return const CategoryThemePalette(
          bg: Color(0xFFFEFCE8),
          border: Color(0xFFFEF08A),
          chipBg: Color(0xFFFEF08A),
          primary: Color(0xFFCA8A04),
          text: Color(0xFF713F12),
        );
      case 'pet':
        return const CategoryThemePalette(
          bg: Color(0xFFFFF8F1),
          border: Color(0xFFFFEDD5),
          chipBg: Color(0xFFFFEDD5),
          primary: Color(0xFFEA580C),
          text: Color(0xFF7C2D12),
        );
      case 'solo':
        return const CategoryThemePalette(
          bg: Color(0xFFFAF5FF),
          border: Color(0xFFF3E8FF),
          chipBg: Color(0xFFF3E8FF),
          primary: Color(0xFF9333EA),
          text: Color(0xFF581C87),
        );
      case 'fandom':
        return const CategoryThemePalette(
          bg: Color(0xFFFFFDF0),
          border: Color(0xFFFEF3C7),
          chipBg: Color(0xFFFEF3C7),
          primary: Color(0xFFD97706),
          text: Color(0xFF78350F),
        );
      case 'exam':
      case 'study':
        return const CategoryThemePalette(
          bg: Color(0xFFEFF6FF),
          border: Color(0xFFDBEAFE),
          chipBg: Color(0xFFDBEAFE),
          primary: Color(0xFF2563EB),
          text: Color(0xFF1E3A8A),
        );
      case 'birthday':
        return const CategoryThemePalette(
          bg: Color(0xFFFDF2F8),
          border: Color(0xFFFCE7F3),
          chipBg: Color(0xFFFCE7F3),
          primary: Color(0xFFDB2777),
          text: Color(0xFF831843),
        );
      case 'custom':
        return const CategoryThemePalette(
          bg: Color(0xFFF0FDFA),
          border: Color(0xFFCCFBF1),
          chipBg: Color(0xFFCCFBF1),
          primary: Color(0xFF0D9488),
          text: Color(0xFF115E59),
        );
      case 'goal':
        return const CategoryThemePalette(
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFDCFCE7),
          chipBg: Color(0xFFDCFCE7),
          primary: Color(0xFF16A34A),
          text: Color(0xFF14532D),
        );
      case 'routine':
        return const CategoryThemePalette(
          bg: Color(0xFFF0F9FF),
          border: Color(0xFFE0F2FE),
          chipBg: Color(0xFFE0F2FE),
          primary: Color(0xFF0284C7),
          text: Color(0xFF075985),
        );
      case 'plan':
        return const CategoryThemePalette(
          bg: Color(0xFFF8FAFC),
          border: Color(0xFFE2E8F0),
          chipBg: Color(0xFFE2E8F0),
          primary: Color(0xFF334155),
          text: Color(0xFF0F172A),
        );
      default:
        return const CategoryThemePalette(
          bg: Color(0xFFF8FAFC),
          border: Color(0xFFE2E8F0),
          chipBg: Color(0xFFE2E8F0),
          primary: Color(0xFF475569),
          text: Color(0xFF0F172A),
        );
    }
  }
}

/// 홈/대시보드 메인 표준 카테고리 요약 카드
/// - 정보 구조: [우선순위 상단 N일째 최대 2개] + [가장 임박한 세부 D-Day 최대 2개]
/// - 군더더기 버튼(+, 추가, 연동 등) 없이 카드 탭 시 해당 상세 화면으로 라우팅
class CategorySummaryDashboardCard extends ConsumerWidget {
  const CategorySummaryDashboardCard({
    super.key,
    required this.category,
    required this.countUpItems,
    required this.countDownItems,
    this.customCountUpText,
    this.onTap,
  });

  final CategoryModel category;
  final List<PlanItem> countUpItems;
  final List<PlanItem> countDownItems;
  final String? customCountUpText;
  final VoidCallback? onTap;

  String _formatDaysCount(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays + 1;
    return diff > 0 ? '$diff일째' : 'D-Day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = CategoryThemePalette.forCategoryKey(category.categoryKey);
    final isMilitary = category.categoryKey == 'military';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 헤더: 아이콘 + 카테고리 이름 + 바로가기 화살표
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.chipBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(category.icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTypography.cardLabel.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. 군대 카테고리 전용 요약 UI
            if (isMilitary)
              _buildMilitaryBody(context, ref, palette)
            else
              _buildStandardBody(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildMilitaryBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final progress = ref.watch(militaryProgressProvider);
    final dischargeDday = ref.watch(militaryDischargeDdayProvider);
    final leaveDday = ref.watch(militaryLeaveDdayProvider);
    final currentRank = ref.watch(militaryCurrentRankProvider);
    final nextRankMilestone = ref.watch(militaryNextRankMilestoneProvider);
    final nextRankDday = ref.watch(militaryNextRankDdayProvider);
    final remainingVacationDays = ref.watch(militaryRemainingVacationDaysProvider);
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 복무율 및 전역일
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '복무율 $progressPercent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
            Text(
              '전역 $dischargeDday',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 프로그레스 바
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: palette.chipBg,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
          ),
        ),
        const SizedBox(height: 10),

        // [다음 진급일 D-Day] + [다음 휴가 D-Day] + [남은 총 휴가 개수]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎖️', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      nextRankMilestone == null
                          ? '${currentRank.labelKo} (진급 완료)'
                          : '${nextRankMilestone.rank.labelKo} $nextRankDday',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏖️', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      leaveDday != null ? '휴가 $leaveDday' : '휴가 미설정',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '남은 휴가 $remainingVacationDays일',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardBody(CategoryThemePalette palette) {
    // 1. 상단 N일째 항목들 (최대 2개)
    final topCountUpPills = <Widget>[];

    if (customCountUpText != null && customCountUpText!.isNotEmpty) {
      topCountUpPills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            customCountUpText!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
        ),
      );
    }

    for (final item in countUpItems.take(2)) {
      if (customCountUpText != null && countUpItems.length == 1) continue;
      topCountUpPills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${item.title} ${_formatDaysCount(item.date)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
        ),
      );
      if (topCountUpPills.length >= 2) break;
    }

    // 2. 세부 D-Day 항목들 (최대 2개)
    final topDDayItems = countDownItems.take(2).toList();

    final hasNoData = topCountUpPills.isEmpty && topDDayItems.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 N일째 배지 (최대 2개)
        if (topCountUpPills.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: topCountUpPills,
          ),
          if (topDDayItems.isNotEmpty) const SizedBox(height: 10),
        ],

        // 하단 세부 D-Day 리스트 (최대 2개)
        if (topDDayItems.isNotEmpty) ...[
          for (final item in topDDayItems) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border.withValues(alpha: 0.8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.protoHeading,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      dDayLabel(item.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else if (hasNoData) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '등록된 디데이 일정이 없어요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
