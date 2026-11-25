import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../controllers/pet_category_controller.dart';

/// 반려동물 패밀리 프로필 (신분증 / 포토카드 형태) 위젯
class PetProfileCardWidget extends StatefulWidget {
  const PetProfileCardWidget({
    super.key,
    required this.petName,
    this.petIcon = '🐶',
    this.photoUrl,
    this.birthOrAdoptionDate,
    this.careSchedules = const [],
    this.onIconChanged,
  });

  final String petName;
  final String petIcon;
  final String? photoUrl;
  final DateTime? birthOrAdoptionDate;
  final List<PetCareSchedule> careSchedules;
  final ValueChanged<String>? onIconChanged;

  @override
  State<PetProfileCardWidget> createState() => _PetProfileCardWidgetState();
}

class _PetProfileCardWidgetState extends State<PetProfileCardWidget> {
  final _controller = const PetCategoryController();
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.petIcon;
  }

  void _showIconPickerModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final icons = _controller.getAvailableIcons();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.protoCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '반려동물 대표 아이콘 선택',
                style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in icons)
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedIcon = item.icon);
                        widget.onIconChanged?.call(item.icon);
                        Navigator.of(modalContext).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedIcon == item.icon
                              ? AppColors.protoCardSelectedBg
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                        
boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(
                              item.labelKo,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.protoCardText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysCount = 0;
    if (widget.birthOrAdoptionDate != null) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final start = DateTime(
        widget.birthOrAdoptionDate!.year,
        widget.birthOrAdoptionDate!.month,
        widget.birthOrAdoptionDate!.day,
      );
      daysCount = todayOnly.difference(start).inDays;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포토카드 / 신분증 상단 헤더
          Row(
            children: [
              GestureDetector(
                onTap: () => _showIconPickerModal(context),
                child: Stack(
                  children: [
                    if (widget.photoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          widget.photoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.protoCardSelectedBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_selectedIcon, style: const TextStyle(fontSize: 24)),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.protoHeading,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 9, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.petName,
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.protoHeading,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.protoCardSelectedBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '패밀리 카드 🐾',
                            style: AppTypography.caption.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.protoCardSelectedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      daysCount > 0 ? '함께한 지 D+$daysCount일째' : '반려동물 신분증 카드',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 케어 일정 D-Day 칩 연동 섹션
          if (widget.careSchedules.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.protoCardBorder),
            const SizedBox(height: 8),
            Text(
              '🍖 케어 D-Day 일정 칩',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoSubtitle,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final schedule in widget.careSchedules) ...[
                  Builder(builder: (context) {
                    final today = DateTime.now();
                    final todayOnly = DateTime(today.year, today.month, today.day);
                    final targetOnly = DateTime(
                      schedule.targetDate.year,
                      schedule.targetDate.month,
                      schedule.targetDate.day,
                    );
                    final diff = targetOnly.difference(todayOnly).inDays;
                    final dDayLabel = diff == 0 ? 'D-day' : (diff > 0 ? 'D-$diff' : 'D+${diff.abs()}');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.protoCardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(schedule.type.defaultEmoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            schedule.title,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.protoCardText,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.protoButtonBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dDayLabel,
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.protoButtonText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
