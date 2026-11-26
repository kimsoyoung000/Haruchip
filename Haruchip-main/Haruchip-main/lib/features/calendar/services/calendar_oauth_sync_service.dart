import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/permissions/native_permission_service.dart';

/// 외부 캘린더 연동 방식 구분
enum CalendarSyncArchitecture {
  /// 기기 로컬 캘린더 동기화 (OS 캘린더 권한만으로 iCloud / Android 기본 캘린더에 쓰기)
  deviceLocal,

  /// 클라우드 OAuth 2.0 인증 기반 API 연동 (Google Calendar API / Naver Calendar API)
  cloudOAuth2,
}

/// OAuth 2.0 인증 요청 결과
@immutable
class CalendarOAuthResult {
  const CalendarOAuthResult({
    required this.providerKey,
    required this.launched,
    required this.authorizationUri,
    this.accessToken,
    this.message,
  });

  final String providerKey;
  final bool launched;
  final Uri authorizationUri;
  final String? accessToken;
  final String? message;
}

/// 구글 / 네이버 캘린더 OAuth 2.0 및 기기 로컬 캘린더 동기화 아키텍처 서비스
///
/// - [기기 로컬 캘린더(device_local)]: OS 캘린더 권한(`Permission.calendarFullAccess`)을 획득한 뒤
///   스마트폰 자체 캘린더 앱(iCloud / Android Calendar Provider)에 일정을 직접 기록한다.
/// - [구글/네이버 클라우드 연동(google / naver)]: 단순 기기 권한만으로는 클라우드 API에 접근할 수 없으므로,
///   OAuth 2.0 로그인 브라우저를 띄워 Access Token을 획득한 후 각 REST API를 호출하는 구조로 분리한다.
class CalendarOAuthSyncService {
  CalendarOAuthSyncService({
    required NativePermissionAdapter permissionAdapter,
    Future<bool> Function(Uri uri)? browserLauncher,
  })  : _permissionAdapter = permissionAdapter,
        _browserLauncher = browserLauncher ?? _defaultLaunchBrowser;

  final NativePermissionAdapter _permissionAdapter;
  final Future<bool> Function(Uri uri) _browserLauncher;

  static Future<bool> _defaultLaunchBrowser(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Calendar OAuth browser launch failed: $e');
      return false;
    }
  }

  /// 1) 기기 로컬 캘린더 동기화 권한 요청 (iCloud / Android 기본 캘린더)
  Future<NativePermissionOutcome> requestDeviceLocalCalendarSync() {
    return _permissionAdapter.request('calendar');
  }

  /// 2) 구글 / 네이버 OAuth 2.0 인증 URL 생성
  Uri buildOAuthAuthorizationUri(String providerKey) {
    if (providerKey == 'google') {
      return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': 'haruchip-google-calendar-oauth-client',
        'redirect_uri': 'com.haruchip.app:/oauth2redirect/google',
        'response_type': 'code',
        'access_type': 'offline',
        'prompt': 'consent',
        'scope': 'https://www.googleapis.com/auth/calendar.events',
      });
    }
    return Uri.https('nid.naver.com', '/oauth2.0/authorize', {
      'client_id': 'haruchip-naver-calendar-oauth-client',
      'redirect_uri': 'com.haruchip.app:/oauth2redirect/naver',
      'response_type': 'code',
      'state': 'haruchip_naver_cal_sync',
    });
  }

  /// 3) OAuth 2.0 로그인 브라우저 실행 (토글 ON 시 호출)
  Future<CalendarOAuthResult> startCloudOAuthFlow(String providerKey) async {
    final uri = buildOAuthAuthorizationUri(providerKey);
    final launched = await _browserLauncher(uri);
    final label = providerKey == 'google' ? '구글' : '네이버';
    return CalendarOAuthResult(
      providerKey: providerKey,
      launched: launched,
      authorizationUri: uri,
      message: launched
          ? '$label OAuth 2.0 로그인 화면으로 이동했습니다. 인증 완료 후 캘린더 API 동기화가 활성화됩니다.'
          : '$label 로그인 브라우저를 열 수 없습니다. 잠시 후 다시 시도해 주세요.',
    );
  }
}

final calendarOAuthSyncServiceProvider = Provider<CalendarOAuthSyncService>(
  (ref) => CalendarOAuthSyncService(
    permissionAdapter: ref.watch(nativePermissionAdapterProvider),
  ),
);
