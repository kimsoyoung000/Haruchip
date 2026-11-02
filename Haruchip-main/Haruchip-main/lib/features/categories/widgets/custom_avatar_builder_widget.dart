import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/birthday_profile.dart';

/// 2D 귀여운 커스텀 아바타 실시간 렌더러 위젯
class CustomAvatarRendererWidget extends StatelessWidget {
  const CustomAvatarRendererWidget({
    super.key,
    required this.config,
    this.size = 80,
    this.showBorder = true,
  });

  final CustomAvatarConfig config;
  final double size;
  final bool showBorder;

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(config.bgColor, const Color(0xFFFFE4E6));
    final skinColor = _parseColor(config.skinColor, const Color(0xFFFFE0BD));
    final hairColor = _parseColor(config.hairColor, const Color(0xFF2C1D11));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: size > 70 ? 3 : 2)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 헤어 뒷부분 (긴머리 / 포니테일 / 똥머리)
            if (config.hairStyle == 'long' || config.hairStyle == 'wave')
              Positioned(
                top: size * 0.22,
                child: Container(
                  width: size * 0.76,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    color: hairColor,
                    borderRadius: BorderRadius.circular(size * 0.35),
                  ),
                ),
              ),
            if (config.hairStyle == 'ponytail')
              Positioned(
                top: size * 0.08,
                right: size * 0.12,
                child: Container(
                  width: size * 0.38,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    color: hairColor,
                    borderRadius: BorderRadius.circular(size * 0.2),
                  ),
                ),
              ),
            if (config.hairStyle == 'bun')
              Positioned(
                top: size * 0.04,
                child: Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: BoxDecoration(
                    color: hairColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // 2. 얼굴 베이스
            Positioned(
              top: size * 0.25,
              child: Container(
                width: size * 0.54,
                height: size * 0.52,
                decoration: BoxDecoration(
                  color: skinColor,
                  borderRadius: switch (config.faceShape) {
                    'egg' => BorderRadius.vertical(
                        top: Radius.circular(size * 0.28),
                        bottom: Radius.circular(size * 0.22),
                      ),
                    'square' => BorderRadius.circular(size * 0.16),
                    _ => BorderRadius.circular(size * 0.26), // round
                  },
                ),
              ),
            ),

            // 3. 볼터치 (기본 또는 표정에 따라)
            Positioned(
              top: size * 0.48,
              left: size * 0.24,
              child: Container(
                width: size * 0.12,
                height: size * 0.06,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF85A1).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(size * 0.04),
                ),
              ),
            ),
            Positioned(
              top: size * 0.48,
              right: size * 0.24,
              child: Container(
                width: size * 0.12,
                height: size * 0.06,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF85A1).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(size * 0.04),
                ),
              ),
            ),

            // 4. 눈 & 입 & 표정
            Positioned(
              top: size * 0.40,
              child: _buildFaceExpression(config.expression, size),
            ),

            // 5. 헤어 앞부분 (앞머리 및 전체 헤어 프레임)
            Positioned(
              top: size * 0.15,
              child: _buildHairFront(config.hairStyle, hairColor, size),
            ),

            // 6. 악세사리
            if (config.accessory != 'none')
              Positioned(
                top: _getAccessoryTop(config.accessory, size),
                child: _buildAccessory(config.accessory, size),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceExpression(String expression, double size) {
    switch (expression) {
      case 'wink':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 왼쪽 윙크 ^
            Text('^', style: TextStyle(fontSize: size * 0.16, fontWeight: FontWeight.w900, color: const Color(0xFF2C1D11), height: 1.0)),
            SizedBox(width: size * 0.14),
            // 오른쪽 똥그란 눈 •
            Container(width: size * 0.07, height: size * 0.07, decoration: const BoxDecoration(color: Color(0xFF2C1D11), shape: BoxShape.circle)),
          ],
        );
      case 'sparkle':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('★', style: TextStyle(fontSize: size * 0.14, color: const Color(0xFFEAB308), height: 1.0)),
            SizedBox(width: size * 0.12),
            Text('★', style: TextStyle(fontSize: size * 0.14, color: const Color(0xFFEAB308), height: 1.0)),
          ],
        );
      case 'cool':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: size * 0.08, height: size * 0.04, decoration: BoxDecoration(color: const Color(0xFF2C1D11), borderRadius: BorderRadius.circular(2))),
            SizedBox(width: size * 0.14),
            Container(width: size * 0.08, height: size * 0.04, decoration: BoxDecoration(color: const Color(0xFF2C1D11), borderRadius: BorderRadius.circular(2))),
          ],
        );
      case 'peace':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('u', style: TextStyle(fontSize: size * 0.13, fontWeight: FontWeight.bold, color: const Color(0xFF2C1D11), height: 1.0)),
            SizedBox(width: size * 0.15),
            Text('u', style: TextStyle(fontSize: size * 0.13, fontWeight: FontWeight.bold, color: const Color(0xFF2C1D11), height: 1.0)),
          ],
        );
      case 'blush':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('•', style: TextStyle(fontSize: size * 0.18, fontWeight: FontWeight.bold, color: const Color(0xFF2C1D11), height: 0.9)),
            SizedBox(width: size * 0.15),
            Text('•', style: TextStyle(fontSize: size * 0.18, fontWeight: FontWeight.bold, color: const Color(0xFF2C1D11), height: 0.9)),
          ],
        );
      case 'smile':
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: size * 0.065, height: size * 0.065, decoration: const BoxDecoration(color: Color(0xFF2C1D11), shape: BoxShape.circle)),
                SizedBox(width: size * 0.16),
                Container(width: size * 0.065, height: size * 0.065, decoration: const BoxDecoration(color: Color(0xFF2C1D11), shape: BoxShape.circle)),
              ],
            ),
            SizedBox(height: size * 0.04),
            Container(
              width: size * 0.09,
              height: size * 0.045,
              decoration: BoxDecoration(
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF2C1D11), width: 1.8),
                ),
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildHairFront(String style, Color color, double size) {
    switch (style) {
      case 'long':
      case 'wave':
        return Container(
          width: size * 0.60,
          height: size * 0.32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(size * 0.3),
              bottom: Radius.circular(size * 0.08),
            ),
          ),
        );
      case 'bun':
      case 'ponytail':
        return Container(
          width: size * 0.58,
          height: size * 0.28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(size * 0.28),
              bottom: Radius.circular(size * 0.08),
            ),
          ),
        );
      case 'bangs':
        return Container(
          width: size * 0.56,
          height: size * 0.26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(size * 0.28),
              bottom: Radius.circular(size * 0.04),
            ),
          ),
        );
      case 'curly':
        return Container(
          width: size * 0.62,
          height: size * 0.32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
        );
      case 'dandy':
        return Container(
          width: size * 0.56,
          height: size * 0.25,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.28),
              topRight: Radius.circular(size * 0.28),
              bottomRight: Radius.circular(size * 0.16),
            ),
          ),
        );
      case 'short':
      default:
        return Container(
          width: size * 0.56,
          height: size * 0.28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(size * 0.28),
              bottom: Radius.circular(size * 0.1),
            ),
          ),
        );
    }
  }

  double _getAccessoryTop(String accessory, double size) {
    return switch (accessory) {
      'glasses_round' || 'glasses_square' => size * 0.36,
      'ribbon' => size * 0.10,
      'beret' => size * 0.06,
      'party_hat' => size * 0.02,
      'star' || 'heart' => size * 0.12,
      _ => size * 0.2,
    };
  }

  Widget _buildAccessory(String accessory, double size) {
    switch (accessory) {
      case 'glasses_round':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size * 0.17,
              height: size * 0.17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1F2937), width: 1.6),
              ),
            ),
            Container(width: size * 0.06, height: 1.5, color: const Color(0xFF1F2937)),
            Container(
              width: size * 0.17,
              height: size * 0.17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1F2937), width: 1.6),
              ),
            ),
          ],
        );
      case 'glasses_square':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size * 0.17,
              height: size * 0.13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF111827), width: 1.8),
              ),
            ),
            Container(width: size * 0.06, height: 1.5, color: const Color(0xFF111827)),
            Container(
              width: size * 0.17,
              height: size * 0.13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF111827), width: 1.8),
              ),
            ),
          ],
        );
      case 'ribbon':
        return Text('🎀', style: TextStyle(fontSize: size * 0.22));
      case 'beret':
        return Text('👒', style: TextStyle(fontSize: size * 0.26));
      case 'party_hat':
        return Text('🥳', style: TextStyle(fontSize: size * 0.26));
      case 'star':
        return Text('⭐', style: TextStyle(fontSize: size * 0.20));
      case 'heart':
        return Text('💖', style: TextStyle(fontSize: size * 0.20));
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 아바타 인터랙티브 커스터마이저 위젯 (피커 툴바)
class CustomAvatarBuilderWidget extends StatefulWidget {
  const CustomAvatarBuilderWidget({
    super.key,
    required this.initialConfig,
    required this.onChanged,
  });

