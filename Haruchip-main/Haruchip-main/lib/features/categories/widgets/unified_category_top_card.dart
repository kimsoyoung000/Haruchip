import 'package:flutter/material.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/category_skin_theme.dart';
import 'skin_theme_card_container.dart';

/// 2D 플랫 라인 및 레트로 픽셀/미니멀 심볼 프리셋
const List<String> kMinimalEmoticonPresets = [
  '❤️', // 하트
  '💍', // 반지
  '💌', // 편지
  '📔', // 다이어리
  '🎨', // 팔레트 (취미)
  '🎸', // 기타 (취미)
  '🎮', // 게임기 (취미)
  '✈️', // 비행기 (여행)
  '🧳', // 캐리어 (여행)
  '🌴', // 야자수 (여행)
  '🗺️', // 지도 (여행)
  '📅', // 달력
  '🌱', // 새싹
  '⭐', // 별
  '🎀', // 리본
  '☕', // 커피
  '🎯', // 타겟
  '🐾', // 발자국
  '🧸', // 곰인형
];

/// 아기 카테고리 카드 폼 팩터와 1:1 일치하는 커플 & 나만의 카테고리 상단 통일 카드 (컴팩트 슬림화 핏)
///
/// 레이아웃 구성:
/// - 좌측: 원형 프로필 아바타 (약 15% 축소: radius 25 / 직경 50, 펜슬 수정 버튼)
/// - 우측 상단: 카테고리명/닉네임 + 대표 심볼 (깔끔한 2D 플랫 라인 / 픽셀 이모티콘)
/// - 우측 중앙: 핵심 D-Day 일수 (ex. "사랑한 지 520일째", "목표 D-45")
/// - 하단: 라운드 서브 배지(재회 기간 제외 정보, 시작일) + [섹션 관리] 버튼
class UnifiedCategoryTopCard extends StatelessWidget {
  const UnifiedCategoryTopCard({
    super.key,
    required this.categoryKey,
    required this.title,
    required this.symbol,
    required this.coreDDayText,
    this.startDateText,
    this.reunionOrExtraBadge,
    this.photoUrl,
    this.fallbackEmoji,
    this.onEditAvatar,
    this.onManageSection,
    this.onHideCard,
    this.manageSectionText = '섹션 관리',
    this.onTapCard,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.skinTheme,
    this.backgroundImageUrl,
  });

  final String categoryKey;
  final String title;
  final String symbol;
  final String coreDDayText;
  final String? startDateText;
  final String? reunionOrExtraBadge;
  final String? photoUrl;
  final String? fallbackEmoji;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onManageSection;
  final VoidCallback? onHideCard;
  final String manageSectionText;
  final VoidCallback? onTapCard;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final CategorySkinTheme? skinTheme;
  final String? backgroundImageUrl;

  bool get _isCouple => categoryKey == 'couple';

  Color get _resolvedBg {
    if (backgroundColor != null) return backgroundColor!;
    if (categoryKey == 'couple') return AppColors.coupleBg;
    if (categoryKey == 'hobby') return AppColors.hobbyBg;
    if (categoryKey == 'travel') return AppColors.travelBg;
    if (categoryKey == 'wedding') return AppColors.weddingBg;
    return AppColors.myCategoryBg;
  }

  Color get _resolvedBorder {
    if (borderColor != null) return borderColor!;
    if (categoryKey == 'couple') return AppColors.coupleBorder;
    if (categoryKey == 'hobby') return AppColors.hobbyBorder;
    if (categoryKey == 'travel') return AppColors.travelBorder;
    if (categoryKey == 'wedding') return AppColors.weddingBorder;
    return AppColors.myCategoryBorder;
  }

  Color get _resolvedText {
    if (textColor != null) return textColor!;
    if (categoryKey == 'couple') return AppColors.coupleText;
    if (categoryKey == 'hobby') return AppColors.hobbyText;
    if (categoryKey == 'travel') return AppColors.travelText;
    if (categoryKey == 'wedding') return AppColors.weddingText;
    return AppColors.myCategoryText;
  }

  String get _resolvedFallbackEmoji {
    if (fallbackEmoji != null) return fallbackEmoji!;
    if (categoryKey == 'couple') return '❤️';
    if (categoryKey == 'hobby') return '🎨';
    if (categoryKey == 'travel') return '✈️';
    if (categoryKey == 'wedding') return '💍';
    return '📔';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _resolvedBg;
    final bColor = _resolvedBorder;
    final tColor = _resolvedText;

    final innerContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 좌측: 원형 프로필 아바타 (약 15% 축소: radius 21 / 직경 42, 펜슬 수정 버튼 포함)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: bColor, width: 1.3),
                      color: Colors.white,
                    ),
                    child: photoUrl != null && photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 21,
                            backgroundImage: NetworkImage(photoUrl!),
                          )
                        : CircleAvatar(
                            radius: 21,
                            backgroundColor: Colors.white,
                            child: HaruChipIconViewer(
                              iconKey: _resolvedFallbackEmoji,
                              size: 24,
                              circular: true,
                            ),
                          ),
                  ),
                  if (onEditAvatar != null)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: InkWell(
                        onTap: onEditAvatar,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: bColor, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 9.5,
                            color: tColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // 2. 우측 정보 영역 (상단 타이틀/심볼 + 중앙 핵심 D-Day)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 우측 상단: 카테고리명/닉네임 + 대표 심볼
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.cardLabel.copyWith(
                              color: tColor.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        HaruChipIconViewer(
                          iconKey: symbol,
                          size: 16,
                        ),
                        if (onHideCard != null) ...[
                          const Spacer(),
                          InkWell(
                            onTap: onHideCard,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 11, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 2),
                                  Text(
                                    '카드 숨기기',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),

                    // 우측 중앙: 핵심 D-Day 텍스트 (ex. "사랑한 지 520일째")
                    InkWell(
                      onTap: onTapCard,
                      borderRadius: BorderRadius.circular(8),
                      child: Text(
                        coreDDayText,
                        style: AppTypography.heading1.copyWith(
                          color: tColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // 3. 하단 라운드 칩 & 액션 버튼
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            runSpacing: 4,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // 시작일 라벨 배지
                  if (startDateText != null && startDateText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: bColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 10, color: tColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 3),
                          Text(
                            startDateText!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: tColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 커플 재회 기간 제외 정보 또는 추가 배지
                  if (reunionOrExtraBadge != null && reunionOrExtraBadge!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: _isCouple ? const Color(0xFFFFD1DC) : bColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: _isCouple ? const Color(0xFFFF9EAA) : bColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        reunionOrExtraBadge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              // [섹션 관리] 버튼
              if (onManageSection != null)
                InkWell(
                  onTap: onManageSection,
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: bColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 11, color: tColor),
                        const SizedBox(width: 3),
                        Text(
                          manageSectionText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: tColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );

    if (skinTheme != null) {
      return SkinThemeCardContainer(
        theme: skinTheme!,
        width: double.infinity,
        borderless: true,
        backgroundImageUrl: backgroundImageUrl,
        padding: const EdgeInsets.all(12),
        child: innerContent,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: innerContent,
    );
  }
}
