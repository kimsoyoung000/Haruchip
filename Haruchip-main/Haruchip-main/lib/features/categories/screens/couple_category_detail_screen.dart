import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../core/utils/safe_image_widget.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../couple/models/couple_relationship.dart';
import '../../couple/providers/couple_provider.dart';
import '../../couple/widgets/couple_relationship_setup_sheet.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/add_event_bottom_sheet.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/category_edit_modal.dart';
import '../widgets/skin_theme_card_container.dart';

class CoupleCategoryDetailScreen extends ConsumerStatefulWidget {
  const CoupleCategoryDetailScreen({
    super.key,
    required this.category,
  });

  final CategoryModel category;

  @override
  ConsumerState<CoupleCategoryDetailScreen> createState() =>
      _CoupleCategoryDetailScreenState();
}

class _CoupleCategoryDetailScreenState
    extends ConsumerState<CoupleCategoryDetailScreen> {
  late CategoryModel _category;
  bool _isTitleEditing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _titleController = TextEditingController(text: _category.name);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _checkOnboarding() {
    final meta = _category.metadata;
    final isInitialized = meta?['isInitialized'] == true;
    if (isInitialized) return;

    final couple = ref.read(coupleProvider);
    if (!isInitialized ||
        (couple.startDate.year == 2024 &&
            couple.startDate.month == 5 &&
            couple.startDate.day == 14)) {
      _showRelationshipSetupModal();
    }
  }

  Future<void> _showRelationshipSetupModal() async {
    final isInitialized = _category.metadata?['isInitialized'] == true;
    final saved = await showCoupleRelationshipSetupSheet(
      context,
      ref,
      isInitialized: isInitialized,
    );
    if (saved && mounted) {
      final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
      currentMeta['isInitialized'] = true;
      final updatedCat = _category.copyWith(metadata: currentMeta);
      ref.read(categoryListProvider.notifier).updateCategory(updatedCat);
      setState(() => _category = updatedCat);
    }
  }

  Future<void> _openEditModal() async {
    final updated = await showCategoryEditModal(
      context,
      category: _category,
    );

    if (updated != null && mounted) {
      setState(() {
        _category = updated;
      });
      ref.read(categoryListProvider.notifier).updateCategory(updated);
    }
  }

  void _saveTitle() {
    setState(() => _isTitleEditing = false);
    final trimmed = _titleController.text.trim();
    if (trimmed.isEmpty) return;
    final updated = _category.copyWith(name: trimmed);
    setState(() => _category = updated);
    ref.read(categoryListProvider.notifier).updateCategory(updated);
  }

  Widget _buildCoupleHeroCard({
    required CoupleRelationship couple,
    required int totalDays,
    required bool hasImage,
    required String? imageUrl,
  }) {
    final startDateStr =
        '${couple.startDate.year}.${couple.startDate.month.toString().padLeft(2, '0')}.${couple.startDate.day.toString().padLeft(2, '0')} ~';
    final displayTitle =
        _category.name.isNotEmpty ? _category.name : '우리 사랑한 지';
    final iconKey =
        _category.icon.isNotEmpty ? _category.icon : 'simple_heart';
    final skinTheme = _category.skinTheme;

    final Color textColor = skinTheme != null
        ? colorFromHex(skinTheme.textColor)
        : const Color(0xFF4A2C35);
    final Color subtitleColor = textColor.withValues(alpha: 0.72);

    final avatarProvider = hasImage ? resolveSafeImageProvider(imageUrl) : null;

    final Widget heroBody = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 138),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌측 프로필 아바타 (펜슬 버튼 탭 시 꾸미기 모달 오픈)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: avatarProvider != null
                    ? CircleAvatar(
                        radius: 28,
                        backgroundImage: avatarProvider,
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: HaruChipIconViewer(
                          iconKey: iconKey,
                          size: 30,
                          circular: true,
                        ),
                      ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openEditModal,
                  child: Container(
                    padding: const EdgeInsets.all(4.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 11,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // 우측 정보 영역: 상단 닉네임 -> 중앙 대형 "866일" -> 하단 "2024.05.14 ~"
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardLabel.copyWith(
                          color: subtitleColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    HaruChipIconViewer(
                      iconKey: iconKey,
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(totalDays < 0 ? 0 : totalDays) + 1}일',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading1.copyWith(
                    color: textColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  startDateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // 카드 박스 전체 터치 -> 만난 날 및 재회 설정 모달 즉시 오픈
    if (skinTheme != null || hasImage) {
      final effectiveTheme = skinTheme ??
          const CategorySkinTheme(
            id: 'couple_default_hero',
            name: '커플 기본',
            backgroundColor: '#FFF5F7',
            patternType: 'none',
            patternColor: '#FFFFFF',
            patternOpacity: 0.0,
            borderStyle: 'none',
            borderColor: '#FFF5F7',
            borderWidth: 0.0,
            borderRadius: 20.0,
            textColor: '#4A2C35',
            accentEmoji: 'simple_heart',
          );

      return SkinThemeCardContainer(
        key: const Key('couple_hero_summary_card'),
        theme: effectiveTheme,
        width: double.infinity,
        borderless: true,
        backgroundImageUrl: hasImage ? imageUrl : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        onTap: _showRelationshipSetupModal,
        child: heroBody,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('couple_hero_summary_card'),
        onTap: _showRelationshipSetupModal,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF5F7),
                Color(0xFFFFFAF5),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD6336C).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: heroBody,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(coupleProvider);
    final totalDays = ref.watch(totalDaysTogetherProvider);
    final anniversaries = ref.watch(upcomingAnniversariesProvider);
    final customItems =
        ref.watch(planItemsByCategoryProvider(_category.categoryKey));

    final bgConfig = _category.background;
    final hasImage = bgConfig.type == BackgroundType.image &&
        bgConfig.imageUrl != null &&
        bgConfig.imageUrl!.isNotEmpty;

    // 세부 D-Day 리스트 항목 (직접 추가한 카운트다운 + 자동 계산 기념일)
    final countDownItems = customItems
        .where((item) => item.displayMode != DdayDisplayMode.daysCount)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cleanCanvasBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: AppColors.protoHeading),
        title: Row(
          children: [
            HaruChipIconViewer(
              iconKey: _category.icon,
              size: 26,
              circular: true,
            ),
            const SizedBox(width: 8),
            if (_isTitleEditing)
              Expanded(
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: AppTypography.heading2
                      .copyWith(color: AppColors.protoHeading),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _saveTitle(),
                ),
              )
            else
              Flexible(
                child: GestureDetector(
                  onTap: () => setState(() => _isTitleEditing = true),
                  child: Text(
                    _category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2
                        .copyWith(color: AppColors.protoHeading),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_isTitleEditing)
            IconButton(
              icon: const Icon(Icons.check_rounded,
                  color: AppColors.chipYellowText),
              onPressed: _saveTitle,
            )
          else ...[
            TextButton.icon(
              key: const Key('category_decorate_button'),
              onPressed: _openEditModal,
              icon: const Icon(
                Icons.palette_outlined,
                size: 18,
                color: AppColors.protoHeading,
              ),
              label: Text(
                '꾸미기',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoHeading,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => showAddEventBottomSheet(
                context,
                categoryKey: _category.categoryKey,
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.chipYellowText,
              ),
              label: const Text(
                '항목 추가',
                style: TextStyle(
                  color: AppColors.chipYellowText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 대표 요약 카드 (카드 전체 탭 -> 만난 날 및 재회 설정 모달 오픈)
              _buildCoupleHeroCard(
                couple: couple,
                totalDays: totalDays,
                hasImage: hasImage,
                imageUrl: bgConfig.imageUrl,
              ),

              const SizedBox(height: 24),

              // 2. 하단 단일 리스트: '세부 D-Day 리스트' (중복 'N일째 리스트' 완전 제거)
              Row(
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 18,
                    color: AppColors.protoHeading,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '세부 D-Day 리스트',
                    style: AppTypography.cardLabel.copyWith(
                      color: AppColors.protoHeading,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._buildCountDownItems(countDownItems, anniversaries),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCountDownItems(
    List<PlanItem> customItems,
    List<AnniversaryMilestone> autoAnniv,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_CountDownListItem> merged = [];

    for (final item in customItems) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      final isPast = itemDate.isBefore(today);
      final diff = itemDate.difference(today).inDays;
      merged.add(_CountDownListItem(
        title: item.title,
        subtext:
            '${item.date.year}.${item.date.month.toString().padLeft(2, '0')}.${item.date.day.toString().padLeft(2, '0')}',
        date: item.date,
        isPast: isPast,
        dDayLabel: diff == 0 ? 'D-Day' : (diff > 0 ? 'D-$diff' : 'D+${-diff}'),
        isCoupleSpecial: false,
        rawItem: item,
      ));
    }

    for (final anniv in autoAnniv.take(15)) {
      final diff = anniv.date.difference(today).inDays;
      merged.add(_CountDownListItem(
        title: anniv.label,
        subtext:
            '${anniv.date.year}.${anniv.date.month.toString().padLeft(2, '0')}.${anniv.date.day.toString().padLeft(2, '0')}',
        date: anniv.date,
        isPast: false,
        dDayLabel: diff == 0 ? 'D-Day' : 'D-$diff',
        isCoupleSpecial: true,
      ));
    }

    merged.sort((a, b) {
      if (!a.isPast && !b.isPast) return a.date.compareTo(b.date);
      if (a.isPast && b.isPast) return b.date.compareTo(a.date);
      return a.isPast ? 1 : -1;
    });

    return merged.map((m) {
      final isPastBadge = m.dDayLabel.startsWith('D+');
      return GestureDetector(
        onTap: () {
          if (m.rawItem != null) {
            showAddEventBottomSheet(
              context,
              categoryKey: _category.categoryKey,
              existingItem: m.rawItem,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              color: AppColors.protoHeading,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (m.isCoupleSpecial) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: Color(0xFFFF7F50),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.subtext,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPastBadge
                      ? const Color(0xFFFFEAEA)
                      : AppColors.chipYellowBg.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  m.dDayLabel,
                  style: TextStyle(
                    color: isPastBadge
                        ? const Color(0xFFEF4444)
                        : AppColors.chipYellowText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _CountDownListItem {
  _CountDownListItem({
    required this.title,
    required this.subtext,
    required this.date,
    required this.isPast,
    required this.dDayLabel,
    required this.isCoupleSpecial,
    this.rawItem,
  });

  final String title;
  final String subtext;
  final DateTime date;
  final bool isPast;
  final String dDayLabel;
  final bool isCoupleSpecial;
  final PlanItem? rawItem;
}
