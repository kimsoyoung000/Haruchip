import 'package:flutter/material.dart';

import '../../../core/utils/safe_image_widget.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../controllers/baby_category_controller.dart';
import '../models/baby_profile.dart';

/// 아기 성장 메인 카드 위젯 (컴팩트 슬림화: 아바타 직경 약 15% 축소 및 카드 내부 여백 압축)
/// (원형 프로필 사진, 태어난 지 N일째, 상세 월령 N개월 N일차(N주 N일), 성별/혈액형/출생시간 뱃지)
class BabyGrowthCardWidget extends StatelessWidget {
  const BabyGrowthCardWidget({
    super.key,
    required this.profile,
    required this.onTapEdit,
    this.onTapManageSections,
  });

  final BabyProfile profile;
  final VoidCallback onTapEdit;
  final VoidCallback? onTapManageSections;

  static const _controller = BabyCategoryController();

  ImageProvider? _getAvatarImage(String? url) {
    return resolveSafeImageProvider(url);
  }

  @override
  Widget build(BuildContext context) {
    final daysCountText = _controller.formatBabyDaysCount(profile.birthDate);
    final detailedAgeText = _controller.formatBabyAgeDetailed(profile.birthDate);
    final avatarImage = _getAvatarImage(profile.photoUrl);

    final isBoy = profile.gender == BabyGender.boy;
    final isGirl = profile.gender == BabyGender.girl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. 원형 프로필 아바타 (약 15% 축소: 56x56)
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isBoy
                                  ? const Color(0xFF38BDF8)
                                  : (isGirl ? const Color(0xFFF472B6) : const Color(0xFFFB923C)),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isBoy
                                        ? const Color(0xFF38BDF8)
                                        : (isGirl ? const Color(0xFFF472B6) : const Color(0xFFFB923C)))
                                    .withValues(alpha: 0.22),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarImage != null
                                ? Image(
                                    image: avatarImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text('👶', style: TextStyle(fontSize: 26)),
                                    ),
                                  )
                                : const Center(
                                    child: Text('👶', style: TextStyle(fontSize: 26)),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // 2. 아기 이름 & 태어난 지 N일째
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.protoHeading,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBoy
                                      ? const Color(0xFFE0F2FE)
                                      : (isGirl ? const Color(0xFFFCE7F3) : const Color(0xFFFFEDD5)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isBoy ? '남아 👦' : (isGirl ? '여아 👧' : '성별 미정'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isBoy
                                        ? const Color(0xFF0369A1)
                                        : (isGirl ? const Color(0xFFBE185D) : const Color(0xFFC2410C)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            daysCountText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. 상세 월령 배지 (N개월 N일차 / N주 N일)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFEF08A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 14, color: Color(0xFFCA8A04)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          detailedAgeText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF713F12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // 4. 출생 정보 뱃지들 (생년월일, 혈액형, 출생 시간)
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _buildBabyInfoChip(
                      icon: Icons.calendar_month_outlined,
                      label: '${profile.birthDate.year}.${profile.birthDate.month.toString().padLeft(2, '0')}.${profile.birthDate.day.toString().padLeft(2, '0')} 생',
                    ),
                    if (profile.bloodType != null && profile.bloodType!.isNotEmpty)
                      _buildBabyInfoChip(
                        icon: Icons.bloodtype_outlined,
                        label: '${profile.bloodType}형',
                      ),
                    if (profile.birthTime != null && profile.birthTime!.isNotEmpty)
                      _buildBabyInfoChip(
                        icon: Icons.schedule_outlined,
                        label: '${profile.birthTime} 탄생',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBabyInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
