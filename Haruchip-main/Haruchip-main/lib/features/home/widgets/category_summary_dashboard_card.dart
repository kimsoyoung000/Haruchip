import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/layout_tokens.dart';
import '../../../design_system/typography.dart';
import '../../categories/controllers/baby_category_controller.dart';
import '../../categories/data/baby_health_database.dart';
import '../../categories/logic/repeat_rule.dart';
import '../../categories/models/baby_profile.dart';
import '../../categories/models/category.dart';
import '../../categories/models/exam_model.dart';
import '../../categories/models/solo_profile.dart';
import '../../categories/widgets/skin_theme_card_container.dart';
import '../../couple/providers/couple_provider.dart';
import '../../hobby/providers/hobby_provider.dart';
import '../../military/providers/military_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../travel/providers/travel_provider.dart';
import '../../wedding/providers/wedding_provider.dart';

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
          bg: Color(0xFFFFF0F3),
          border: Color(0xFFFFCCD5),
          chipBg: Color(0xFFFFCCD5),
          primary: Color(0xFFFF7A9C),
          text: Color(0xFF4A4A4A),
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
      case 'custom':
        return const CategoryThemePalette(
          bg: Color(0xFFFFFFFF),
          border: Color(0xFFE9ECEF),
          chipBg: Color(0xFFF3F4F6),
          primary: Color(0xFF6C757D),
          text: Color(0xFF343A40),
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
      case 'hobby':
        return const CategoryThemePalette(
          bg: Color(0xFFF4F7F4),
          border: Color(0xFFDDE7DD),
          chipBg: Color(0xFFDDE7DD),
          primary: Color(0xFF354235),
          text: Color(0xFF354235),
        );
      case 'travel':
        return const CategoryThemePalette(
          bg: Color(0xFFF0F8FF),
          border: Color(0xFFD6ECFF),
          chipBg: Color(0xFFD6ECFF),
          primary: Color(0xFF2C3E50),
          text: Color(0xFF2C3E50),
        );
      case 'wedding':
        return const CategoryThemePalette(
          bg: Color(0xFFFFF5F5),
          border: Color(0xFFFED7D7),
          chipBg: Color(0xFFFED7D7),
          primary: Color(0xFFE53E3E),
          text: Color(0xFF742A2A),
        );
      case 'plan':
      case 'appointment':
      default:
        return const CategoryThemePalette(
          bg: Color(0xFFF8F9FA),
          border: Color(0xFFE9ECEF),
          chipBg: Color(0xFFE9ECEF),
          primary: Color(0xFF495057),
          text: Color(0xFF343A40),
        );
    }
  }
}

/// 다가오는 D-Day 표준 엔트리 (임박순 정렬 & 지난 일정 제외용)
class _UpcomingDdayEntry {
  const _UpcomingDdayEntry({
    required this.title,
    required this.dDayBadge,
    required this.sortDateTime,
  });

  final String title;
  final String dDayBadge;
  final DateTime sortDateTime;
}

/// 홈/대시보드(칩 데이) 메인 표준 카테고리 요약 카드
///
/// - 모든 카테고리 카드의 세로 높이를 [kFixedCardHeight]로 완전 통일
/// - 그룹 1 (커플/솔로/덕질/아기/반려동물/직접 추가): N일째 칩 최대 3개 + 다가오는 D-Day 바 최대 2개
/// - 그룹 2 (시험/결혼/생일/일정·약속/목표/루틴/취미/여행): N일째 없이 다가오는 D-Day 바 최대 3개
/// - 그룹 3 (군대): 슬림 복무율 프로그레스 바 + 가장 가까운 다가오는 D-Day 바 1개
class CategorySummaryDashboardCard extends ConsumerWidget {
  const CategorySummaryDashboardCard({
    super.key,
    required this.category,
    required this.countUpItems,
    required this.countDownItems,
    this.customCountUpText,
    this.onTap,
    this.onLongPress,
    this.onHide,
    this.isEditMode = false,
    this.isWideList = false,
  });

  /// 모든 메인 카테고리 카드의 통일 고정 세로 높이 (일정 0개 ~ 최대치 동일)
  static const double kFixedCardHeight = 154.0;

  /// 그룹 2 (D-Day 전용, 최대 3개) 카테고리 키 집합
  static const Set<String> _kGroup2Keys = {
    'exam',
    'study',
    'wedding',
    'birthday',
    'plan',
    'appointment',
    'goal',
    'routine',
    'hobby',
    'travel',
  };

