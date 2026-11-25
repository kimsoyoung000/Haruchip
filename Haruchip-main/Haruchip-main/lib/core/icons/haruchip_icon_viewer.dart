import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'haruchip_icon_registry.dart';

/// 앱 전역 아이콘 렌더링 일원화 보안 래퍼 컴포넌트
///
/// 1) `'asset:'` 또는 안전 레지스트리 화이트리스트 키 -> `SvgPicture.asset()` 렌더링
/// 2) `'file:'` -> 앱 내부 샌드박스 경로 유효성 검증 후 `Image.file()` 렌더링
/// 3) 경로 조작(`../` 등) 및 미등록 에셋 키 -> 안전 Fallback(`default_chip.svg`) 차단
/// 4) 기존 유니코드 텍스트(이모지) -> `Text(emoji)`로 100% 하위 호환 렌더링
class HaruChipIconViewer extends StatelessWidget {
  const HaruChipIconViewer({
    super.key,
    required this.iconKey,
    this.size = 24,
    this.color,
    this.circular = false,
    this.borderRadius,
  });

  final String iconKey;
  final double size;
  final Color? color;
  final bool circular;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final trimmed = iconKey.trim();

    // 0) 빈 값 -> 안전 Fallback SVG
    if (trimmed.isEmpty) {
      return _buildFallbackSvg();
    }

    // 1) 'file:' -> 앱 샌드박스 내부 경로 유효성 검사 후 Image.file() 렌더링
    if (trimmed.startsWith(HaruChipIconRegistry.filePrefix)) {
      final syncFile = HaruChipIconSandbox.resolveSafeSandboxFileSync(trimmed);
      if (syncFile != null) {
        return _buildClippedFileImage(syncFile);
      }
      return FutureBuilder<File?>(
        future: HaruChipIconSandbox.resolveSafeSandboxFile(trimmed),
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file == null) {
            return _buildFallbackSvg();
          }
          return _buildClippedFileImage(file);
        },
      );
    }

    // 2) 'asset:' 또는 화이트리스트 레지스트리 키 -> SvgPicture.asset() 렌더링
    if (HaruChipIconRegistry.isSafeRegistryKey(trimmed)) {
      final normalized = HaruChipIconRegistry.normalizeKey(trimmed);
      final assetPath = HaruChipIconRegistry.getAssetPath(normalized);
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => SizedBox(width: size, height: size),
      );
    }

    // 3) 경로 조작(../ 등) 또는 미등록 에셋 키 시도 -> 무조건 안전 Fallback으로 차단
    if (HaruChipIconRegistry.isAssetKeyAttempt(trimmed)) {
      return _buildFallbackSvg();
    }

    // 4) 기존 유니코드 텍스트(이모지) -> 하위 호환 Text 렌더링
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          trimmed,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size * 0.85,
            height: 1.1,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackSvg() {
    return SvgPicture.asset(
      HaruChipIconRegistry.defaultFallbackAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }

  Widget _buildClippedFileImage(File file) {
    final image = Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildFallbackSvg(),
    );

    if (circular) {
      return ClipOval(child: image);
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size * 0.25),
      child: image,
    );
  }
}
