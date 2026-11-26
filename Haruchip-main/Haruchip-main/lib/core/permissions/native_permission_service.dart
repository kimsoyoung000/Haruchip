import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../design_system/colors.dart';

/// 네이티브 OS 권한 요청 결과 모델
enum NativePermissionOutcome {
  /// 전체 허용됨
  granted,

  /// iOS 14+ 사진 라이브러리 제한된 접근(선택 사진 허용)
  limited,

  /// 일시 거부됨
  denied,

  /// 영구 거부("허용 안 함" / 다시 묻지 않음) -> 설정 앱 이동 유도 필요
  permanentlyDenied,
}

extension NativePermissionOutcomeX on NativePermissionOutcome {
  bool get isUsable =>
      this == NativePermissionOutcome.granted ||
      this == NativePermissionOutcome.limited;
}

/// 실기기 OS 권한 요청 어댑터 인터페이스 (테스트 모킹 가능)
abstract class NativePermissionAdapter {
  Future<NativePermissionOutcome> request(String permissionKey);
  Future<NativePermissionOutcome> check(String permissionKey);
  Future<bool> openSettings();
}

/// `permission_handler` 기반 Android/iOS 실기기 네이티브 권한 엔진
class PermissionHandlerAdapter implements NativePermissionAdapter {
  const PermissionHandlerAdapter();

  NativePermissionOutcome _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isProvisional) {
      return NativePermissionOutcome.granted;
    }
    if (status.isLimited) {
      return NativePermissionOutcome.limited;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return NativePermissionOutcome.permanentlyDenied;
    }
    return NativePermissionOutcome.denied;
  }

  Permission? _resolvePermission(String key) {
    switch (key) {
      case 'notification':
        return Permission.notification;
      case 'photos':
        return Permission.photos;
      case 'camera':
        return Permission.camera;
      case 'calendar':
        return Permission.calendarFullAccess;
      default:
        return null;
    }
  }

  @override
  Future<NativePermissionOutcome> request(String permissionKey) async {
    // Web 환경에서는 브라우저 권한 정책을 따르며 네이티브 플러그인 크래시를 방지한다.
    if (kIsWeb) {
      return NativePermissionOutcome.granted;
    }

    final permission = _resolvePermission(permissionKey);
    if (permission == null) {
      return NativePermissionOutcome.granted;
    }

    try {
      var status = await permission.request();

      // Android 12 이하 구버전 호환: photos가 거부/미지원일 때 storage로 폴백 검증
      if (permissionKey == 'photos' &&
          defaultTargetPlatform == TargetPlatform.android &&
          status.isDenied) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          status = storageStatus;
        }
      }
      return _mapStatus(status);
    } catch (e) {
      debugPrint('Native permission request failed ($permissionKey): $e');
      return NativePermissionOutcome.denied;
    }
  }

  @override
  Future<NativePermissionOutcome> check(String permissionKey) async {
    if (kIsWeb) return NativePermissionOutcome.granted;
    final permission = _resolvePermission(permissionKey);
    if (permission == null) return NativePermissionOutcome.granted;
    try {
      final status = await permission.status;
      return _mapStatus(status);
    } catch (_) {
      return NativePermissionOutcome.denied;
    }
  }

  @override
  Future<bool> openSettings() async {
    if (kIsWeb) return false;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}

final nativePermissionAdapterProvider = Provider<NativePermissionAdapter>(
  (ref) => const PermissionHandlerAdapter(),
);

/// 영구 거부(Permanently Denied) 시 OS 앱 설정 화면 이동을 유도하는 공통 다이얼로그
Future<bool> showPermanentlyDeniedSettingsDialog(
  BuildContext context, {
  required String permissionTitle,
  required Future<bool> Function() onOpenSettings,
}) async {
  final moved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '$permissionTitle 권한이 필요합니다',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.protoHeading,
        ),
      ),
      content: Text(
        '시스템 설정에서 권한이 거부되어 있어요.\n'
        '설정 > 하루칩에서 $permissionTitle 권한을 허용해 주세요.',
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: Color(0xFF4B5563),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            '취소',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        ElevatedButton(
          key: const Key('permission_open_settings_btn'),
          onPressed: () async {
            Navigator.of(ctx).pop(true);
            await onOpenSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.chipYellowBg,
            foregroundColor: AppColors.chipYellowText,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '설정으로 이동',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  return moved ?? false;
}