  final CustomAvatarConfig initialConfig;
  final ValueChanged<CustomAvatarConfig> onChanged;

  @override
  State<CustomAvatarBuilderWidget> createState() => _CustomAvatarBuilderWidgetState();
}

class _CustomAvatarBuilderWidgetState extends State<CustomAvatarBuilderWidget>
    with SingleTickerProviderStateMixin {
  late CustomAvatarConfig _config;
  late TabController _tabController;

  final List<({String key, String label})> _tabs = const [
    (key: 'hair', label: '헤어스타일'),
    (key: 'hairColor', label: '머리색'),
    (key: 'expression', label: '표정/눈'),
    (key: 'accessory', label: '악세사리'),
    (key: 'skin', label: '피부/얼굴'),
    (key: 'bg', label: '배경색'),
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _update(CustomAvatarConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 실시간 아바타 프리뷰
        Center(
          child: Column(
            children: [
              CustomAvatarRendererWidget(
                config: _config,
                size: 96,
                showBorder: true,
              ),
              const SizedBox(height: 6),
              Text(
                '✨ 나만의 커스텀 아바타',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 커스텀 탭 바
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                ),
              ],
            ),
            labelColor: AppColors.protoHeading,
            unselectedLabelColor: AppColors.protoSubtitle,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // 탭 컨텐츠 영역
        SizedBox(
          height: 100,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHairStyleTab(),
              _buildHairColorTab(),
              _buildExpressionTab(),
              _buildAccessoryTab(),
              _buildSkinAndFaceTab(),
              _buildBgColorTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHairStyleTab() {
    final styles = [
      (key: 'short', label: '단발', icon: '💇'),
      (key: 'long', label: '긴머리', icon: '👩'),
      (key: 'wave', label: '웨이브', icon: '🦱'),
      (key: 'ponytail', label: '포니테일', icon: '👱‍♀️'),
      (key: 'bun', label: '똥머리', icon: '👧'),
      (key: 'bangs', label: '앞머리', icon: '🧑'),
      (key: 'curly', label: '뽀글이', icon: '🧑‍🦱'),
      (key: 'dandy', label: '댄디', icon: '👦'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: styles.map((s) {
          final isSelected = _config.hairStyle == s.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _update(_config.copyWith(hairStyle: s.key)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFE4E6) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF881337) : AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHairColorTab() {
    final colors = [
      (hex: '#2C1D11', label: '내추럴 블랙'),
      (hex: '#5C3A21', label: '다크 브라운'),
      (hex: '#8B5A2B', label: '초코 브라운'),
      (hex: '#C68B59', label: '라이트 브라운'),
      (hex: '#E5A65D', label: '골드 블론드'),
      (hex: '#D47B95', label: '파스텔 핑크'),
      (hex: '#7B889B', label: '애쉬 그레이'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: colors.map((c) {
          final isSelected = _config.hairColor.toLowerCase() == c.hex.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => _update(_config.copyWith(hairColor: c.hex)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${c.hex.replaceAll('#', '')}')),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.label,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpressionTab() {
    final expressions = [
      (key: 'smile', label: '미소', icon: '😊'),
      (key: 'wink', label: '윙크', icon: '😉'),
      (key: 'sparkle', label: '초롱초롱', icon: '✨'),
      (key: 'blush', label: '발그레', icon: '🥰'),
      (key: 'cool', label: '시크', icon: '😎'),
      (key: 'peace', label: '뿌듯', icon: '😌'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: expressions.map((e) {
          final isSelected = _config.expression == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _update(_config.copyWith(expression: e.key)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFE4E6) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF881337) : AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccessoryTab() {
    final accessories = [
      (key: 'none', label: '없음', icon: '❌'),
      (key: 'glasses_round', label: '동글안경', icon: '👓'),
      (key: 'glasses_square', label: '뿔테안경', icon: '🕶️'),
      (key: 'ribbon', label: '리본핀', icon: '🎀'),
      (key: 'beret', label: '모자', icon: '👒'),
      (key: 'party_hat', label: '고깔모자', icon: '🥳'),
      (key: 'star', label: '별핀', icon: '⭐'),
      (key: 'heart', label: '하트핀', icon: '💖'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: accessories.map((a) {
          final isSelected = _config.accessory == a.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _update(_config.copyWith(accessory: a.key)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFE4E6) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(a.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF881337) : AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkinAndFaceTab() {
    final skins = [
      (hex: '#FFE0BD', label: '밝은 톤'),
      (hex: '#F5D0A9', label: '웜톤'),
      (hex: '#E8B887', label: '내추럴'),
      (hex: '#C68642', label: '태닝'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: skins.map((s) {
          final isSelected = _config.skinColor.toLowerCase() == s.hex.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => _update(_config.copyWith(skinColor: s.hex)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${s.hex.replaceAll('#', '')}')),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBgColorTab() {
    final bgColors = [
      (hex: '#FFE4E6', label: '핑크'),
      (hex: '#FEF08A', label: '버터 옐로우'),
      (hex: '#DBEAFE', label: '스카이 블루'),
      (hex: '#DCFCE7', label: '민트 그린'),
      (hex: '#F3E8FF', label: '라벤더'),
      (hex: '#FFEDD5', label: '살구 오렌지'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: bgColors.map((b) {
          final isSelected = _config.bgColor.toLowerCase() == b.hex.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => _update(_config.copyWith(bgColor: b.hex)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${b.hex.replaceAll('#', '')}')),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
