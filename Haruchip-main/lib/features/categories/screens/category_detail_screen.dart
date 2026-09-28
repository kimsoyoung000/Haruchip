import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/add_event_bottom_sheet.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/baby_profile_card_widget.dart';
import '../widgets/category_edit_modal.dart';
import '../widgets/category_onboarding_sheets.dart';
import '../widgets/pet_profile_card_widget.dart';

/// 전체 카테고리 범용 상세 화면 (듀얼 리스트 & 카테고리 온보딩 & 꾸미기 에디터 연동)
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  final CategoryModel category;

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late CategoryModel _category;

  // Edit / Reordering mode for 'N일째' items
  bool _isReorderingMode = false;
  List<PlanItem> _customCountUpOrder = [];

  @override
  void initState() {
    super.initState();
    _category = widget.category;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  void _checkOnboarding() {
    final meta = _category.metadata;
    final isInitialized = meta?['isInitialized'] == true;
    if (isInitialized) return;

    switch (_category.categoryKey) {
      case 'military':
        showMilitaryOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'baby':
        showBabyOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'solo':
        showSoloOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'fandom':
        showFandomOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'pet':
        showPetOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      default:
        // 생일, 시험/자격증, 계획/일정 등은 즉시 진입
        break;
    }
  }

  void _reloadCategory() {
    final categories = ref.read(categoryListProvider);
    final found = categories.where((c) => c.id == _category.id).toList();
    if (found.isNotEmpty && mounted) {
      setState(() {
        _category = found.first;
      });
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

  Future<void> _openCategorySpecificSettings() async {
    switch (_category.categoryKey) {
      case 'military':
        await showMilitaryOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'baby':
        await showBabyOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'solo':
        await showSoloOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'fandom':
        await showFandomOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'pet':
        await showPetOnboardingSheet(context, category: _category, ref: ref);
        break;
      default:
        break;
    }
    if (mounted) _reloadCategory();
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calculateDaysCount(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays + 1;
    return diff > 0 ? '$diff일째' : 'D-Day';
  }

  String _calculateDDayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  List<PlanItem> _sortCountDownItems(List<PlanItem> items) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    final futureItems = <PlanItem>[];
    final pastItems = <PlanItem>[];

    for (final item in items) {
      final targetOnly = DateTime(item.date.year, item.date.month, item.date.day);
      if (targetOnly.isBefore(todayOnly)) {
        pastItems.add(item);
      } else {
        futureItems.add(item);
      }
    }

    futureItems.sort((a, b) => a.date.compareTo(b.date));
    pastItems.sort((a, b) => b.date.compareTo(a.date));

    return [...futureItems, ...pastItems];
  }

  @override
  Widget build(BuildContext context) {
    final rawItems = ref.watch(planItemsByCategoryProvider(_category.categoryKey));

    final countUpItems = rawItems.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
    final countDownRaw = rawItems.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();
    final countDownItems = _sortCountDownItems(countDownRaw);

    // Sync count up order
    if (_customCountUpOrder.length != countUpItems.length) {
      _customCountUpOrder = List.from(countUpItems);
    }

    final bgConfig = _category.background;
    final typoConfig = _category.typography;

    Color? singleColor;
    List<Color>? gradientColors;

    if (bgConfig.type == BackgroundType.singleColor && bgConfig.colorValues.isNotEmpty) {
      singleColor = colorFromHex(bgConfig.colorValues.first);
    } else if (bgConfig.type == BackgroundType.gradient && bgConfig.colorValues.length >= 2) {
      gradientColors = bgConfig.colorValues.map((h) => colorFromHex(h)).toList();
    }

    final textColor = colorFromHex(typoConfig.textColor);
    final hasImage = bgConfig.type == BackgroundType.image && bgConfig.imageUrl != null;

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.protoBackground,
        elevation: 0,
        title: Text(
          '${_category.icon} ${_category.name}',
          style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openEditModal,
            icon: const Icon(Icons.palette_outlined, size: 17, color: AppColors.protoHeading),
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
            icon: const Icon(Icons.add, size: 17, color: Color(0xFF007AFF)),
            label: const Text(
              '항목 추가',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 카테고리 전용 헤더 카드 (꾸미기 커스텀 배경 + 스티커 실시간 반영)
                  GestureDetector(
                    onTap: _openCategorySpecificSettings,
                    child: Container(
                      width: double.infinity,
                      height: 190,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: singleColor ?? AppColors.protoCardBg,
                        gradient: gradientColors != null ? LinearGradient(colors: gradientColors) : null,
                        image: hasImage
                            ? DecorationImage(
                                image: bgConfig.imageUrl!.startsWith('http')
                                    ? NetworkImage(bgConfig.imageUrl!) as ImageProvider
                                    : AssetImage(bgConfig.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.15), BlendMode.darken),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.protoCardBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final cWidth = cardConstraints.maxWidth;
                          final cHeight = cardConstraints.maxHeight;

                          return Stack(
                            children: [
                              Align(
                                alignment: typoConfig.position.alignment,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Opacity(
                                    opacity: typoConfig.opacity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: switch (typoConfig.position) {
                                        TextPositionPreset.topLeft || TextPositionPreset.bottomLeft => CrossAxisAlignment.start,
                                        TextPositionPreset.topRight || TextPositionPreset.bottomRight => CrossAxisAlignment.end,
                                        _ => CrossAxisAlignment.center,
                                      },
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_category.icon, style: const TextStyle(fontSize: 28)),
                                            const SizedBox(width: 8),
                                            Text(
                                              _category.name,
                                              style: TextStyle(
                                                fontFamily: typoConfig.fontFamily,
                                                color: hasImage ? Colors.white : textColor,
                                                fontSize: typoConfig.fontSize + 4,
                                                fontWeight: FontWeight.bold,
                                                shadows: hasImage
                                                    ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '등록된 디데이: ${rawItems.length}개',
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.protoHeading,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (['military', 'baby', 'solo', 'fandom', 'pet'].contains(_category.categoryKey)) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.settings_rounded, size: 12, color: Color(0xFF007AFF)),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (bgConfig.decorations != null)
                                for (final sticker in bgConfig.decorations!)
                                  Positioned(
                                    left: sticker.x * cWidth,
                                    top: sticker.y * cHeight,
                                    child: Transform.rotate(
                                      angle: sticker.rotation,
                                      child: Transform.scale(
                                        scale: sticker.scale,
                                        child: sticker.isText
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  sticker.stickerType,
                                                  style: TextStyle(
                                                    fontSize: sticker.fontSize ?? 12,
                                                    color: sticker.textColor != null ? colorFromHex(sticker.textColor!) : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            : Text(sticker.stickerType, style: const TextStyle(fontSize: 28)),
                                      ),
                                    ),
                                  ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. 카테고리별 특화 상단 프로필 헤더 (Baby / Pet)
                  if (_category.categoryKey == 'baby') ...[
                    BabyProfileCardWidget(
                      babyName: _category.metadata?['babyName'] as String? ?? '우리 아기 👶',
                      birthDate: _category.metadata?['birthDate'] != null
                          ? DateTime.parse(_category.metadata!['birthDate'] as String)
                          : DateTime.now().subtract(const Duration(days: 100)),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_category.categoryKey == 'pet') ...[
                    PetProfileCardWidget(
                      petName: (_category.metadata?['pets'] as List<dynamic>?)?.isNotEmpty == true
                          ? (_category.metadata!['pets'][0]['name'] as String? ?? '댕댕이')
                          : '댕댕이 🐶',
                      birthOrAdoptionDate: (_category.metadata?['pets'] as List<dynamic>?)?.isNotEmpty == true &&
                              _category.metadata!['pets'][0]['adoptionDate'] != null
                          ? DateTime.parse(_category.metadata!['pets'][0]['adoptionDate'] as String)
                          : DateTime.now().subtract(const Duration(days: 200)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 구분선
                  const Divider(height: 1, color: AppColors.protoCardBorder),
                  const SizedBox(height: 24),

                  // 3. [영역 A] 'N일째 리스트' (Count-up List)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.protoHeading),
                          const SizedBox(width: 6),
                          Text(
                            'N일째 리스트',
                            style: AppTypography.cardLabel.copyWith(
                              color: AppColors.protoHeading,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (countUpItems.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _customCountUpOrder = List.from(countUpItems);
                              _isReorderingMode = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '편집',
                            style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (countUpItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: const Text('등록된 N일째 항목이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  else
                    for (final item in _customCountUpOrder)
                      _buildCountUpCard(
                        item: item,
                        onTap: () => showAddEventBottomSheet(
                          context,
                          categoryKey: _category.categoryKey,
                          existingItem: item,
                        ),
                      ),

                  const SizedBox(height: 28),

                  // 4. [영역 B] '세부 D-Day 리스트' (Countdown List)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, size: 18, color: AppColors.protoHeading),
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
                      Text(
                        '총 ${countDownItems.length}개',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (countDownItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 28, color: Colors.grey),
                          const SizedBox(height: 6),
                          const Text('예정된 D-Day 일정이 없어요', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    for (final item in countDownItems) ...[
                      _buildCountDownCard(
                        item: item,
                        onTap: () => showAddEventBottomSheet(
                          context,
                          categoryKey: _category.categoryKey,
                          existingItem: item,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ),

          // Reordering Modal Overlay for Zone A
          if (_isReorderingMode)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Notification
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'N일째 항목 순서 변경',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '💡 상단 2개 항목만 메인 화면에 우선 표시됩니다.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reorderable list
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: ReorderableListView(
                              // ignore: deprecated_member_use
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) newIndex -= 1;
                                  final item = _customCountUpOrder.removeAt(oldIndex);
                                  _customCountUpOrder.insert(newIndex, item);
                                });
                              },
                              children: [
                                for (int i = 0; i < _customCountUpOrder.length; i++)
                                  Container(
                                    key: ValueKey(_customCountUpOrder[i].id),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: i < 2
                                          ? Border.all(color: const Color(0xFF007AFF), width: 2)
                                          : Border.all(color: const Color(0xFFE5E5EA)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: i < 2 ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: i < 2 ? Colors.white : const Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _customCountUpOrder[i].title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.protoHeading,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.drag_handle_rounded, color: Color(0xFF8E8E93)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() {
                              _isReorderingMode = false;
                            });
                          },
                          child: const Text('수정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountUpCard({
    required PlanItem item,
    required VoidCallback onTap,
  }) {
    final dDayText = _calculateDaysCount(item.date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.protoHeading,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(item.date),
                    style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                dDayText,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountDownCard({
    required PlanItem item,
    required VoidCallback onTap,
  }) {
    final dDayLabel = _calculateDDayLabel(item.date);
    final isPast = dDayLabel.startsWith('D+');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.protoHeading,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(item.date),
                    style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPast ? const Color(0xFFFFEAEA) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                dDayLabel,
                style: TextStyle(
                  color: isPast ? const Color(0xFFEF4444) : const Color(0xFF007AFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
