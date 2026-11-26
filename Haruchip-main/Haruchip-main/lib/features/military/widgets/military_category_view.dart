import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart' show planItemsByCategoryProvider;
import '../../shared/widgets/add_event_bottom_sheet.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/military_rank.dart';
import '../models/military_service.dart';
import '../providers/military_provider.dart';

/// 군대(곰신) 카테고리 전용 파스텔 무테두리 컴팩트 대시보드 뷰
///
/// 1) 상단 대표 프로필 + 소수점 6자리 실시간 복무율 게이지 (무스크롤 컴팩트 피팅)
/// 2) 6대 핵심 복무 지표 2x3 컴팩트 그리드
/// 3) 호봉/계급 2단계 진급 타임라인 바 (인라인 날짜 터치 수정 & 동적 재계산)
/// 4) 휴가·외박·외출·면회 관리 엔진 (단일/연속 자동 일수 계산 + 캘린더 연속 바 동기화)
/// 5) 군대 전용 D-Day 리스트 (추가/편집 + 섹션 숨김/순서 편집 연동)
class MilitaryCategoryView extends ConsumerStatefulWidget {
  const MilitaryCategoryView({super.key});

  @override
  ConsumerState<MilitaryCategoryView> createState() =>
      _MilitaryCategoryViewState();
}

