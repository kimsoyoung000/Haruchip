import 'package:flutter/material.dart';

import '../../categories/models/category.dart';

/// 테마별 컬러 팔레트 그룹 정의 (TimeTree 스타일 1:1 벤치마킹)
class ThemedColorGroup {
  const ThemedColorGroup({
    required this.label,
    required this.hexColors,
  });

  final String label;
  final List<String> hexColors;
}

/// 6대 테마 컬러 팔레트 (기본 / 단순 / 화려한 / 파스텔 / 시원한 / 세련된)
const List<ThemedColorGroup> kThemedColorPaletteGroups = [
  ThemedColorGroup(
    label: '기본',
    hexColors: [
      '#FF4B63',
      '#E83A78',
      '#F7931E',
      '#39B54A',
      '#29ABE2',
      '#9E7DDE',
    ],
  ),
  ThemedColorGroup(
    label: '단순',
    hexColors: [
      '#FF4D4F',
      '#FADB14',
      '#73D13D',
      '#5CDBD3',
      '#4096FF',
      '#B37FEB',
    ],
  ),
  ThemedColorGroup(
    label: '화려한',
    hexColors: [
      '#FF8585',
      '#FF85A2',
      '#FFB973',
      '#8EC5FC',
      '#6EE7B7',
      '#D4BBFC',
    ],
  ),
  ThemedColorGroup(
    label: '파스텔',
    hexColors: [
      '#FFD1D5',
      '#FAD4F0',
      '#FFE09E',
      '#BAFFC9',
      '#BAE1FF',
      '#E8D7FF',
    ],
  ),
  ThemedColorGroup(
    label: '시원한',
    hexColors: [
      '#2B6CB0',
      '#5A89A8',
      '#8FA8B8',
      '#6E85B7',
      '#94A3B8',
      '#B4B4C7',
    ],
  ),
  ThemedColorGroup(
    label: '세련된',
    hexColors: [
      '#8E3A4E',
      '#9C7A5B',
      '#7A688A',
      '#7D7D7D',
      '#4E6274',
      '#1F2429',
    ],
  ),
];

String _normalizeHex(String hex) {
  final cleaned = hex.trim().toUpperCase();
  if (cleaned.startsWith('#')) return cleaned;
  return '#$cleaned';
}

String _colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
}

bool _isLightColor(Color color) => color.computeLuminance() > 0.62;

/// 타임트리 스타일 테마별 컬러 팔레트 그리드 (새 카테고리 추가 다이얼로그 및 색상 변경 모달 공용)
class ThemedColorPaletteGrid extends StatelessWidget {
  const ThemedColorPaletteGrid({
    super.key,
    required this.selectedHex,
    required this.onColorSelected,
    this.compact = false,
  });

  final String selectedHex;
  final ValueChanged<String> onColorSelected;
  final bool compact;

