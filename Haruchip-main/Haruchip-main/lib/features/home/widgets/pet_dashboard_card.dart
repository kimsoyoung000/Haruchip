import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/controllers/pet_category_controller.dart';
import '../../categories/widgets/pet_profile_card_widget.dart';
import '../../plan/models/plan_item.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

/// 대시보드 반려동물 카드 — CLAUDE.md §8 & 고도화 요구사항 §2.6.
class PetDashboardCard extends StatelessWidget {
  const PetDashboardCard({super.key, required this.items});

  final List<PlanItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isNotEmpty) {
      final first = items.first;
      final careSchedules = items.skip(1).map((item) {
        return PetCareSchedule(
          id: item.id,
          title: item.title,
          type: item.title.contains('사료')
              ? PetCareType.feed
              : (item.title.contains('산책')
                  ? PetCareType.walk
                  : (item.title.contains('병원') || item.title.contains('접종')
                      ? PetCareType.hospital
                      : PetCareType.custom)),
          targetDate: item.date,
        );
      }).toList();

      return PetProfileCardWidget(
        petName: first.title,
        birthOrAdoptionDate: first.date,
        photoUrl: first.photoUrl,
        careSchedules: careSchedules,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.protoCardSelectedBg, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.protoCardSelectedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🐾', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '반려동물 기록',
                  style: AppTypography.cardLabel.copyWith(
                    color: AppColors.protoHeading,
                  ),
                ),
              ),
              InkWell(
                onTap: () => showAddEventBottomSheet(context, categoryKey: 'pet'),
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: AppColors.protoStepLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '아직 등록된 반려동물이 없어요',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