class _MilitaryCategoryViewState extends ConsumerState<MilitaryCategoryView> {
  Timer? _liveTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _liveTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _editHobongDate(
    BuildContext context,
    HobongInfo hobongInfo,
  ) async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: hobongInfo.nextHobongDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null && mounted) {
      ref.read(militaryServiceProvider.notifier).setCustomNextHobongDate(picked);
    }
  }

  Future<void> _editRankDate(
    BuildContext context,
    RankPromotionProgress rankProgress,
  ) async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: rankProgress.targetDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null && mounted) {
      ref.read(militaryServiceProvider.notifier).setCustomNextRankDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(militaryServiceProvider);
    final dischargeDday = ref.watch(militaryDischargeDdayProvider);
    final nextLeaveDday = ref.watch(militaryLeaveDdayProvider);
    final militaryPlans = ref.watch(planItemsByCategoryProvider('military'));

    final effectiveDischarge = service.effectiveDischargeDate;
    final today = DateTime(_now.year, _now.month, _now.day);
    final enlistDay = DateTime(
      service.enlistDate.year,
      service.enlistDate.month,
      service.enlistDate.day,
    );
    final dischargeDay = DateTime(
      effectiveDischarge.year,
      effectiveDischarge.month,
      effectiveDischarge.day,
    );

    final totalDays = dischargeDay.difference(enlistDay).inDays.clamp(1, 99999);
    final servedDays =
        (today.difference(enlistDay).inDays + 1).clamp(0, totalDays);
    final remainingDays = dischargeDay.difference(today).inDays.clamp(0, 99999);

    final exactProgress = calculateExactServiceProgress(
      enlistDate: service.enlistDate,
      dischargeDate: effectiveDischarge,
      now: _now,
    );
    final exactPercentStr = (exactProgress * 100).toStringAsFixed(6);

    final hobongInfo = calculateHobongInfo(
      service.enlistDate,
      now: _now,
      customNextHobongDate: service.customNextHobongDate,
    );
    final rankProgress = calculateRankPromotionProgress(
      service.enlistDate,
      effectiveDischarge,
      now: _now,
      customNextRankDate: service.customNextRankDate,
    );
    final remainingWorkdays = calculateRemainingWorkdays(
      dischargeDate: effectiveDischarge,
      leaveRanges: service.leaves
          .map((l) => (startDate: l.startDate, endDate: l.endDate))
          .toList(),
      today: today,
    );

    final nextRankDdayStr = rankProgress.nextRank != null
        ? (rankProgress.dDay == 0 ? 'D-Day' : 'D-${rankProgress.dDay}')
        : '병장 만기';

    final sortedLeaves = List<MilitaryLeaveRecord>.from(service.leaves)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final customDdayItems = militaryPlans
        .where((item) => !item.id.startsWith('mil-leave-'))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final orderedSections = service.sectionOrder.isNotEmpty
        ? service.sectionOrder
        : kDefaultMilitarySectionOrder;

    final sectionWidgets = <Widget>[];
    for (final secKey in orderedSections) {
      if (service.hiddenSections.contains(secKey)) continue;
      Widget? section;
      switch (secKey) {
        case 'metrics':
          section = _buildSixMetricsGrid(
            totalDays: totalDays,
            servedDays: servedDays,
            remainingDays: remainingDays,
            nextRankDdayStr: nextRankDdayStr,
            remainingWorkdays: remainingWorkdays,
            nextLeaveDday: nextLeaveDday ?? '미등록',
          );
          break;
        case 'timeline':
          section = _buildPromotionTimelineCard(
            context: context,
            service: service,
            hobongInfo: hobongInfo,
            rankProgress: rankProgress,
          );
          break;
        case 'leaves':
          section = _buildLeaveManagementSection(
            context: context,
            service: service,
            leaves: sortedLeaves,
            today: today,
          );
          break;
        case 'ddayList':
          section = _buildMilitaryDdayListSection(
            context: context,
            items: customDdayItems,
            today: today,
          );
          break;
      }
      if (section != null) {
        sectionWidgets.add(const SizedBox(height: 9));
        sectionWidgets.add(section);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 상단 대표 프로필 & 실시간 정밀 복무율 게이지 (무스크롤 컴팩트 피팅)
        _buildHeroProfileCard(
          context: context,
          service: service,
          hobongInfo: hobongInfo,
          effectiveDischarge: effectiveDischarge,
          dischargeDday: dischargeDday,
          exactProgress: exactProgress,
          exactPercentStr: exactPercentStr,
        ),
        ...sectionWidgets,
      ],
    );
  }

  Widget _buildHeroProfileCard({
    required BuildContext context,
    required MilitaryService service,
    required HobongInfo hobongInfo,
    required DateTime effectiveDischarge,
    required String dischargeDday,
    required double exactProgress,
    required String exactPercentStr,
  }) {
    final rankBadgeText =
        '${service.branch.labelKo} ${hobongInfo.currentRank.labelKo} ${hobongInfo.currentHobong}호봉';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('military_hero_profile_card'),
        onTap: () => showMilitaryProfileEditSheet(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF3FAF4),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 베레모 곰돌이 벡터 아바타 (컴팩트 44x44)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const HaruChipIconViewer(
                          iconKey: 'simple_bear',
                          size: 28,
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.chipYellowBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            size: 11,
                            color: AppColors.chipYellowText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // 닉네임 + 계급/호봉 뱃지 + 입대~전역일
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                service.soldierName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.heading2.copyWith(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.protoHeading,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                rankBadgeText,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E6B3E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_fmtDate(service.enlistDate)} ~ ${_fmtDate(effectiveDischarge)} ($dischargeDday)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // 실시간 정밀 복무율 수치 (소수점 6자리)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '실시간 복무율',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  Text(
                    '$exactPercentStr%',
                    key: const Key('military_live_percent_text'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.chipYellowText,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // 부드러운 크림 옐로우 트랙 + 파스텔 옐로우~세이지 그린 채움 바
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: const Color(0xFFFFF8E1),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: exactProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.chipYellowBg,
                            Color(0xFF81C784),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSixMetricsGrid({
    required int totalDays,
    required int servedDays,
    required int remainingDays,
    required String nextRankDdayStr,
    required int remainingWorkdays,
    required String nextLeaveDday,
  }) {
    final metrics = [
      (label: '전체 복무일', value: '$totalDays일', accent: const Color(0xFF4B5563)),
      (label: '현재 복무일', value: '$servedDays일째', accent: const Color(0xFF2E6B3E)),
      (label: '남은 복무일', value: '$remainingDays일', accent: AppColors.chipYellowText),
      (label: '계급 진급일', value: nextRankDdayStr, accent: const Color(0xFF2E6B3E)),
      (label: '남은 일과일', value: '$remainingWorkdays일', accent: AppColors.chipYellowText),
      (label: '다음 휴가일', value: nextLeaveDday, accent: const Color(0xFFD97706)),
    ];

    return GridView.builder(
      key: const Key('military_metrics_section'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.82,
      ),
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  m.value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: m.accent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromotionTimelineCard({
    required BuildContext context,
    required MilitaryService service,
    required HobongInfo hobongInfo,
    required RankPromotionProgress rankProgress,
  }) {
    final hobongPercent = (hobongInfo.progress * 100).toStringAsFixed(2);
    final rankPercent = (rankProgress.progress * 100).toStringAsFixed(2);
    final hobongDdayLabel =
        hobongInfo.dDay == 0 ? 'D-Day' : 'D-${hobongInfo.dDay}';
    final rankDdayLabel =
        rankProgress.dDay == 0 ? 'D-Day' : 'D-${rankProgress.dDay}';
    final rankTitle = rankProgress.nextRank != null
        ? '${rankProgress.currentRank.labelKo} → ${rankProgress.nextRank!.labelKo} 진급 $rankDdayLabel'
        : '병장 만기 전역 $rankDdayLabel';

    return Container(
      key: const Key('military_timeline_section'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '계급 · 호봉 승급 타임라인',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.protoHeading,
                ),
              ),
              Text(
                '탭하여 날짜 수정',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1) 호봉 승급 바 (탭 -> 인라인 날짜 피커로 수정)
          _buildTimelineBarRow(
            rowKey: const Key('military_hobong_bar'),
            title: '${hobongInfo.nextHobong}호봉 승급 $hobongDdayLabel',
            percentText: '$hobongPercent%',
            dateText: _fmtDate(hobongInfo.nextHobongDate),
            progress: hobongInfo.progress,
            trackColor: const Color(0xFFFFF8E1),
            fillColor: AppColors.chipYellowBg,
            isCustomized: service.customNextHobongDate != null,
            onTap: () => _editHobongDate(context, hobongInfo),
            onReset: service.customNextHobongDate != null
                ? () => ref
                    .read(militaryServiceProvider.notifier)
                    .setCustomNextHobongDate(null)
                : null,
          ),
          const SizedBox(height: 8),

          // 2) 계급 진급 바 (탭 -> 인라인 날짜 피커로 수정)
          _buildTimelineBarRow(
            rowKey: const Key('military_rank_bar'),
            title: rankTitle,
            percentText: '$rankPercent%',
            dateText: _fmtDate(rankProgress.targetDate),
            progress: rankProgress.progress,
            trackColor: const Color(0xFFE8F5E9),
            fillColor: const Color(0xFF81C784),
            isCustomized: service.customNextRankDate != null,
            onTap: () => _editRankDate(context, rankProgress),
            onReset: service.customNextRankDate != null
                ? () => ref
                    .read(militaryServiceProvider.notifier)
                    .setCustomNextRankDate(null)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBarRow({
    required Key rowKey,
    required String title,
    required String percentText,
    required String dateText,
    required double progress,
    required Color trackColor,
    required Color fillColor,
    required bool isCustomized,
    required VoidCallback onTap,
    VoidCallback? onReset,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$title · $percentText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  if (isCustomized && onReset != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onReset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '복원',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6.5,
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilitaryDdayListSection({
    required BuildContext context,
    required List<PlanItem> items,
    required DateTime today,
  }) {
    return Container(
      key: const Key('military_dday_list_section'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'D-Day 리스트',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.protoHeading,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('military_add_dday_inline_button'),
                onPressed: () => showAddEventBottomSheet(
                  context,
                  categoryKey: 'military',
                ),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text(
                  'D-Day 추가',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipYellowBg,
                  foregroundColor: AppColors.chipYellowText,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '등록된 군대 D-Day 일정이 없습니다. (수료식 · 면회 등)',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
              ),
            )
          else
            for (final item in items) ...[
              _buildMilitaryDdayTile(context, item, today),
              const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _buildMilitaryDdayTile(
    BuildContext context,
    PlanItem item,
    DateTime today,
  ) {
    final target = DateTime(item.date.year, item.date.month, item.date.day);
    final diff = target.difference(today).inDays;
    final dDayText = diff == 0
        ? 'D-Day'
        : (diff > 0 ? 'D-$diff' : 'D+${diff.abs()}');
    final isPast = diff < 0;

    return InkWell(
      onTap: () => showAddEventBottomSheet(
        context,
        categoryKey: 'military',
        existingItem: item,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _fmtDate(item.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: isPast
                    ? const Color(0xFFF1F5F9)
                    : AppColors.chipYellowBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dDayText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isPast
                      ? const Color(0xFF94A3B8)
                      : AppColors.chipYellowText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveManagementSection({
    required BuildContext context,
    required MilitaryService service,
    required List<MilitaryLeaveRecord> leaves,
    required DateTime today,
  }) {
    return Container(
      key: const Key('military_leaves_section'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '휴가 · 외박 · 외출 관리',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.protoHeading,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('military_add_leave_button'),
                onPressed: () => showMilitaryLeaveModal(context, ref),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text(
                  '출타 등록',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipYellowBg,
                  foregroundColor: AppColors.chipYellowText,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 휴가 통계 요약 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FBF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLeaveStatChip(
                  '남은 정기휴가',
                  '${service.remainingVacationDays}일',
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0xFFDCECE0),
                ),
                _buildLeaveStatChip(
                  '남은 포상휴가',
                  '${service.remainingRewardVacationDays}일',
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0xFFDCECE0),
                ),
                _buildLeaveStatChip(
                  '외박/외출',
                  '${service.overnightAndOutingCount}회',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (leaves.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '등록된 휴가·외박·외출 일정이 없습니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            )
          else
            for (final leave in leaves) ...[
              _buildLeaveItemTile(context, leave, today),
              const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _buildLeaveStatChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E6B3E),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveItemTile(
    BuildContext context,
    MilitaryLeaveRecord leave,
    DateTime today,
  ) {
    final s = DateTime(
      leave.startDate.year,
      leave.startDate.month,
      leave.startDate.day,
    );
    final diff = s.difference(today).inDays;
    final dDayText = diff == 0
        ? 'D-Day'
        : (diff > 0 ? 'D-$diff' : 'D+${diff.abs()}');
    final isPast = diff < 0;
    final dateRangeText = leave.isSingleDay
        ? _fmtDate(leave.startDate)
        : '${_fmtDate(leave.startDate)} ~ ${_fmtDate(leave.endDate)}';

    return InkWell(
      onTap: () => showMilitaryLeaveModal(context, ref, existing: leave),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(leave.type.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leave.summaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateRangeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isPast
                    ? const Color(0xFFF1F5F9)
                    : AppColors.chipYellowBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                dDayText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isPast
                      ? const Color(0xFF94A3B8)
                      : AppColors.chipYellowText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 군 복무 정보(닉네임·군종·입대일·전역일·단축일수) 컴팩트 화이트 수정 바텀시트
Future<void> showMilitaryProfileEditSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final current = ref.read(militaryServiceProvider);
  final nameCtrl = TextEditingController(text: current.soldierName);
  final shortenedCtrl = TextEditingController(
    text: current.shortenedDays > 0 ? '${current.shortenedDays}' : '',
  );
  MilitaryBranch branch = current.branch;
  DateTime enlistDate = current.enlistDate;
  DateTime dischargeDate = current.dischargeDate;

  String fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '복무 정보 설정',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 닉네임
                  const Text('군인 닉네임',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: '예: 용이, 우리 군인',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 군종 선택 (육군 18 / 해병 18 / 해군 20 / 공군 21 / 사회복무요원 21)
                  const Text('군종 선택',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final b in MilitaryBranch.values)
                        ChoiceChip(
                          label: Text(
                            '${b.labelKo} (${totalServiceMonths[b]}개월)',
                          ),
                          selected: branch == b,
                          showCheckmark: false,
                          backgroundColor: const Color(0xFFF8F9FA),
                          selectedColor: AppColors.chipYellowBg,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: branch == b
                                ? AppColors.chipYellowText
                                : const Color(0xFF4B5563),
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              branch = b;
                              dischargeDate = defaultDischargeDate(enlistDate, b);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 입대일 / 전역일
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showHaruDatePicker(
                              context,
                              initialDate: enlistDate,
                              firstDate: DateTime(2015),
                              lastDate: DateTime(2035),
                              title: '입대일 선택',
                            );
                            if (picked != null) {
                              setModalState(() {
                                enlistDate = picked;
                                dischargeDate =
                                    defaultDischargeDate(picked, branch);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('입대일',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF9CA3AF))),
                                const SizedBox(height: 2),
                                Text(
                                  fmt(enlistDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showHaruDatePicker(
                              context,
                              initialDate: dischargeDate,
                              firstDate: enlistDate,
                              lastDate: DateTime(2040),
                              title: '전역일 선택',
                            );
                            if (picked != null) {
                              setModalState(() => dischargeDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('전역일',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF9CA3AF))),
                                const SizedBox(height: 2),
                                Text(
                                  fmt(dischargeDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 단축일수
                  const Text('단축일수 (선택, 일 단위)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: shortenedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '예: 0',
                      suffixText: '일',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chipYellowBg,
                      foregroundColor: AppColors.chipYellowText,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final shortened =
                          int.tryParse(shortenedCtrl.text.trim()) ?? 0;
                      ref.read(militaryServiceProvider.notifier).setService(
                            enlistDate: enlistDate,
                            dischargeDate: dischargeDate,
                            branch: branch,
                            soldierName: nameCtrl.text.trim().isEmpty
                                ? '우리 군인'
                                : nameCtrl.text.trim(),
                            shortenedDays: shortened.clamp(0, 365),
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      '저장 완료',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  nameCtrl.dispose();
  shortenedCtrl.dispose();
}

/// 휴가 · 외박 · 외출 · 직접입력 등록/수정 바텀시트
Future<void> showMilitaryLeaveModal(
  BuildContext context,
  WidgetRef ref, {
  MilitaryLeaveRecord? existing,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  MilitaryLeaveType selectedType =
      existing?.type ?? MilitaryLeaveType.regular;
  final titleCtrl = TextEditingController(
    text: existing?.title ?? selectedType.labelKo,
  );
  DateTime startDate = existing?.startDate ?? today;
  DateTime endDate = existing?.endDate ?? today;

  String fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final days = (DateTime(endDate.year, endDate.month, endDate.day)
                    .difference(
                        DateTime(startDate.year, startDate.month, startDate.day))
                    .inDays +
                1)
            .clamp(1, 365);

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing != null ? '출타 일정 수정' : '출타 일정 등록',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        if (existing != null)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(militaryServiceProvider.notifier)
                                  .deleteLeave(existing.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              '삭제',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 출타 4대 분류 + 직접입력 칩
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final type in MilitaryLeaveType.values)
                          ChoiceChip(
                            label: Text(
                              type == MilitaryLeaveType.custom
                                  ? '+ 직접입력'
                                  : type.labelKo,
                            ),
                            selected: selectedType == type,
                            showCheckmark: false,
                            backgroundColor: const Color(0xFFF8F9FA),
                            selectedColor: AppColors.chipYellowBg,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: selectedType == type
                                  ? AppColors.chipYellowText
                                  : const Color(0xFF4B5563),
                            ),
                            onSelected: (_) {
                              setModalState(() {
                                selectedType = type;
                                if (type != MilitaryLeaveType.custom) {
                                  titleCtrl.text = type.labelKo;
                                } else {
                                  titleCtrl.clear();
                                }
                                if (type == MilitaryLeaveType.outing) {
                                  endDate = startDate;
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 일정 제목 (직접입력 또는 커스텀 명칭)
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: '예: 신병 위로휴가, 면회',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 시작일 ~ 종료일 + 자동 계산 일수
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showHaruDatePicker(
                                context,
                                initialDate: startDate,
                                firstDate: DateTime(2015),
                                lastDate: DateTime(2040),
                                title: '시작일 선택',
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = picked;
                                  if (selectedType == MilitaryLeaveType.outing ||
                                      endDate.isBefore(picked)) {
                                    endDate = picked;
                                  }
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('시작일',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF9CA3AF))),
                                  const SizedBox(height: 2),
                                  Text(
                                    fmt(startDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('~',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showHaruDatePicker(
                                context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2040),
                                title: '종료일 선택',
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('종료일',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF9CA3AF))),
                                  const SizedBox(height: 2),
                                  Text(
                                    fmt(endDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        days == 1
                            ? '당일 일정 · 1일 사용 (칩 캘린더 자동 연동)'
                            : '${days - 1}박 $days일 · 총 $days일 사용 (칩 캘린더 연속 바 자동 연동)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E6B3E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton(
                      key: const Key('military_leave_submit_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final title = titleCtrl.text.trim().isEmpty
                            ? selectedType.labelKo
                            : titleCtrl.text.trim();
                        final record = MilitaryLeaveRecord(
                          id: existing?.id ??
                              'lv_${DateTime.now().microsecondsSinceEpoch}',
                          type: selectedType,
                          title: title,
                          startDate: startDate,
                          endDate: endDate.isBefore(startDate)
                              ? startDate
                              : endDate,
                        );
                        final notifier =
                            ref.read(militaryServiceProvider.notifier);
                        if (existing != null) {
                          notifier.updateLeave(record);
                        } else {
                          notifier.addLeave(record);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        existing != null ? '수정 완료' : '등록 완료',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  titleCtrl.dispose();
}

/// 곰신-군인 실시간 공유 초대 바텀시트
Future<void> showMilitaryGomshinShareModal(
  BuildContext context,
  WidgetRef ref,
) async {
  final myCode = ref.read(militaryServiceProvider.notifier).ensureShareCode();
  final codeCtrl = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final service = ref.watch(militaryServiceProvider);
        final isConnected = service.connectedPartnerCode != null &&
            service.connectedPartnerCode!.isNotEmpty;

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '곰신 · 군인 실시간 공유',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '초대 코드를 연결하면 복무율, 진급일, 휴가 일정이 양방향으로 실시간 동기화됩니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),

                  // 내 난수 초대 코드 박스
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FBF7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '내 초대 코드',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                myCode,
                                key: const Key('military_my_invite_code'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: Color(0xFF2E6B3E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.chipYellowBg,
                            foregroundColor: AppColors.chipYellowText,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: myCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('초대 코드가 복사되었습니다.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            '복사',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            size: 18,
                            color: Color(0xFF2E6B3E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '실시간 연동 중 (${service.connectedPartnerCode})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E6B3E),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(militaryServiceProvider.notifier)
                                  .disconnectPartnerRoom();
                            },
                            child: const Text(
                              '해제',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: '상대방 초대 코드 입력 (예: MIL-XXXX-XXXX)',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      key: const Key('military_connect_partner_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final input = codeCtrl.text.trim();
                        if (input.isEmpty) return;
                        await ref
                            .read(militaryServiceProvider.notifier)
                            .connectPartnerRoom(input);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('곰신 · 군인 실시간 동기화가 연결되었습니다.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        '실시간 공유 연결하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  codeCtrl.dispose();
}

/// 군대 카테고리 상단 앱바 [+] 터치 시: [출타 등록] vs [일반 D-Day 등록] 선택 시트
Future<void> showMilitaryAddActionSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '군대 일정 추가',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.protoHeading,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: const Color(0xFFF6FBF7),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const Key('military_choice_add_leave'),
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(ctx);
                  showMilitaryLeaveModal(context, ref);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Text('🌴', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '출타 등록',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.protoHeading,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '정기휴가 · 포상휴가 · 외박 · 외출 (일수 자동 차감)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const Key('military_choice_add_dday'),
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddEventBottomSheet(context, categoryKey: 'military');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Text('📅', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '일반 D-Day 등록',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.protoHeading,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '수료식 · 면회 · 기념일 등 자유로운 D-Day 일정',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 군대 카테고리 섹션 순서 & 숨김 관리 바텀시트 (드래그 순서 변경 + 숨김 토글)
Future<void> showMilitarySectionManagementModal(
  BuildContext context,
  WidgetRef ref,
) async {
  final current = ref.read(militaryServiceProvider);
  final order = List<String>.from(
    current.sectionOrder.isNotEmpty
        ? current.sectionOrder
        : kDefaultMilitarySectionOrder,
  );
  final hidden = Set<String>.from(current.hiddenSections);

  const sectionLabels = <String, ({String title, String subtitle})>{
    'metrics': (title: '복무 지표', subtitle: '전체·현재·남은 복무일 및 일과일 6대 지표'),
    'timeline': (title: '진급 타임라인', subtitle: '호봉 승급 및 계급 진급 프로그레스 바'),
    'leaves': (title: '출타 관리', subtitle: '정기휴가 · 포상휴가 · 외박 · 외출 리스트'),
    'ddayList': (title: 'D-Day 리스트', subtitle: '수료식 · 면회 등 군대 전용 D-Day 목록'),
  };

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '군대 섹션 순서 및 숨김 관리',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.protoHeading,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '드래그하여 순서를 바꾸거나 스위치를 꺼서 원하는 섹션을 숨길 수 있어요.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 248),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: order.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setModalState(() {
                      final moved = order.removeAt(oldIndex);
                      order.insert(newIndex, moved);
                    });
                  },
                  itemBuilder: (context, index) {
                    final key = order[index];
                    final meta = sectionLabels[key] ??
                        (title: key, subtitle: '');
                    final isVisible = !hidden.contains(key);
                    return Container(
                      key: ValueKey('mil_sec_$key'),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                size: 20,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.protoHeading,
                                  ),
                                ),
                                Text(
                                  meta.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            key: Key('military_section_toggle_$key'),
                            value: isVisible,
                            activeTrackColor: AppColors.chipYellowBg,
                            activeThumbColor: AppColors.chipYellowText,
                            onChanged: (val) {
                              setModalState(() {
                                if (val) {
                                  hidden.remove(key);
                                } else {
                                  hidden.add(key);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                key: const Key('military_section_save_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipYellowBg,
                  foregroundColor: AppColors.chipYellowText,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ref.read(militaryServiceProvider.notifier).updateSectionConfig(
                        order: order,
                        hidden: hidden,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text(
                  '적용하기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
