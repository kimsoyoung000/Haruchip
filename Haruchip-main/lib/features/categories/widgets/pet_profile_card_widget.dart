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
                          border: Border.all(
                            color: _selectedIcon == item.icon
                                ? AppColors.protoCardSelectedBorder
                                : Colors.transparent,
                            width: 2,
                          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.protoCardSelectedBg, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.photoUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.protoCardSelectedBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(_selectedIcon, style: const TextStyle(fontSize: 28)),
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
                        child: const Icon(Icons.edit, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
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
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.protoCardSelectedBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '패밀리 카드 🐾',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.protoCardSelectedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysCount > 0 ? '함께한 지 D+$daysCount일째' : '반려동물 신분증 카드',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 케어 일정 D-Day 칩 연동 섹션
          if (widget.careSchedules.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.protoCardBorder),
            const SizedBox(height: 10),
            Text(
              '🍖 케어 D-Day 일정 칩',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoSubtitle,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.protoCardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(schedule.type.defaultEmoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            schedule.title,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.protoCardText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.protoButtonBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dDayLabel,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
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
