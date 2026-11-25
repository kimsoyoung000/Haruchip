import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../controllers/baby_category_controller.dart';

/// 아기 탄생일 성장 기록형 UI (원형 프로필 액자 & X개월 Y일째 변환 & 마일스톤 카드)
class BabyProfileCardWidget extends StatelessWidget {
  const BabyProfileCardWidget({
    super.key,
    required this.babyName,
    required this.birthDate,
    this.photoUrl,
  });

  final String babyName;
  final DateTime birthDate;
  final String? photoUrl;

  static final _controller = const BabyCategoryController();

  @override
  Widget build(BuildContext context) {
    final formattedAge = _controller.formatBabyAgeDetailed(birthDate);
    final milestones = _controller.getGrowthMilestones(birthDate);

    // 가장 가까운 다가올 마일스톤 찾기
    final upcomingMilestone = milestones.firstWhere(
      (m) => !m.isReached,
      orElse: () => milestones.last,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.protoCardSelectedBg, width: 1.5),
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
          Row(
            children: [
              // 원형 프로필 액자 (약 15% 축소: radius 24)
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9A9E).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: photoUrl != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(photoUrl!),
                      )
                    : const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.protoCardBg,
                        child: Text('👶', style: TextStyle(fontSize: 22)),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      babyName,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.protoHeading,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // N일째 (X개월 Y일째) 자동 변환 표시
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.protoCardSelectedBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        formattedAge,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.protoCardSelectedText,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 100일, 돌(365일) 주요 성장 마일스톤 카드
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.protoCoupleBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      '성장 마일스톤: ${upcomingMilestone.label}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoCoupleTextStrong,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.protoCoupleTextStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        upcomingMilestone.isReached
                            ? '달성 완료!'
                            : 'D-${upcomingMilestone.daysLeft}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (upcomingMilestone.checklist.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '준비물: ${upcomingMilestone.checklist.join(', ')}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.protoCoupleTextStrong.withValues(alpha: 0.8),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