  Future<void> _openCustomColorWheel(BuildContext context) async {
    final initial = colorFromHex(selectedHex);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => _CustomColorWheelDialog(initialColor: initial),
    );
    if (picked != null) {
      onColorSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = _normalizeHex(selectedHex);
    final double chipSize = compact ? 26 : 30;
    final double rowVerticalPadding = compact ? 8 : 11;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int gIdx = 0; gIdx < kThemedColorPaletteGroups.length; gIdx++) ...[
            if (gIdx > 0)
              const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F5F9)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: rowVerticalPadding,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: compact ? 48 : 58,
                    child: Text(
                      kThemedColorPaletteGroups[gIdx].label,
                      style: TextStyle(
                        fontSize: compact ? 12.5 : 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final hex in kThemedColorPaletteGroups[gIdx].hexColors)
                          _ColorCircleChip(
                            hex: hex,
                            size: chipSize,
                            isSelected: _normalizeHex(hex) == normalizedSelected,
                            onTap: () => onColorSelected(_normalizeHex(hex)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F5F9)),
          // 사용자 지정 (컬러 휠) 행
          InkWell(
            onTap: () => _openCustomColorWheel(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: rowVerticalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사용자 지정',
                    style: TextStyle(
                      fontSize: compact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!kThemedColorPaletteGroups.any(
                        (g) => g.hexColors.any((h) => _normalizeHex(h) == normalizedSelected),
                      )) ...[
                        Container(
                          width: chipSize - 6,
                          height: chipSize - 6,
                          decoration: BoxDecoration(
                            color: colorFromHex(normalizedSelected),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF374151), width: 1.5),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: _isLightColor(colorFromHex(normalizedSelected))
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // 커스텀 컬러 휠 아이콘
                      Container(
                        width: chipSize,
                        height: chipSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              Color(0xFFFF3B30),
                              Color(0xFFFF9500),
                              Color(0xFFFFCC00),
                              Color(0xFF34C759),
                              Color(0xFF00C7BE),
                              Color(0xFF007AFF),
                              Color(0xFFAF52DE),
                              Color(0xFFFF2D55),
                              Color(0xFFFF3B30),
                            ],
                          ),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorCircleChip extends StatelessWidget {
  const _ColorCircleChip({
    required this.hex,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hex);
    final checkColor =
        _isLightColor(color) ? const Color(0xFF1F2937) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size + 4,
        height: size + 4,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: _isLightColor(color)
                      ? const Color(0xFF475569)
                      : color,
                  width: 1.8,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isSelected
              ? Icon(Icons.check_rounded, size: size * 0.56, color: checkColor)
              : null,
        ),
      ),
    );
  }
}

/// 우측 컬러 도트 탭 시 호출되는 타임트리 스타일 팔레트 색상 변경 바텀시트
Future<String?> showThemedColorPickerSheet(
  BuildContext context, {
  required String title,
  required String currentHex,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ThemedColorPickerSheet(
      title: title,
      initialHex: currentHex,
    ),
  );
}

class _ThemedColorPickerSheet extends StatefulWidget {
  const _ThemedColorPickerSheet({
    required this.title,
    required this.initialHex,
  });

  final String title;
  final String initialHex;

  @override
  State<_ThemedColorPickerSheet> createState() =>
      _ThemedColorPickerSheetState();
}

class _ThemedColorPickerSheetState extends State<_ThemedColorPickerSheet> {
  late String _selectedHex;

  @override
  void initState() {
    super.initState();
    _selectedHex = _normalizeHex(widget.initialHex);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final previewColor = colorFromHex(_selectedHex);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 상단 네비게이션 바 (닫기 / 타이틀 / 완료)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 24, color: Color(0xFF476A92)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(_selectedHex),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF476A92),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '완료',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // 본문 스크롤 영역
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '라벨 색상',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: previewColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _selectedHex,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ThemedColorPaletteGrid(
                          selectedHex: _selectedHex,
                          onColorSelected: (hex) {
                            setState(() => _selectedHex = hex);
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '*변경한 색상은 칩 캘린더 전체의 해당 카테고리 일정에 즉시 반영됩니다.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
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
}

/// 사용자 지정 HSV 커스텀 컬러 피커 다이얼로그
class _CustomColorWheelDialog extends StatefulWidget {
  const _CustomColorWheelDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_CustomColorWheelDialog> createState() =>
      _CustomColorWheelDialogState();
}

class _CustomColorWheelDialogState extends State<_CustomColorWheelDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsv.toColor();
    final hex = _colorToHex(currentColor);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '사용자 지정 색상',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            alignment: Alignment.center,
            child: Text(
              hex,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _isLightColor(currentColor)
                    ? const Color(0xFF1F2937)
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('색상 (Hue)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Slider(
            value: _hsv.hue,
            min: 0,
            max: 360,
            activeColor: currentColor,
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('채도 (Saturation)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Slider(
            value: _hsv.saturation,
            min: 0.05,
            max: 1.0,
            activeColor: currentColor,
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('밝기 (Brightness)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Slider(
            value: _hsv.value,
            min: 0.2,
            max: 1.0,
            activeColor: currentColor,
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(hex),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF476A92),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('선택'),
        ),
      ],
    );
  }
}
