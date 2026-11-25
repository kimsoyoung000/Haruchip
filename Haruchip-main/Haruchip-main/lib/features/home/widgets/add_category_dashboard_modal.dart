import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_picker.dart';
import '../../../core/icons/haruchip_icon_registry.dart';
import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../calendar/widgets/themed_color_palette_sheet.dart';
import '../../categories/data/category_types.dart';
import '../../categories/logic/category_content_flow.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/services/image_upload_service.dart';
import '../../onboarding/models/onboarding_category.dart';

/// "카테고리 추가하기" 순백 화이트 미니멀 바텀시트
///
/// - 타입 선택(STEP A) → 이름/아이콘/파스텔 테마 색상 커스텀(STEP B)
/// - 캘린더와 동일한 테마 파스텔 팔레트([ThemedColorPaletteGrid]) 및
///   통합 아이콘 피커([showHaruChipIconPicker]) 연동
Future<void> showAddCategoryDashboardModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddCategoryDashboardModal(),
  );
}

class _AddCategoryDashboardModal extends ConsumerStatefulWidget {
  const _AddCategoryDashboardModal();

  @override
  ConsumerState<_AddCategoryDashboardModal> createState() =>
      _AddCategoryDashboardModalState();
}

class _AddCategoryDashboardModalState
    extends ConsumerState<_AddCategoryDashboardModal> {
  OnboardingCategory? _selectedType;
  final _nameController = TextEditingController();
  String? _selectedIcon;
  String _selectedColorHex = kThemedColorPaletteGroups[3].hexColors.first; // 파스텔 기본값

  String? _backgroundImageUrl;
  bool _uploadingBackground = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectType(OnboardingCategory type) {
    setState(() {
      _selectedType = type;
      _nameController.clear();
      _selectedIcon = type.emoji;
      _selectedColorHex = getCategoryColorHex(type.key);
      _backgroundImageUrl = null;
    });
  }

  void _backToTypeSelection() {
    setState(() => _selectedType = null);
  }

  Future<void> _pickBackgroundImage() async {
    setState(() => _uploadingBackground = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await ref
          .read(imageUploadServiceProvider)
          .pickAndUpload(folder: 'category-background');
      if (!mounted) return;
      if (url == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('⚠️ 로그인 상태를 확인하거나 사진 선택을 다시 시도해주세요.')),
        );
      } else {
        setState(() => _backgroundImageUrl = url);
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('⚠️ 사진 업로드에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingBackground = false);
    }
  }

  Future<void> _handleAdd(BuildContext context) async {
    final type = _selectedType;
    if (type == null) return;
    final name = _nameController.text.trim().isEmpty
        ? type.labelKo
        : _nameController.text.trim();
    final icon = _selectedIcon ?? type.emoji;

    final draft = ref.read(categoryListProvider.notifier).newDraft(
          categoryKey: type.key,
          name: name,
          emoji: icon,
          colorHex: _selectedColorHex,
          backgroundImageUrl: _backgroundImageUrl,
        );
    final added = await collectContentAndAddCategory(context, ref, draft);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!added) {
      messenger.showSnackBar(
        const SnackBar(content: Text('내용을 입력하고 저장해야 카테고리가 추가돼요.')),
      );
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text("✨ '$name' 카테고리가 추가되었습니다!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _selectedType;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 10, 22, bottomInset + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (type != null)
                          GestureDetector(
                            onTap: _backToTypeSelection,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: AppColors.protoSubtitle,
                              ),
                            ),
                          ),
                        Text(
                          type == null ? '카테고리 추가하기' : '${type.labelKo} 커스텀',
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.protoHeading,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.protoSubtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (type == null) _buildStepA() else _buildStepB(type),
                const SizedBox(height: 18),
                if (type != null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _handleAdd(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        overlayColor: const Color(0xFFF7D779),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        categoryNeedsContent(type.key)
                            ? '다음: 내용 입력하기'
                            : '추가하기',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.protoSubtitle,
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어떤 카테고리를 추가할까요?',
          style: AppTypography.caption.copyWith(
            color: AppColors.protoSubtitle,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            for (final category in kCategoryTypes)
              InkWell(
                onTap: () => _selectType(category),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cleanCanvasBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HaruChipIconViewer(
                        iconKey: category.emoji,
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.labelKo,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.protoHeading,
                          fontWeight: FontWeight.w700,
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
  }

  Widget _buildStepB(OnboardingCategory type) {
    final currentIcon = _selectedIcon ?? type.emoji;
    final iconChoices = <String>{
      currentIcon,
      ...HaruChipIconRegistry.quickPresetKeys,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이름',
          style: AppTypography.caption.copyWith(
            color: AppColors.protoCardText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: AppTypography.body.copyWith(color: AppColors.protoHeading),
          decoration: InputDecoration(
            hintText: type.key == 'custom'
                ? '예: 우리 가족, 나만의 디데이, 버킷리스트'
                : type.labelKo,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13.5,
            ),
            filled: true,
            fillColor: AppColors.cleanCanvasBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
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
        const SizedBox(height: 16),

        // 상단 아이콘 셀렉터 (HaruChipIconViewer + 전체 아이콘 피커 연동)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '아이콘',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoCardText,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final picked = await showHaruChipIconPicker(
                  context,
                  initialIconKey: currentIcon,
                  title: '카테고리 아이콘 선택',
                );
                if (picked != null && mounted) {
                  setState(() => _selectedIcon = picked);
                }
              },
              icon: const Icon(Icons.grid_view_rounded, size: 15),
              label: const Text(
                '전체 아이콘',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.chipYellowText,
                backgroundColor: const Color(0xFFFFF8E1),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final iconKey in iconChoices)
              GestureDetector(
                onTap: () => setState(() => _selectedIcon = iconKey),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: currentIcon == iconKey
                        ? AppColors.chipYellowBg
                        : AppColors.cleanCanvasBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentIcon == iconKey
                          ? AppColors.chipGoldOutline
                          : Colors.transparent,
                      width: 1.6,
                    ),
                  ),
                  child: HaruChipIconViewer(iconKey: iconKey, size: 22),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),

        // 캘린더/꾸미기와 100% 동일한 테마 파스텔 팔레트
        Row(
          children: [
            Text(
              '테마 색상',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoCardText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colorFromHex(_selectedColorHex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ThemedColorPaletteGrid(
          selectedHex: _selectedColorHex,
          compact: true,
          onColorSelected: (hex) => setState(() => _selectedColorHex = hex),
        ),

        if (type.group == CategoryGroup.emotional) ...[
          const SizedBox(height: 16),
          Text(
            '배경 사진 (선택)',
            style: AppTypography.caption.copyWith(
              color: AppColors.protoCardText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_backgroundImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _backgroundImageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
          ],
          OutlinedButton.icon(
            onPressed: _uploadingBackground ? null : _pickBackgroundImage,
            icon: _uploadingBackground
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(
              _backgroundImageUrl == null ? '사진 추가하기' : '사진 변경하기',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.protoHeading,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
