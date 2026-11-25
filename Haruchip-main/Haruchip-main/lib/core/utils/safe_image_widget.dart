import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../icons/haruchip_icon_viewer.dart';

/// 데이터 URI(`data:image/...;base64,...`) 디코딩 바이트 캐시 (프레임당 재디코딩 방지)
final Map<String, Uint8List> _decodedDataUriCache = <String, Uint8List>{};

/// Base64 Data URI 여부 확인
bool isDataImageUri(String value) {
  final trimmed = value.trim();
  return trimmed.startsWith('data:image/') && trimmed.contains(';base64,');
}

/// Base64 Data URI를 안전하게 `Uint8List`로 디코딩 (캐시 적용)
Uint8List? decodeDataImageUri(String uri) {
  final cached = _decodedDataUriCache[uri];
  if (cached != null) return cached;
  final commaIndex = uri.indexOf(',');
  if (commaIndex < 0 || commaIndex + 1 >= uri.length) return null;
  try {
    final bytes = base64Decode(uri.substring(commaIndex + 1));
    if (_decodedDataUriCache.length > 64) {
      _decodedDataUriCache.clear();
    }
    _decodedDataUriCache[uri] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

/// `XFile`을 플랫폼 무관(Web/iOS/Android/Desktop) 메모리 기반 Data URI로 안전 변환
///
/// Flutter Web에서 `Image.file` / `FileImage` 크래시를 원천 차단하고,
/// 브라우저 새로고침 시 만료되는 `blob:` URL 대신 안정적인 바이트 기반 렌더링을 보장한다.
Future<String> xFileToSafeImageSource(XFile picked) async {
  final bytes = await picked.readAsBytes();
  final mime = _inferImageMimeType(picked.mimeType, picked.name, picked.path);
  final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
  _decodedDataUriCache[dataUri] = bytes;
  return dataUri;
}

String _inferImageMimeType(String? mimeType, String name, String path) {
  if (mimeType != null && mimeType.startsWith('image/')) {
    return mimeType;
  }
  final lower = (name.isNotEmpty ? name : path).toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

/// 이미지 로딩 실패 또는 데이터 미존재 시 노출하는 기본 하루칩 아바타
class DefaultChipAvatar extends StatelessWidget {
  const DefaultChipAvatar({
    super.key,
    this.iconKey = 'simple_heart',
    this.size = 32,
  });

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF5F7),
      alignment: Alignment.center,
      child: HaruChipIconViewer(
        iconKey: iconKey,
        size: size,
        circular: true,
      ),
    );
  }
}

/// Web/Mobile 크로스 플랫폼 안전 이미지 렌더링 위젯 (`kIsWeb` 분기 보장)
///
/// Flutter Web 환경에서는 절대 `Image.file`을 호출하지 않는다.
Widget buildUserImage(
  dynamic imageData, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? fallback,
}) {
  final fallbackWidget = fallback ?? const DefaultChipAvatar();

  if (imageData == null) return fallbackWidget;

  if (imageData is Uint8List) {
    if (imageData.isEmpty) return fallbackWidget;
    return Image.memory(
      imageData,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => fallbackWidget,
    );
  }

  if (imageData is String) {
    final trimmed = imageData.trim();
    if (trimmed.isEmpty) return fallbackWidget;

    if (isDataImageUri(trimmed)) {
      final bytes = decodeDataImageUri(trimmed);
      if (bytes == null || bytes.isEmpty) return fallbackWidget;
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackWidget,
      );
    }

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('blob:')) {
      return Image.network(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackWidget,
      );
    }

    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackWidget,
      );
    }

    if (!kIsWeb) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => fallbackWidget,
        );
      }
    }
    return fallbackWidget;
  }

  if (!kIsWeb && imageData is File) {
    if (imageData.existsSync()) {
      return Image.file(
        imageData,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackWidget,
      );
    }
  }

  return fallbackWidget;
}

/// `DecorationImage` / `CircleAvatar.backgroundImage`용 Web-safe `ImageProvider` 변환기
///
/// Flutter Web 환경에서는 절대 `FileImage`를 생성하지 않는다.
ImageProvider<Object>? resolveSafeImageProvider(dynamic imageData) {
  if (imageData == null) return null;

  if (imageData is Uint8List) {
    return imageData.isEmpty ? null : MemoryImage(imageData);
  }

  if (imageData is String) {
    final trimmed = imageData.trim();
    if (trimmed.isEmpty) return null;

    if (isDataImageUri(trimmed)) {
      final bytes = decodeDataImageUri(trimmed);
      return (bytes == null || bytes.isEmpty) ? null : MemoryImage(bytes);
    }

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('blob:')) {
      return NetworkImage(trimmed);
    }

    if (trimmed.startsWith('assets/')) {
      return AssetImage(trimmed);
    }

    if (!kIsWeb) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  if (!kIsWeb && imageData is File) {
    if (imageData.existsSync()) {
      return FileImage(imageData);
    }
  }

  return null;
}
