import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/widgets/baby_profile_card_widget.dart';
import '../../plan/models/plan_item.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

/// 대시보드 아기 카드 — CLAUDE.md §5.5 & 고도화 요구사항 §2.5.
class BabyDashboardCard extends StatelessWidget {
  const BabyDashboardCard({super.key, required this.items});

  final List<PlanItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isNotEmpty) {
      final first = items.first;
      return Column(
        children: [
          BabyProfileCardWidget(
            babyName: first.title,
            birthDate: first.date,
            photoUrl: first.photoUrl,
          ),
        ],
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
                child: const Text('👶', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '아기 성장 기록',
                  style: AppTypography.cardLabel.copyWith(
                    color: AppColors.protoHeading,
                  ),
                ),
              ),
              InkWell(
                onTap: () => showAddEventBottomSheet(context, categoryKey: 'baby'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.protoCardSelectedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ 추가',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.protoStepLabel,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '아직 등록된 아기 기록이 없어요',
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
