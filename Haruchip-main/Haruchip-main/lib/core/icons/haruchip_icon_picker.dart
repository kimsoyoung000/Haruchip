import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../utils/safe_image_widget.dart';
import 'haruchip_icon_registry.dart';
import 'haruchip_icon_viewer.dart';

/// 하루칩 통합 아이콘/사진 선택 바텀시트 호출 헬퍼
///
/// 반환값:
/// - [아이콘] 탭에서 선택 시: 안전 레지스트리 키 (예: `'simple_heart'`, `'line_cake'`)
/// - [사진] 탭에서 선택 시: 앱 샌드박스 격리 경로 키 (`'file:<sandbox_path>'`)
/// - 취소 시: `null`
Future<String?> showHaruChipIconPicker(
  BuildContext context, {
  String? initialIconKey,
  String title = '아이콘 선택',
  bool enablePhotoTab = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => HaruChipIconPicker(
      initialIconKey: initialIconKey,
      title: title,
      enablePhotoTab: enablePhotoTab,
    ),
  );
}

/// 레퍼런스 스타일 아이콘 선택 바텀시트
///
/// - [아이콘] 탭: '하트/기호', '기념일/음식', '동물/자연', '목표/시험' 4개 그룹 그리드
///   + 심플(파스텔) / 라인(2px) 스타일 전환 지원
/// - [사진] 탭: 기기 앨범 사진 선택 -> 앱 내부 저장소(Sandbox) 격리 복사 후 경로 반환
class HaruChipIconPicker extends StatefulWidget {
  const HaruChipIconPicker({
    super.key,
    this.initialIconKey,
    this.title = '아이콘 선택',
    this.enablePhotoTab = true,
  });

  final String? initialIconKey;
  final String title;
  final bool enablePhotoTab;

  @override
  State<HaruChipIconPicker> createState() => _HaruChipIconPickerState();
}

class _HaruChipIconPickerState extends State<HaruChipIconPicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late HaruChipIconStyle _style;
  late String _selectedKey;
  bool _isPickingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIconKey?.trim() ?? '';
    _selectedKey = initial;
    final normalized = HaruChipIconRegistry.normalizeKey(initial);
    _style = normalized.startsWith('line_')
        ? HaruChipIconStyle.line
        : HaruChipIconStyle.simple;

    final initialTabIndex = widget.enablePhotoTab &&
            (initial.startsWith(HaruChipIconRegistry.filePrefix) ||
                isDataImageUri(initial))
        ? 1
        : 0;
    _tabController = TabController(
      length: widget.enablePhotoTab ? 2 : 1,
      vsync: this,
      initialIndex: initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoFromAlbum() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) {
        if (mounted) setState(() => _isPickingPhoto = false);
        return;
      }

      if (kIsWeb) {
        final safeDataUri = await xFileToSafeImageSource(picked);
        if (!mounted) return;
        Navigator.of(context).pop(safeDataUri);
        return;
      }

      final sandboxKey = await HaruChipIconSandbox.savePhotoToSandbox(
        File(picked.path),
      );
      if (!mounted) return;
      if (sandboxKey == null) {
        setState(() => _isPickingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진을 안전 저장소에 보관하지 못했어요. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      Navigator.of(context).pop(sandboxKey);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPickingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('앨범 접근에 실패했어요. 사진 권한을 확인해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.protoCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 헤더 (타이틀 + 닫기 버튼)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 10, 6),
                child: Row(
                  children: [
                    if (_selectedKey.isNotEmpty) ...[
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.protoCardSelectedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.protoCardSelectedBorder,
                            width: 1.2,
                          ),
                        ),
                        child: HaruChipIconViewer(
                          iconKey: _selectedKey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTypography.heading2.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.protoSubtitle,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 상단 탭 바 ([아이콘] / [사진])
              if (widget.enablePhotoTab)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.protoCardBg,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.protoHeading,
                      unselectedLabelColor: AppColors.protoSubtitle,
                      labelStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: '아이콘'),
                        Tab(text: '사진'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.protoCardBorder),

              // 탭 본문
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIconsTab(),
                    if (widget.enablePhotoTab) _buildPhotoTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconsTab() {
    final catalog = HaruChipIconRegistry.groupedCatalog(style: _style);
    final normalizedSelected = HaruChipIconRegistry.normalizeKey(_selectedKey);

    return Column(
      children: [
        // 심플(파스텔) vs 라인(2px) 스타일 전환 필
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              _buildStylePill(
                label: '심플 파스텔',
                selected: _style == HaruChipIconStyle.simple,
                onTap: () => setState(() => _style = HaruChipIconStyle.simple),
              ),
              const SizedBox(width: 8),
              _buildStylePill(
                label: '미니멀 라인',
                selected: _style == HaruChipIconStyle.line,
                onTap: () => setState(() => _style = HaruChipIconStyle.line),
              ),
            ],
          ),
        ),

        // 4대 그룹별 아이콘 그리드
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: HaruChipIconRegistry.groups.length,
            itemBuilder: (context, groupIndex) {
              final groupName = HaruChipIconRegistry.groups[groupIndex];
              final items = catalog[groupName] ?? const <HaruChipIconItem>[];

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoCardText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, itemIndex) {
                        final item = items[itemIndex];
                        final isSelected = normalizedSelected == item.key;

                        return Tooltip(
                          message: item.labelKo,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(item.key),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.protoCardSelectedBg
                                    : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.protoCardSelectedBorder
                                      : Colors.transparent,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: HaruChipIconViewer(
                                iconKey: item.key,
                                size: 28,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStylePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.protoCardSelectedBg : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.protoCardSelectedBorder
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? AppColors.protoCardSelectedText
                : AppColors.protoCardText,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTab() {
    final hasCurrentPhoto =
        _selectedKey.startsWith(HaruChipIconRegistry.filePrefix);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(
                color: hasCurrentPhoto
                    ? AppColors.protoCardSelectedBorder
                    : AppColors.border,
                width: 2,
              ),
            ),
            child: hasCurrentPhoto
                ? HaruChipIconViewer(
                    iconKey: _selectedKey,
                    size: 92,
                    circular: true,
                  )
                : const Icon(
                    Icons.photo_library_outlined,
                    size: 38,
                    color: AppColors.protoSubtitle,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            '앨범에서 나만의 사진 선택',
            style: AppTypography.cardLabel.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.protoHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '선택한 사진은 앱 내부 안전 저장소(Sandbox)에\n격리 보관되어 안전하게 표시됩니다.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.protoSubtitle,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isPickingPhoto ? null : _pickPhotoFromAlbum,
              icon: _isPickingPhoto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.protoButtonText,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded, size: 20),
              label: Text(
                _isPickingPhoto ? '사진 저장 중...' : '앨범에서 사진 고르기',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.protoButtonBg,
                foregroundColor: AppColors.protoButtonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
