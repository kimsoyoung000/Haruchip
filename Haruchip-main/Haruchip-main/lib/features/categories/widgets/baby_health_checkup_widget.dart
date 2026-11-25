import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../data/baby_health_database.dart';
import '../models/baby_profile.dart';

/// 국가 영유아 건강검진 (1~8차) 위젯 + 간략히 보기/펼치기 아코디언
class BabyHealthCheckupWidget extends StatefulWidget {
  const BabyHealthCheckupWidget({
    super.key,
    required this.profile,
    required this.onToggleCheckup,
    this.onOpenAddGrowthRecord,
  });

  final BabyProfile profile;
  final ValueChanged<HealthCheckupDose> onToggleCheckup;
  final VoidCallback? onOpenAddGrowthRecord;

  @override
  State<BabyHealthCheckupWidget> createState() =>
      _BabyHealthCheckupWidgetState();
}

class _BabyHealthCheckupWidgetState extends State<BabyHealthCheckupWidget> {
  bool _isExpanded = false; // 기본값: 간략히 보기

  List<HealthCheckupDose> get _effectiveDoses {
    final existing = widget.profile.checkupDoses;
    if (existing.isNotEmpty) return existing;
    return kDefaultHealthCheckupDoses;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  /// 간략히 보기용 대표 검진 1건 추출 (검진 진행 중/다가오는 미완료 1건 우선, 없으면 최근 완료 1건)
  HealthCheckupDose? _pickHeadlineCheckup(
      List<HealthCheckupDose> doses, DateTime today) {
    if (doses.isEmpty) return null;
    for (final dose in doses) {
      if (dose.isCompleted) continue;
      final endDate = widget.profile.birthDate.add(Duration(days: dose.endDays));
      if (!endDate.isBefore(today)) return dose;
    }
    final uncompleted = doses.where((d) => !d.isCompleted).toList();
    if (uncompleted.isNotEmpty) return uncompleted.first;
    return doses.last;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doses = _effectiveDoses;
    final completedCount = doses.where((d) => d.isCompleted).length;
    final headline = _pickHeadlineCheckup(doses, today);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 + 완료 카운트 + [간략히 보기 / 펼치기] 토글
          Row(
            children: [
              const Text('🩺', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '국가 영유아 건강검진 (1~8차)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.protoHeading,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$completedCount/${doses.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                key: const Key('baby_checkup_toggle_button'),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.chipYellowText,
                ),
                child: Text(
                  _isExpanded ? '간략히 보기' : '펼치기',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.chipYellowText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. 아코디언 본문 (간략히 보기: 대표 1건 / 펼치기: 전체 1~8차)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? (headline == null
                    ? const SizedBox.shrink()
                    : _buildSlimCheckupRow(headline, today))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: doses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) =>
                            _buildSlimCheckupRow(doses[index], today),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 12, color: Color(0xFFB45309)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '출처: 국민건강보험공단 영유아 건강검진 표준 일정표 기준 (1~8차)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimCheckupRow(HealthCheckupDose dose, DateTime today) {
    final startDate =
        widget.profile.birthDate.add(Duration(days: dose.startDays));
    final endDate = widget.profile.birthDate.add(Duration(days: dose.endDays));

    final isPeriodActive =
        !today.isBefore(startDate) && !today.isAfter(endDate);
    final isUpcoming = today.isBefore(startDate);

    String badgeText;
    Color badgeBg;
    Color badgeTextClr;

    if (dose.isCompleted) {
      badgeText = '검진 완료';
      badgeBg = const Color(0xFFE2E8F0);
      badgeTextClr = const Color(0xFF64748B);
    } else if (isPeriodActive) {
      final daysLeft = endDate.difference(today).inDays;
      badgeText = '마감 D-$daysLeft';
      badgeBg = const Color(0xFFFEF2F2);
      badgeTextClr = const Color(0xFFDC2626);
    } else if (isUpcoming) {
      final startLeft = startDate.difference(today).inDays;
      badgeText = 'D-$startLeft';
      badgeBg = AppColors.chipYellowBg.withValues(alpha: 0.75);
      badgeTextClr = AppColors.chipYellowText;
    } else {
      badgeText = '기간 경과';
      badgeBg = const Color(0xFFF1F5F9);
      badgeTextClr = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dose.isCompleted
            ? const Color(0xFFF8FAFC)
            : (isPeriodActive
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFFAFAFA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: dose.isCompleted,
              activeColor: const Color(0xFFD97706),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              onChanged: (_) => widget.onToggleCheckup(dose),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${dose.stage}차 검진',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dose.isCompleted
                            ? Colors.grey.shade600
                            : AppColors.protoHeading,
                        decoration: dose.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '(${dose.periodLabel})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(startDate)} ~ ${_formatDate(endDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: dose.isCompleted
                        ? Colors.grey.shade500
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: badgeTextClr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
