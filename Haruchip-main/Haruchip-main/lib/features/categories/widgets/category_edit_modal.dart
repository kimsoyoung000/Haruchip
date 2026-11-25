import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/icons/haruchip_icon_picker.dart';
import '../../../core/icons/haruchip_icon_registry.dart';
import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../core/utils/safe_image_widget.dart';
import '../../../design_system/colors.dart';
import '../../calendar/widgets/themed_color_palette_sheet.dart';
import '../models/category.dart';
import 'skin_theme_card_container.dart';

Future<CategoryModel?> showCategoryEditModal(
  BuildContext context, {
  required CategoryModel category,
}) {
  return showModalBottomSheet<CategoryModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryEditModal(category: category),
  );
}

/// 슬림화된 카테고리 꾸미기 바텀시트 — [기본 정보] | [스킨] 2탭 구조
///
/// - [기본 정보]: 카테고리 이름, 대표 아이콘/사진(HaruChipIconPicker), 캘린더 라벨 배경 채우기 토글
/// - [스킨]: 테마별 파스텔 팔레트 카드 배경색, 심플 배경 패턴 & 투명도(0~100%) 슬라이더, 갤러리 사진 배경
class CategoryEditModal extends StatefulWidget {
  const CategoryEditModal({super.key, required this.category});

  final CategoryModel category;

  @override
  State<CategoryEditModal> createState() => _CategoryEditModalState();
}

