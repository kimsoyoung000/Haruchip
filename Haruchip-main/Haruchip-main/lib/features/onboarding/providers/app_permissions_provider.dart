import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/native_permission_service.dart';
import '../models/app_permissions.dart';

/// 앱 네이티브 OS 접근 권한 상태 관리 노티파이어 (`permission_handler` 실기기 연동)
class AppPermissionsNotifier extends StateNotifier<AppPermissionsState> {
  AppPermissionsNotifier(this._adapter) : super(const AppPermissionsState());

  final NativePermissionAdapter _adapter;

  /// 기존 단위 테스트 및 수동 토글 호환용
  void toggleAll() {
    final nextVal = !state.allAgreed;
    state = state.setAll(nextVal);
    _syncWithLocalAndServer();
  }

  /// 기존 단위 테스트 및 수동 토글 호환용
  void toggle(String key) {
    state = state.toggle(key);
    _syncWithLocalAndServer();
  }

  /// 실기기 OS 시스템 권한 다이얼로그를 호출하고 결과([NativePermissionOutcome])를 반영한다.
  ///
  /// - `notification` -> `Permission.notification.request()`
  /// - `photos` -> `Permission.photos.request()` (iOS 14+ `limited` 지원, Android 12 이하 `storage` 폴백)
  /// - `camera` -> `Permission.camera.request()`
  /// - `calendar` -> `Permission.calendarFullAccess.request()`
  /// - 영구 거부(`permanentlyDenied`) 시 권한 상태를 false로 유지하고 호출부가 설정 앱 이동 팝업을 띄우도록 반환한다.
  Future<NativePermissionOutcome> requestNativePermission(String key) async {
    if (key == 'settlement') {
      toggle('settlement');
      return state.settlement
          ? NativePermissionOutcome.granted
          : NativePermissionOutcome.denied;
    }

    // 이미 허용된 항목을 다시 눌러 비활성화하려는 경우 OS 설정 이동 안내를 위해 상태만 해제
    if (state.isEnabled(key)) {
      setPermission(key, false);
      return NativePermissionOutcome.denied;
    }

    final outcome = await _adapter.request(key);
    if (key == 'photos') {
      state = state.copyWith(
        photos: outcome.isUsable,
        photosLimited: outcome == NativePermissionOutcome.limited,
      );
    } else {
      setPermission(key, outcome.isUsable);
    }
    _syncWithLocalAndServer();
    return outcome;
  }

  /// [전체 허용하기] — 모든 OS 접근 권한을 순차 요청하고 영구 거부된 항목 키 목록을 반환한다.
  Future<List<String>> requestAllNativePermissions() async {
    if (state.allAgreed) {
      state = state.setAll(false).copyWith(photosLimited: false);
      _syncWithLocalAndServer();
      return const <String>[];
    }

    final permanentlyDeniedKeys = <String>[];
    for (final item in kAppPermissionItems) {
      if (item.key == 'settlement') {
        setPermission('settlement', true);
        continue;
      }
      final outcome = await _adapter.request(item.key);
      if (item.key == 'photos') {
        state = state.copyWith(
          photos: outcome.isUsable,
          photosLimited: outcome == NativePermissionOutcome.limited,
        );
      } else {
        setPermission(item.key, outcome.isUsable);
      }
      if (outcome == NativePermissionOutcome.permanentlyDenied) {
        permanentlyDeniedKeys.add(item.key);
      }
    }
    _syncWithLocalAndServer();
    return permanentlyDeniedKeys;
  }

  Future<bool> openDeviceAppSettings() => _adapter.openSettings();

  void setPermission(String key, bool value) {
    switch (key) {
      case 'notification':
        state = state.copyWith(notification: value);
        break;
      case 'photos':
        state = state.copyWith(
          photos: value,
          photosLimited: value ? state.photosLimited : false,
        );
        break;
      case 'camera':
        state = state.copyWith(camera: value);
        break;
      case 'calendar':
        state = state.copyWith(calendar: value);
        break;
      case 'settlement':
        state = state.copyWith(settlement: value);
        break;
      case 'marketing':
        state = state.copyWith(marketing: value);
        break;
    }
    _syncWithLocalAndServer();
  }

  void _syncWithLocalAndServer() {
    debugPrint('AppPermissions synced: ${state.toJson()}');
  }
}

final appPermissionsProvider =
    StateNotifierProvider<AppPermissionsNotifier, AppPermissionsState>(
  (ref) => AppPermissionsNotifier(ref.watch(nativePermissionAdapterProvider)),
);
