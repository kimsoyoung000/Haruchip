import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../controllers/baby_category_controller.dart';
import '../data/baby_health_database.dart';
import '../models/baby_profile.dart';

/// 국가 표준 필수 예방접종 타임라인 위젯 (KCDA 35회 표준일정표 + 간략히 보기/펼치기 아코디언)
class BabyVaccineTimelineWidget extends StatefulWidget {
  const BabyVaccineTimelineWidget({
    super.key,
    required this.profile,
    required this.onToggleVaccine,
    required this.onUpdateVaccine,
  });

  final BabyProfile profile;
  final ValueChanged<VaccineDose> onToggleVaccine;
  final ValueChanged<VaccineDose> onUpdateVaccine;

  @override
  State<BabyVaccineTimelineWidget> createState() =>
      _BabyVaccineTimelineWidgetState();
}

class _BabyVaccineTimelineWidgetState extends State<BabyVaccineTimelineWidget> {
  bool _isExpanded = false; // 기본값: 간략히 보기
  int _tabIndex = 0; // 0: 미접종, 1: 완료, 2: 전체, 3: 0~6개월, 4: 12~36개월, 5: 만 4~12세
  static const _controller = BabyCategoryController();

  List<VaccineDose> get _effectiveDoses {
    final existing = widget.profile.vaccineDoses;
    if (existing.isNotEmpty) return existing;
    return kDefaultVaccineDoses;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calculateDdayBadge(DateTime targetDate, bool isCompleted) {
    if (isCompleted) return '접종 완료';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = target.difference(today).inDays;

    if (diff > 0) return 'D-$diff';
    if (diff == 0) return 'D-Day';
    return 'D+${-diff}';
  }

  /// 간략히 보기용 대표 일정 1건 추출 (다가오는 미접종 1건 우선, 모두 완료 시 가장 최근 완료 1건)
  VaccineDose? _pickHeadlineDose(List<VaccineDose> allDoses) {
    if (allDoses.isEmpty) return null;
    final uncompleted = allDoses.where((d) => !d.isCompleted).toList()
      ..sort((a, b) {
        final dateA = _controller.calculateVaccineDoseTargetDate(
            widget.profile.birthDate, a);
        final dateB = _controller.calculateVaccineDoseTargetDate(
            widget.profile.birthDate, b);
        return dateA.compareTo(dateB);
      });
    if (uncompleted.isNotEmpty) return uncompleted.first;

    final completed = allDoses.where((d) => d.isCompleted).toList()
      ..sort((a, b) {
        final da = a.completedDate ??
            _controller.calculateVaccineDoseTargetDate(
                widget.profile.birthDate, a);
        final db = b.completedDate ??
            _controller.calculateVaccineDoseTargetDate(
                widget.profile.birthDate, b);
        return db.compareTo(da);
      });
    return completed.isNotEmpty ? completed.first : allDoses.first;
  }

  @override
  Widget build(BuildContext context) {
    final allDoses = _effectiveDoses;
    final completedCount = allDoses.where((d) => d.isCompleted).length;
    final totalCount = allDoses.length;
    final uncompletedCount = totalCount - completedCount;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final headlineDose = _pickHeadlineDose(allDoses);

    List<VaccineDose> filtered;
    switch (_tabIndex) {
      case 0:
        filtered = allDoses.where((d) => !d.isCompleted).toList();
        break;
      case 1:
        filtered = allDoses.where((d) => d.isCompleted).toList();
        break;
      case 2:
        filtered = List.from(allDoses);
        break;
      case 3:
        filtered = allDoses.where((d) => d.recommendedAgeMonths <= 6).toList();
        break;
      case 4:
        filtered = allDoses
            .where((d) =>
                d.recommendedAgeMonths >= 12 && d.recommendedAgeMonths <= 36)
            .toList();
        break;
      case 5:
        filtered = allDoses.where((d) => d.recommendedAgeMonths >= 48).toList();
        break;
      default:
        filtered = List.from(allDoses);
    }

    if (_tabIndex != 0 && _tabIndex != 1) {
      filtered.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        final dateA = _controller.calculateVaccineDoseTargetDate(
            widget.profile.birthDate, a);
        final dateB = _controller.calculateVaccineDoseTargetDate(
            widget.profile.birthDate, b);
        return dateA.compareTo(dateB);
      });
    } else if (_tabIndex == 0) {
      filtered.sort((a, b) {
        final dateA = _controller.calculateVaccineDoseTargetDate(
            widget.profile.birthDate, a);
        final dateB = _controller.calculateVaccineDoseTargetDate(
            widget.profile.birthDate, b);
        return dateA.compareTo(dateB);
      });
    }

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
          // 1. 헤더 + 진행률 + [간략히 보기 / 펼치기] 토글
          Row(
            children: [
              const Text('💉', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '국가 표준 필수 예방접종',
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
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                key: const Key('baby_vaccine_toggle_button'),
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

          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),

          const SizedBox(height: 10),

          // 2. 아코디언 본문 (간략히 보기: 1건 슬림 바 / 펼치기: 전체 35회 리스트)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? (headlineDose == null
                    ? const SizedBox.shrink()
                    : _buildSlimVaccineRow(headlineDose))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTab(0, '미접종 ($uncompletedCount)'),
                            const SizedBox(width: 5),
                            _buildTab(1, '완료 ($completedCount)'),
                            const SizedBox(width: 5),
                            _buildTab(2, '전체 ($totalCount)'),
                            const SizedBox(width: 5),
                            _buildTab(3, '0~6개월'),
                            const SizedBox(width: 5),
                            _buildTab(4, '12~36개월'),
                            const SizedBox(width: 5),
                            _buildTab(5, '만 4~12세'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Text(
                            _tabIndex == 0
                                ? '🎉 모든 권장 필수 예방접종을 완료했습니다!'
                                : (_tabIndex == 1
                                    ? '아직 접종 완료된 항목이 없습니다.'
                                    : '해당 조건의 예방접종 항목이 없습니다.'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) =>
                              _buildSlimVaccineRow(filtered[index]),
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
                                size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '출처: 질병관리청(KCDA) 예방접종도우미 표준 예방접종 일정표 (35회)',
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

  Widget _buildSlimVaccineRow(VaccineDose dose) {
    final targetDate = _controller.calculateVaccineDoseTargetDate(
      widget.profile.birthDate,
      dose,
    );
    final badgeText = _calculateDdayBadge(targetDate, dose.isCompleted);
    final isDdayOrPast =
        !dose.isCompleted && targetDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dose.isCompleted
            ? const Color(0xFFF8FAFC)
            : (isDdayOrPast ? const Color(0xFFFFFBEB) : const Color(0xFFFAFAFA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: dose.isCompleted,
              activeColor: const Color(0xFF059669),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              onChanged: (_) => widget.onToggleVaccine(dose),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        dose.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dose.recommendedAgeLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dose.isCompleted && dose.completedDate != null
                      ? '접종일: ${_formatDate(dose.completedDate!)} · ${dose.disease}'
                      : '예정일: ${_formatDate(targetDate)} · ${dose.disease}',
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
              color: dose.isCompleted
                  ? const Color(0xFFECFDF5)
                  : (isDdayOrPast
                      ? AppColors.chipYellowBg
                      : const Color(0xFFE0F2FE)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: dose.isCompleted
                    ? const Color(0xFF059669)
                    : (isDdayOrPast
                        ? AppColors.chipYellowText
                        : const Color(0xFF0369A1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipYellowBg : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color:
                isSelected ? AppColors.chipYellowText : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