class _CategoryEditModalState extends State<CategoryEditModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late String _selectedIcon;

  // 스킨(카드 배경색 · 패턴 · 투명도 · 사진 배경) 상태
  late String _selectedBgHex;
  late SkinPatternType _patternType;
  late double _patternOpacity; // 0.0 ~ 1.0
  String? _photoBgPath;

  final ImagePicker _imagePicker = ImagePicker();

  static const List<({SkinPatternType type, String label, IconData icon})>
      _simplePatterns = [
    (type: SkinPatternType.none, label: '없음', icon: Icons.block_rounded),
    (type: SkinPatternType.dot, label: '도트', icon: Icons.blur_on_rounded),
    (type: SkinPatternType.grid, label: '미세 체크', icon: Icons.grid_4x4_rounded),
    (
      type: SkinPatternType.diagonalStripes,
      label: '스트라이프',
      icon: Icons.line_style_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.icon;

    final existingSkin = widget.category.skinTheme;
    _selectedBgHex = existingSkin?.backgroundColor ??
        (widget.category.background.colorValues.isNotEmpty
            ? widget.category.background.colorValues.first
            : '#FFF0F3');
    _patternType = existingSkin?.patternTypeEnum ?? SkinPatternType.none;
    if (_patternType == SkinPatternType.pixelHeart) {
      _patternType = SkinPatternType.dot;
    }
    _patternOpacity = (existingSkin?.patternOpacity ?? 0.25).clamp(0.0, 1.0);
    _photoBgPath = widget.category.background.type == BackgroundType.image
        ? widget.category.background.imageUrl
        : null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoBackground() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final safeImageSource = await xFileToSafeImageSource(picked);
        if (mounted) {
          setState(() {
            _photoBgPath = safeImageSource;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('앨범에서 사진을 불러오지 못했어요. 권한을 확인해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  CategorySkinTheme _buildCurrentSkinTheme() {
    final bgColor = colorFromHex(_selectedBgHex);
    final isDarkBg = bgColor.computeLuminance() < 0.45;
    final textHex = isDarkBg ? '#FFFFFF' : '#2C2C2E';
    final patternHex = isDarkBg ? '#FFFFFF' : '#1F2937';

    return CategorySkinTheme(
      id: widget.category.skinTheme?.id ?? 'custom_skin_${widget.category.id}',
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : widget.category.name,
      backgroundColor: _selectedBgHex,
      patternType: _patternType.name,
      patternColor: patternHex,
      patternOpacity: _patternOpacity,
      borderStyle: SkinBorderStyle.none.name,
      borderColor: _selectedBgHex,
      borderWidth: 0.0,
      borderRadius: 18.0,
      textColor: textHex,
      accentEmoji: _selectedIcon,
    );
  }

  void _saveAndClose() {
    final name = _nameController.text.trim();
    final hasPhoto = _photoBgPath != null && _photoBgPath!.isNotEmpty;
    final currentMeta = Map<String, dynamic>.from(
      widget.category.metadata ?? const <String, dynamic>{},
    );
    currentMeta['skinTheme'] = _buildCurrentSkinTheme().toJson();

    final updatedCategory = widget.category.copyWith(
      name: name.isEmpty ? widget.category.name : name,
      icon: _selectedIcon,
      metadata: currentMeta,
      background: BackgroundConfig(
        type: hasPhoto ? BackgroundType.image : BackgroundType.singleColor,
        colorValues: [_selectedBgHex],
        imageUrl: hasPhoto ? _photoBgPath : null,
        decorations: const <StickerConfig>[],
      ),
    );

    Navigator.of(context).pop(updatedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cleanCanvasBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 상단 네비게이션 바 (취소 / 카테고리 꾸미기 / 완료)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: AppColors.protoSubtitle,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  '카테고리 꾸미기',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.protoHeading,
                  ),
                ),
                TextButton(
                  onPressed: _saveAndClose,
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      color: AppColors.chipYellowText,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 실시간 프리뷰 카드 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: _buildLivePreviewCard(),
          ),

          // 2탭 선택 바: [기본 정보] | [스킨]
          Container(
            color: AppColors.cleanWhiteBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.chipYellowText,
              unselectedLabelColor: AppColors.protoSubtitle,
              indicatorColor: AppColors.chipGoldOutline,
              indicatorWeight: 2.8,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: '기본 정보'),
                Tab(text: '스킨'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // 탭 본문
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildUnifiedSkinTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 상단 실시간 무테두리 라운드 프리뷰 카드
  Widget _buildLivePreviewCard() {
    final skin = _buildCurrentSkinTheme();
    final bgColor = colorFromHex(_selectedBgHex);
    final hasPhoto = _photoBgPath != null && _photoBgPath!.isNotEmpty;
    final textColor =
        hasPhoto ? Colors.white : colorFromHex(skin.textColor);
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.category.name;

    return SkinThemeCardContainer(
      theme: skin,
      height: 124,
      width: double.infinity,
      borderless: true,
      backgroundImageUrl: hasPhoto ? _photoBgPath : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: hasPhoto ? 0.9 : 0.72),
                  shape: BoxShape.circle,
                ),
                child: HaruChipIconViewer(
                  iconKey: _selectedIcon,
                  size: 18,
                  circular: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    shadows: hasPhoto
                        ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textColor.withValues(alpha: 0.7),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '함께한 지 100일째',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: bgColor.computeLuminance() < 0.45
                        ? const Color(0xFF1F2937)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '다가오는 D-Day 일정',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Text(
                        'D-12',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.chipYellowText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// TAB 1: 기본 정보 (이름 · 대표 아이콘/사진)
  Widget _buildBasicInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('카테고리 이름'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: AppColors.protoHeading,
          ),
          decoration: InputDecoration(
            hintText: '카테고리 이름을 입력하세요 (예: 커플, 우리 여행)',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.chipGoldOutline,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        _buildSectionTitle('대표 아이콘 / 사진'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _openIconPicker,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.chipYellowBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: HaruChipIconViewer(
                        iconKey: _selectedIcon,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openIconPicker,
                      icon: const Icon(Icons.grid_view_rounded, size: 17),
                      label: const Text(
                        '전체 아이콘 · 사진에서 선택',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.chipYellowText,
                        backgroundColor: const Color(0xFFFFFBF0),
                        side: const BorderSide(
                          color: AppColors.chipGoldOutline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HaruChipIconRegistry.quickPresetKeys.map((iconKey) {
                  final isSelected = _selectedIcon == iconKey;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = iconKey),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.chipYellowBg
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.chipGoldOutline
                              : Colors.transparent,
                          width: 1.6,
                        ),
                      ),
                      child: HaruChipIconViewer(iconKey: iconKey, size: 24),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _openIconPicker() async {
    final picked = await showHaruChipIconPicker(
      context,
      initialIconKey: _selectedIcon,
      title: '카테고리 아이콘 선택',
    );
    if (picked != null && mounted) {
      setState(() => _selectedIcon = picked);
    }
  }

  /// TAB 2: 통합 스킨 탭 ([카드 배경색] · [배경 패턴 & 투명도] · [사진 배경])
  Widget _buildUnifiedSkinTab() {
    final hasPhoto = _photoBgPath != null && _photoBgPath!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. 카드 배경색 (캘린더 테마별 파스텔 팔레트 100% 동일)
        _buildSectionTitle('카드 배경색'),
        const SizedBox(height: 8),
        ThemedColorPaletteGrid(
          selectedHex: _selectedBgHex,
          onColorSelected: (hex) {
            setState(() {
              _selectedBgHex = hex;
              _photoBgPath = null;
            });
          },
        ),
        const SizedBox(height: 20),

        // 2. 배경 패턴 & 투명도(Opacity 0~100%)
        _buildSectionTitle('배경 패턴 & 투명도'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: _simplePatterns.map((p) {
                  final isSelected = _patternType == p.type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() {
                          _patternType = p.type;
                          _photoBgPath = null;
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.chipYellowBg
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.chipGoldOutline
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                p.icon,
                                size: 18,
                                color: isSelected
                                    ? AppColors.chipYellowText
                                    : AppColors.protoCardText,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.chipYellowText
                                      : AppColors.protoCardText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_patternType != SkinPatternType.none) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '패턴 투명도',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.protoCardText,
                      ),
                    ),
                    Text(
                      '${(_patternOpacity * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.chipYellowText,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.chipGoldOutline,
                    inactiveTrackColor: AppColors.surfaceMuted,
                    thumbColor: AppColors.chipYellowText,
                    overlayColor: AppColors.chipYellowBg.withValues(alpha: 0.4),
                  ),
                  child: Slider(
                    value: _patternOpacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) => setState(() => _patternOpacity = v),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. 사진 배경 (갤러리 업로드 & 카드 비율 자동 마스킹)
        _buildSectionTitle('사진 배경'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 2.6,
                    child: buildUserImage(
                      _photoBgPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickPhotoBackground,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        hasPhoto ? '다른 사진으로 변경' : '갤러리에서 사진 업로드',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => _photoBgPath = null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE11D48),
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '제거',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: AppColors.protoHeading,
      ),
    );
  }
}
