import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/pet_profile.dart';

/// 반려동물 패밀리 카드 (명함 / 프로필형) 가로 스와이프 캐러셀 위젯
class PetFamilyCardCarouselWidget extends StatefulWidget {
  const PetFamilyCardCarouselWidget({
    super.key,
    required this.pets,
    this.onEditPet,
    this.onAddNewPet,
  });

  final List<PetProfile> pets;
  final ValueChanged<PetProfile>? onEditPet;
  final VoidCallback? onAddNewPet;

  @override
  State<PetFamilyCardCarouselWidget> createState() => _PetFamilyCardCarouselWidgetState();
}

class _PetFamilyCardCarouselWidgetState extends State<PetFamilyCardCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pets.isEmpty) {
      return _buildEmptyCard();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pets.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final pet = widget.pets[index];
              return _buildFamilyCard(pet, index);
            },
          ),
        ),
        if (widget.pets.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pets.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD97706) : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            '등록된 반려동물 프로필이 없습니다',
            style: AppTypography.heading2.copyWith(fontSize: 16, color: AppColors.protoHeading),
          ),
          const SizedBox(height: 4),
          Text(
            '우리 아이의 프로필을 등록하고 기념일과 케어 일정을 관리해보세요.',
            style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onAddNewPet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('반려동물 프로필 등록하기', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(PetProfile pet, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF9),
            Color(0xFFFFF7ED),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Row: Avatar + Name / Species / Days Together + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Profile Avatar
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                      ? Image(
                          image: getPetAvatarImageProvider(pet.photoUrl)!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(pet.icon, style: const TextStyle(fontSize: 30)),
                          ),
                        )
                      : Center(
                          child: Text(pet.icon, style: const TextStyle(fontSize: 32)),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Pet Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pet.name,
                            style: AppTypography.heading2.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.protoHeading,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            pet.species.isNotEmpty ? pet.species : '반려동물',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // 함께한 지 N일째 배지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            '함께한 지 D+${pet.daysTogether}일째',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons (Edit / Add)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => widget.onEditPet?.call(pet),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: widget.onAddNewPet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3E8D8)),
          const SizedBox(height: 10),

          // Lower Section: Personality note & Birthday summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pet.personality.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.format_quote_rounded, size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pet.personality,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.cake_outlined, size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          '나이: ${pet.formattedAge}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (pet.nextBirthdayDDayLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '생일 ${pet.nextBirthdayDDayLabel}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
