import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/birthday_profile.dart';
import 'custom_avatar_builder_widget.dart';

/// 생일 카테고리 2열 프로필 네모 카드 위젯
class BirthdayGridCardWidget extends StatelessWidget {
  const BirthdayGridCardWidget({
    super.key,
    required this.friend,
    this.onTap,
  });

  final BirthdayProfile friend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dDay = friend.dDay();
    final dDayLabel = friend.dDayLabel();
    final isToday = dDay == 0;
    final isSoon = dDay > 0 && dDay <= 30;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday
                ? const Color(0xFFF472B6)
                : const Color(0xFFF1F5F9),
            width: isToday ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isToday
                  ? const Color(0xFFDB2777).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 프로필 영역 (사진 / 이모지 / 2D 커스텀 아바타)
            _buildAvatar(context),
            const SizedBox(height: 10),

            // 2. 별명 (이름)
            Text(
              friend.name,
              style: AppTypography.heading2.copyWith(
                color: AppColors.protoHeading,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),

            // 3. 생년월일
            Text(
              friend.formattedBirthDate(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // 4. [ D-Day ] 뱃지 (당일 지나면 D-365 자동 롤링)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFDB2777)
                    : isSoon
                        ? const Color(0xFFFDF2F8)
                        : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFFDB2777)
                      : isSoon
                          ? const Color(0xFFFCE7F3)
                          : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                isToday ? '🎂 오늘 D-Day!' : dDayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isToday
                      ? Colors.white
                      : isSoon
                          ? const Color(0xFFDB2777)
                          : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (friend.avatarType == BirthdayAvatarType.photo &&
        friend.photoUrl != null &&
        friend.photoUrl!.isNotEmpty) {
      ImageProvider? imageProvider;
      if (friend.photoUrl!.startsWith('data:image')) {
        try {
          final base64Content = friend.photoUrl!.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64Content));
        } catch (_) {}
      } else {
        imageProvider = NetworkImage(friend.photoUrl!);
      }

      return Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F8),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFCE7F3), width: 2),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: imageProvider == null
            ? const Icon(Icons.person, size: 36, color: Color(0xFFDB2777))
            : null,
      );
    }

    if (friend.avatarType == BirthdayAvatarType.customAvatar &&
        friend.avatarConfig != null) {
      return CustomAvatarRendererWidget(
        config: friend.avatarConfig!,
        size: 68,
        showBorder: true,
      );
    }

    // Default: Emoji
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF2F8),
        shape: BoxShape.circle,
      ),
      child: Text(
        friend.emoji ?? '🎂',
        style: const TextStyle(fontSize: 34),
      ),
    );
  }
}
