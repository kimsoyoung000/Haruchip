import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/y2k_diary_models.dart';

/// Y2K 프리 다꾸 캔버스 (인터랙티브 멀티 제스처 스티커 & 테이프 조작기)
class Y2KFreeCanvas extends StatefulWidget {
  const Y2KFreeCanvas({
    super.key,
    required this.stickers,
    required this.onUpdateSticker,
    required this.onDeleteSticker,
    this.height = 360,
  });

  final List<PlacedSticker> stickers;
  final void Function(PlacedSticker updated) onUpdateSticker;
  final void Function(String id) onDeleteSticker;
  final double height;

  @override
  State<Y2KFreeCanvas> createState() => _Y2KFreeCanvasState();
}

class _Y2KFreeCanvasState extends State<Y2KFreeCanvas> {
  String? _selectedStickerId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_selectedStickerId != null) {
          setState(() => _selectedStickerId = null);
        }
      },
      child: Container(
        height: widget.height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFC0CB), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF69B4).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasW = constraints.maxWidth;
            final canvasH = constraints.maxHeight;

            return Stack(
              children: [
                // 캔버스 배경 그리드 & 워터마크
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CanvasGridPainter(),
                  ),
                ),
                if (widget.stickers.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎨', style: TextStyle(fontSize: 40, color: Colors.pink.withValues(alpha: 0.4))),
                        const SizedBox(height: 8),
                        Text(
                          '하단 [+ 스티커북]을 눌러\n자유롭게 다이어리를 꾸며보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 배치된 스티커 렌더링
                for (final sticker in widget.stickers)
                  _buildInteractiveSticker(sticker, canvasW, canvasH),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInteractiveSticker(PlacedSticker sticker, double canvasW, double canvasH) {
    final isSelected = _selectedStickerId == sticker.id;
    final pixelX = sticker.x * canvasW;
    final pixelY = sticker.y * canvasH;

    return Positioned(
      left: pixelX - 40,
      top: pixelY - 40,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedStickerId = sticker.id);
        },
        onDoubleTap: () {
          HapticFeedback.mediumImpact();
          widget.onDeleteSticker(sticker.id);
        },
        onPanUpdate: (details) {
          final newX = (sticker.x + details.delta.dx / canvasW).clamp(0.05, 0.95);
          final newY = (sticker.y + details.delta.dy / canvasH).clamp(0.05, 0.95);
          widget.onUpdateSticker(sticker.copyWith(x: newX, y: newY));
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 스티커 본체 (회전 및 스케일 적용)
            Transform.rotate(
              angle: sticker.rotation,
              child: Transform.scale(
                scale: sticker.scale,
                child: Container(
                  padding: isSelected ? const EdgeInsets.all(6) : EdgeInsets.zero,
                  decoration: isSelected
                      ? BoxDecoration(
                          border: Border.all(color: const Color(0xFFFF4081), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: sticker.isTextTape
                      ? _buildTapeSticker(sticker)
                      : Text(
                          sticker.icon,
                          style: const TextStyle(fontSize: 42),
                        ),
                ),
              ),
            ),

            // 포커스 시 우하단 크기/회전 조절 핸들
            if (isSelected) ...[
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final newScale = (sticker.scale + details.delta.dx * 0.02).clamp(0.5, 3.0);
                    final newRot = sticker.rotation + details.delta.dy * 0.03;
                    widget.onUpdateSticker(sticker.copyWith(scale: newScale, rotation: newRot));
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4081),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.crop_rotate_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
              // 우상단 삭제 버튼
              Positioned(
                right: -8,
                top: -8,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onDeleteSticker(sticker.id);
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTapeSticker(PlacedSticker sticker) {
    final color = Color(int.parse('FF${sticker.tapeColorHex.replaceAll('#', '')}', radix: 16));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sticker.text ?? sticker.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0xFFFFD1DC).withValues(alpha: 0.4);
    const step = 20.0;

    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