  final CategoryModel category;
  final List<PlanItem> countUpItems;
  final List<PlanItem> countDownItems;
  final String? customCountUpText;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onHide;
  final bool isEditMode;
  final bool isWideList;

  String _formatDaysCount(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays + 1;
    return diff > 0 ? '$diff일째' : 'D-Day';
  }

  String _formatUpcomingDday(DateTime targetDate, DateTime today) {
    final d = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = d.difference(today).inDays;
    return diff <= 0 ? 'D-Day' : 'D-$diff';
  }

  /// 날짜/시간이 이미 지난 과거 일정인지 판별 (지난 일정은 메인 카드에서 자동 제외)
  bool _isUpcoming(DateTime date, TimeOfDay? time, DateTime now, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    if (d.isBefore(today)) return false;
    if (d == today && time != null) {
      final dt = DateTime(d.year, d.month, d.day, time.hour, time.minute);
      if (dt.isBefore(now)) return false;
    }
    return true;
  }

  /// PlanItem 목록에서 지난 일정을 제외하고 오늘 기준 임박순(오름차순) 정렬
  List<_UpcomingDdayEntry> _upcomingFromPlanItems(
    List<PlanItem> items,
    DateTime now,
    DateTime today,
  ) {
    final list = <_UpcomingDdayEntry>[];
    for (final item in items) {
      if (!_isUpcoming(item.date, item.deadlineTime, now, today)) continue;
      final d = DateTime(item.date.year, item.date.month, item.date.day);
      final sortDt = item.deadlineTime != null
          ? DateTime(d.year, d.month, d.day, item.deadlineTime!.hour,
              item.deadlineTime!.minute)
          : DateTime(d.year, d.month, d.day, 23, 59);
      list.add(_UpcomingDdayEntry(
        title: item.title,
        dDayBadge: _formatUpcomingDday(d, today),
        sortDateTime: sortDt,
      ));
    }
    list.sort((a, b) => a.sortDateTime.compareTo(b.sortDateTime));
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinTheme = category.skinTheme;
    final defaultPalette =
        CategoryThemePalette.forCategoryKey(category.categoryKey);
    final palette = skinTheme != null
        ? CategoryThemePalette(
            bg: colorFromHex(skinTheme.backgroundColor),
            border: colorFromHex(skinTheme.borderColor),
            chipBg:
                colorFromHex(skinTheme.patternColor).withValues(alpha: 0.28),
            primary: colorFromHex(skinTheme.borderColor),
            text: colorFromHex(skinTheme.textColor),
          )
        : defaultPalette;

    final key = category.categoryKey;
    final displayIcon = skinTheme?.accentEmoji.isNotEmpty == true
        ? skinTheme!.accentEmoji
        : category.icon;

    final Widget bodyWidget;
    if (key == 'military') {
      bodyWidget = _buildGroup3MilitaryBody(ref, palette);
    } else if (_kGroup2Keys.contains(key)) {
      bodyWidget = _buildGroup2DdayOnlyBody(ref, palette);
    } else {
      bodyWidget = _buildGroup1CountUpAndDdayBody(ref, palette);
    }

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 컴팩트 통일 헤더 (고정 높이)
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.chipBg,
                shape: BoxShape.circle,
              ),
              child: HaruChipIconViewer(
                iconKey: displayIcon,
                size: 16,
                circular: true,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.cardLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: palette.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isEditMode) ...[
              if (onHide != null)
                IconButton(
                  icon: const Icon(Icons.visibility_off_outlined,
                      size: 16, color: Color(0xFF6B7280)),
                  tooltip: '대시보드에서 숨기기',
                  onPressed: onHide,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.drag_handle_rounded,
                  size: 18, color: Color(0xFF9CA3AF)),
            ] else
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: palette.primary.withValues(alpha: 0.7),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // 2. 고정 높이 내부 본문
        Expanded(child: bodyWidget),
      ],
    );

    if (skinTheme != null) {
      return SizedBox(
        height: kFixedCardHeight,
        child: InkWell(
          onTap: isEditMode ? null : onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: SkinThemeCardContainer(
            theme: skinTheme,
            borderless: true,
            backgroundImageUrl: category.background.type == BackgroundType.image
                ? category.background.imageUrl
                : null,
            padding: AppLayoutTokens.cardInternalPadding,
            child: cardContent,
          ),
        ),
      );
    }

    // 무테두리 순백색(#FFFFFF) 럭셔리 플랫 카드 + 초미세 소프트 섀도우
    return SizedBox(
      height: kFixedCardHeight,
      child: InkWell(
        onTap: isEditMode ? null : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: AppLayoutTokens.cardInternalPadding,
          decoration: BoxDecoration(
            color: AppColors.cleanWhiteBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppLayoutTokens.luxuryCardShadow,
          ),
          child: cardContent,
        ),
      ),
    );
  }

  /// 그룹 1: [커플, 솔로, 덕질, 아기, 반려동물, 직접 설정한 새 카테고리들]
  /// - 상단: 시작일 기준 'N일째' 가로 칩 최대 3개
  /// - 하단: 화이트 라운드 바 형태 다가오는 D-Day 일정 최대 2개 (임박순, 지난 일정 제외)
  Widget _buildGroup1CountUpAndDdayBody(
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = category.categoryKey;

    final chips = <String>[];

    BabyProfile? babyProfile;
    if (key == 'couple') {
      final totalDays = ref.watch(totalDaysTogetherProvider);
      chips.add('함께한 지 ${(totalDays < 0 ? 0 : totalDays) + 1}일째');
    } else if (key == 'baby') {
      if (category.metadata?['babyProfile'] != null) {
        try {
          babyProfile = BabyProfile.fromJson(
            Map<String, dynamic>.from(category.metadata!['babyProfile'] as Map),
          );
        } catch (_) {}
      }
      const babyController = BabyCategoryController();
      if (babyProfile != null) {
        chips.add(babyController.formatBabyDaysCount(babyProfile.birthDate));
        final rawAge =
            babyController.formatBabyAgeDetailed(babyProfile.birthDate);
        final compactAge = rawAge.contains('(')
            ? rawAge.substring(0, rawAge.indexOf('(')).trim()
            : rawAge;
        chips.add(compactAge);
      } else {
        chips.add('태어난 지 1일째');
        chips.add('생후 0개월 1일차');
      }
    } else if (key == 'solo') {
      SoloProfile? soloProfile;
      if (category.metadata?['soloProfile'] != null) {
        try {
          soloProfile = SoloProfile.fromJson(
            Map<String, dynamic>.from(category.metadata!['soloProfile'] as Map),
          );
        } catch (_) {}
      }
      final days = soloProfile?.daysCount() ??
          (countUpItems.isNotEmpty
              ? (today
                      .difference(DateTime(
                        countUpItems.first.date.year,
                        countUpItems.first.date.month,
                        countUpItems.first.date.day,
                      ))
                      .inDays +
                  1)
              : 1);
      chips.add('나에게 집중한 지 $days일째');
    } else if (customCountUpText != null && customCountUpText!.isNotEmpty) {
      chips.add(customCountUpText!);
    }

    // 아기 카드는 '태어난 지 N일째' + '생후 N개월 N일차' 핵심 2개 뱃지만 깔끔하게 노출
    if (key != 'baby') {
      for (final item in countUpItems) {
        if (chips.length >= 3) break;
        final text = '${item.title} ${_formatDaysCount(item.date)}';
        if (!chips.contains(text)) {
          chips.add(text);
        }
      }
    }

    final limitedChips = key == 'baby' ? chips.take(2).toList() : chips.take(3).toList();
    final upcomingEntries = <_UpcomingDdayEntry>[
      ..._upcomingFromPlanItems(countDownItems, now, today),
    ];

    if (key == 'couple') {
      final anniversaries = ref.watch(upcomingAnniversariesProvider);
      for (final anniv in anniversaries.take(5)) {
        final d = DateTime(anniv.date.year, anniv.date.month, anniv.date.day);
        if (d.isBefore(today)) continue;
        upcomingEntries.add(_UpcomingDdayEntry(
          title: anniv.label,
          dDayBadge: _formatUpcomingDday(d, today),
          sortDateTime: DateTime(d.year, d.month, d.day, 23, 59),
        ));
      }
      upcomingEntries.sort((a, b) => a.sortDateTime.compareTo(b.sortDateTime));
    } else if (key == 'baby' && babyProfile != null) {
      const babyController = BabyCategoryController();
      final vaccines = babyProfile.vaccineDoses.isNotEmpty
          ? babyProfile.vaccineDoses
          : kDefaultVaccineDoses;
      for (final v in vaccines) {
        if (v.isCompleted) continue;
        final target =
            babyController.calculateVaccineDoseTargetDate(babyProfile.birthDate, v);
        final d = DateTime(target.year, target.month, target.day);
        if (d.isBefore(today)) continue;
        upcomingEntries.add(_UpcomingDdayEntry(
          title: '💉 ${v.name}',
          dDayBadge: _formatUpcomingDday(d, today),
          sortDateTime: DateTime(d.year, d.month, d.day, 12, 0),
        ));
      }

      final checkups = babyProfile.checkupDoses.isNotEmpty
          ? babyProfile.checkupDoses
          : kDefaultHealthCheckupDoses;
      for (final c in checkups) {
        if (c.isCompleted) continue;
        final start = babyProfile.birthDate.add(Duration(days: c.startDays));
        final end = babyProfile.birthDate.add(Duration(days: c.endDays));
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = DateTime(end.year, end.month, end.day);
        if (endDay.isBefore(today)) continue;
        final targetDay = startDay.isBefore(today) ? endDay : startDay;
        upcomingEntries.add(_UpcomingDdayEntry(
          title: '🩺 ${c.stage}차 영유아 건강검진',
          dDayBadge: _formatUpcomingDday(targetDay, today),
          sortDateTime: DateTime(targetDay.year, targetDay.month, targetDay.day, 12, 0),
        ));
      }
      upcomingEntries.sort((a, b) => a.sortDateTime.compareTo(b.sortDateTime));
    }

    final upcoming = upcomingEntries.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 N일째 칩 영역 (최대 3개, 1줄 가로 스크롤)
        if (limitedChips.isNotEmpty) ...[
          SizedBox(
            height: 24,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final label in limitedChips)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.chipBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: palette.primary,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // 하단 다가오는 D-Day 화이트 라운드 바 (최대 2개)
        Expanded(
          child: upcoming.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (final entry in upcoming)
                      _buildWhiteDdayBar(entry.title, entry.dDayBadge, palette),
                  ],
                )
              : _buildEmptyPlaceholder(),
        ),
      ],
    );
  }

  /// 그룹 2: [시험/자격증, 결혼 준비, 생일, 일정/약속, 목표/버킷리스트, 루틴/주간계획표, 취미, 여행]
  /// - N일째 표기 없이, 오직 다가오는 'D-Day 일정'만 최대 3개까지 화이트 라운드 바로 표기
  Widget _buildGroup2DdayOnlyBody(
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = category.categoryKey;
    final entries = <_UpcomingDdayEntry>[];

    if (key == 'exam' || key == 'study') {
      final raw = category.metadata?['exams'] as List<dynamic>?;
      if (raw != null) {
        for (final r in raw) {
          try {
            final exam = ExamProfile.fromJson(Map<String, dynamic>.from(r as Map));
            if (exam.isHidden) continue;
            for (final stage in exam.stages) {
              if (stage.isCompleted) continue;
              final target = (stage.stageType == ExamStageType.application &&
                      stage.endDate != null &&
                      today.isAfter(DateTime(stage.startDate.year,
                          stage.startDate.month, stage.startDate.day)))
                  ? stage.endDate!
                  : stage.startDate;
              final d = DateTime(target.year, target.month, target.day);
              if (!d.isBefore(today)) {
                entries.add(_UpcomingDdayEntry(
                  title: '${exam.title} · ${stage.name}',
                  dDayBadge: _formatUpcomingDday(d, today),
                  sortDateTime: d,
                ));
              }
            }
            for (final sub in exam.subjects) {
              if (sub.isCompleted) continue;
              final d = DateTime(
                  sub.examDate.year, sub.examDate.month, sub.examDate.day);
              if (!d.isBefore(today)) {
                entries.add(_UpcomingDdayEntry(
                  title: '${exam.title} · ${sub.subjectName}',
                  dDayBadge: _formatUpcomingDday(d, today),
                  sortDateTime: d,
                ));
              }
            }
          } catch (_) {}
        }
      }
      entries.addAll(_upcomingFromPlanItems(countDownItems, now, today));
    } else if (key == 'wedding') {
      final weddingDate = ref.watch(weddingDateProvider);
      if (weddingDate != null) {
        final wd =
            DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
        if (!wd.isBefore(today)) {
          entries.add(_UpcomingDdayEntry(
            title: '💍 본식 (결혼식)',
            dDayBadge: _formatUpcomingDday(wd, today),
            sortDateTime: wd,
          ));
        }
      }
      final weddingItems = ref.watch(weddingListProvider);
      for (final item in weddingItems) {
        if (item.isCompleted || item.targetDate == null) continue;
        final d = DateTime(item.targetDate!.year, item.targetDate!.month,
            item.targetDate!.day);
        if (!d.isBefore(today)) {
          entries.add(_UpcomingDdayEntry(
            title: item.title,
            dDayBadge: _formatUpcomingDday(d, today),
            sortDateTime: d,
          ));
        }
      }
      entries.addAll(_upcomingFromPlanItems(countDownItems, now, today));
    } else if (key == 'travel') {
      final trips = ref.watch(travelTripListProvider);
      for (final trip in trips) {
        final s = DateTime(
            trip.startDate.year, trip.startDate.month, trip.startDate.day);
        final e =
            DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
        if (e.isBefore(today)) continue; // 지난 여행 제외
        final isOngoing = !today.isBefore(s) && !today.isAfter(e);
        entries.add(_UpcomingDdayEntry(
          title: '${trip.emoji} ${trip.destination}',
          dDayBadge: isOngoing
              ? '${trip.currentDayNumber()}일차'
              : _formatUpcomingDday(s, today),
          sortDateTime: isOngoing ? today : s,
        ));
      }
      final interPlans = ref.watch(interTripPlanListProvider);
      for (final p in interPlans) {
        final d = DateTime(p.date.year, p.date.month, p.date.day);
        if (!d.isBefore(today)) {
          entries.add(_UpcomingDdayEntry(
            title: p.title,
            dDayBadge: _formatUpcomingDday(d, today),
            sortDateTime: d,
          ));
        }
      }
      entries.addAll(_upcomingFromPlanItems(countDownItems, now, today));
    } else if (key == 'hobby') {
      final schedules = ref.watch(hobbyScheduleListProvider);
      final hobbies = ref.watch(hobbyListProvider);
      for (final sched in schedules) {
        final d = DateTime(sched.date.year, sched.date.month, sched.date.day);
        final t = sched.hasTime
            ? TimeOfDay(hour: sched.date.hour, minute: sched.date.minute)
            : null;
        if (!_isUpcoming(d, t, now, today)) continue;
        final hMatch = hobbies.where((h) => h.id == sched.hobbyId);
        final prefix = hMatch.isNotEmpty ? '${hMatch.first.icon} ' : '';
        entries.add(_UpcomingDdayEntry(
          title: '$prefix${sched.title}',
          dDayBadge: _formatUpcomingDday(d, today),
          sortDateTime: sched.date,
        ));
      }
      entries.addAll(_upcomingFromPlanItems(countDownItems, now, today));
    } else if (key == 'routine') {
      final allRoutineItems = [...countDownItems, ...countUpItems];
      for (final item in allRoutineItems) {
        final hour = item.deadlineTime?.hour ?? 23;
        final minute = item.deadlineTime?.minute ?? 59;
        DateTime? nextDate;
        if (item.repeatConfig.type == RepeatType.daily) {
          final cand = DateTime(today.year, today.month, today.day, hour, minute);
          nextDate = cand.isAfter(now) ? cand : cand.add(const Duration(days: 1));
        } else if (item.repeatConfig.type == RepeatType.weekly &&
            item.repeatConfig.weekdays.isNotEmpty) {
          for (int i = 0; i <= 7; i++) {
            final check = today.add(Duration(days: i));
            final wd = check.weekday % 7;
            if (item.repeatConfig.weekdays.contains(wd) ||
                item.repeatConfig.weekdays.contains(check.weekday)) {
              final cand =
                  DateTime(check.year, check.month, check.day, hour, minute);
              if (cand.isAfter(now) || i > 0) {
                nextDate = cand;
                break;
              }
            }
          }
        } else if (_isUpcoming(item.date, item.deadlineTime, now, today)) {
          nextDate = DateTime(
              item.date.year, item.date.month, item.date.day, hour, minute);
        }
        if (nextDate != null) {
          final nd = DateTime(nextDate.year, nextDate.month, nextDate.day);
          entries.add(_UpcomingDdayEntry(
            title: item.title,
            dDayBadge: _formatUpcomingDday(nd, today),
            sortDateTime: nextDate,
          ));
        }
      }
    } else {
      // birthday, plan, appointment, goal
      entries.addAll(_upcomingFromPlanItems(countDownItems, now, today));
    }

    entries.sort((a, b) => a.sortDateTime.compareTo(b.sortDateTime));
    final top3 = entries.take(3).toList();

    if (top3.isEmpty) {
      return _buildEmptyPlaceholder();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (final entry in top3)
          _buildWhiteDdayBar(entry.title, entry.dDayBadge, palette),
      ],
    );
  }

  /// 그룹 3: [군대 (곰신)]
  /// - 슬림 복무율 프로그레스 바(%) 유지 + 바로 아래 가장 가까운 다가오는 D-Day 일정 최대 2개 표기
  Widget _buildGroup3MilitaryBody(
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final service = ref.watch(militaryServiceProvider);
    final progress = ref.watch(militaryProgressProvider);
    final dischargeDday = ref.watch(militaryDischargeDdayProvider);
    final nextRankMilestone = ref.watch(militaryNextRankMilestoneProvider);
    final progressPercent = (progress * 100).toStringAsFixed(1);

    // 가장 가까운 다가오는 군대 D-Day 최대 2개 산출 (등록된 출타 + 진급 + 전역 + 커스텀 일정)
    final candidates = <_UpcomingDdayEntry>[];
    for (final leave in service.leaves) {
      final ld = DateTime(
        leave.startDate.year,
        leave.startDate.month,
        leave.startDate.day,
      );
      if (!ld.isBefore(today)) {
        candidates.add(_UpcomingDdayEntry(
          title: '${leave.type.emoji} ${leave.summaryLabel}',
          dDayBadge: _formatUpcomingDday(ld, today),
          sortDateTime: ld,
        ));
      }
    }
    if (service.nextLeaveDate != null && candidates.isEmpty) {
      final ld = DateTime(service.nextLeaveDate!.year,
          service.nextLeaveDate!.month, service.nextLeaveDate!.day);
      if (!ld.isBefore(today)) {
        candidates.add(_UpcomingDdayEntry(
          title: '🏖️ 다음 휴가',
          dDayBadge: _formatUpcomingDday(ld, today),
          sortDateTime: ld,
        ));
      }
    }
    if (nextRankMilestone != null) {
      final rd = DateTime(nextRankMilestone.startDate.year,
          nextRankMilestone.startDate.month, nextRankMilestone.startDate.day);
      if (!rd.isBefore(today)) {
        candidates.add(_UpcomingDdayEntry(
          title: '🎖️ ${nextRankMilestone.rank.labelKo} 진급',
          dDayBadge: _formatUpcomingDday(rd, today),
          sortDateTime: rd,
        ));
      }
    }
    final dd = DateTime(service.effectiveDischargeDate.year,
        service.effectiveDischargeDate.month, service.effectiveDischargeDate.day);
    if (!dd.isBefore(today)) {
      candidates.add(_UpcomingDdayEntry(
        title: '🎉 전역일 (만기제대)',
        dDayBadge: _formatUpcomingDday(dd, today),
        sortDateTime: dd,
      ));
    }
    final customMilitaryItems = countDownItems
        .where((item) => !item.id.startsWith('mil-leave-'))
        .toList();
    candidates.addAll(_upcomingFromPlanItems(customMilitaryItems, now, today));
    candidates.sort((a, b) => a.sortDateTime.compareTo(b.sortDateTime));

    final topTwo = candidates.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '복무율 $progressPercent%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E6B3E),
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '전역 $dischargeDday',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.chipYellowText,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFFFFF8E1),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.chipYellowBg, Color(0xFF81C784)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: topTwo.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (final entry in topTwo)
                      _buildWhiteDdayBar(entry.title, entry.dDayBadge, palette),
                  ],
                )
              : _buildEmptyPlaceholder(),
        ),
      ],
    );
  }

  /// 표준 파스텔 소프트 라운드 D-Day 바 (순백색 카드 위 은은한 대비, 콤팩트 고정 높이 28px)
  Widget _buildWhiteDdayBar(
    String title,
    String dDayBadge,
    CategoryThemePalette palette,
  ) {
    final rowBg = Color.lerp(const Color(0xFFF8F9FA), palette.bg, 0.72) ??
        const Color(0xFFF8F9FA);
    return Container(
      height: 28,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.protoHeading,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            dDayBadge,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 일정이 없을 때도 카드 높이를 일관되게 유지하는 단정한 빈 상태 플레이스홀더
  Widget _buildEmptyPlaceholder() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '등록된 일정이 없어요',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
