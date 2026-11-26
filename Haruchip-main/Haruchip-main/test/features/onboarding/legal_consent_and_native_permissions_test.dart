import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/permissions/native_permission_service.dart';
import 'package:haruchip/features/calendar/services/calendar_oauth_sync_service.dart';
import 'package:haruchip/features/onboarding/models/app_permissions.dart';
import 'package:haruchip/features/onboarding/models/legal_consent.dart';
import 'package:haruchip/features/onboarding/providers/legal_consent_provider.dart';
import 'package:haruchip/features/onboarding/screens/app_permission_screen.dart';
import 'package:haruchip/features/onboarding/screens/calendar_integration_screen.dart';
import 'package:haruchip/features/onboarding/screens/legal_consent_screen.dart';

class _FakePermissionAdapter implements NativePermissionAdapter {
  _FakePermissionAdapter(this.outcomes);

  final Map<String, NativePermissionOutcome> outcomes;
  final List<String> requestedKeys = [];
  bool openedSettings = false;

  @override
  Future<NativePermissionOutcome> request(String permissionKey) async {
    requestedKeys.add(permissionKey);
    return outcomes[permissionKey] ?? NativePermissionOutcome.granted;
  }

  @override
  Future<NativePermissionOutcome> check(String permissionKey) async {
    return outcomes[permissionKey] ?? NativePermissionOutcome.denied;
  }

  @override
  Future<bool> openSettings() async {
    openedSettings = true;
    return true;
  }
}

void main() {
  group('Legal Compliance, Native OS Permissions & OAuth 2.0 Calendar Tests', () {
    testWidgets(
      '1. 법적 약관 동의 화면: 필수 2종 미동의 시 버튼 비활성화, 전문 모달, 마케팅 동의 토스트 & Firestore Timestamp 로깅',
      (tester) async {
        final fakeDb = FakeFirebaseFirestore();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        var proceeded = false;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LegalConsentScreen(
                onNext: () => proceeded = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 초기 상태: [동의하고 시작하기] 비활성화
        final submitBtnFinder =
            find.byKey(const Key('legal_consent_submit_btn'));
        expect(
          tester.widget<ElevatedButton>(submitBtnFinder).onPressed,
          isNull,
        );

        // [필수 2] 개인정보 수집 및 이용 동의 전문 보기 모달 확인
        await tester.tap(find.byKey(const Key('legal_consent_privacy_view')));
        await tester.pumpAndSettle();
        expect(find.textContaining('1. 수집 항목'), findsOneWidget);
        expect(find.textContaining('3. 보유 및 이용 기간'), findsOneWidget);
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();

        // 필수 1만 체크해도 여전히 비활성화
        await tester.tap(find.byKey(const Key('legal_consent_terms')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<ElevatedButton>(submitBtnFinder).onPressed,
          isNull,
        );

        // 필수 2까지 체크하면 활성화
        await tester.tap(find.byKey(const Key('legal_consent_privacy')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<ElevatedButton>(submitBtnFinder).onPressed,
          isNotNull,
        );

        // [선택 1] 마케팅 동의 체크 -> 법적 일시 토스트 노출
        await tester.tap(find.byKey(const Key('legal_consent_marketing')));
        await tester.pumpAndSettle();
        final expectedToast =
            LegalConsentState.formatMarketingConsentToast(DateTime.now());
        expect(find.text(expectedToast), findsOneWidget);

        // Firestore marketingAgreedAt: Timestamp 법적 로깅 검증
        await container
            .read(legalConsentProvider.notifier)
            .commitConsentToDatabase(
              firestoreOverride: fakeDb,
              uidOverride: 'user-legal-1',
            );
        final doc = await fakeDb.collection('users').doc('user-legal-1').get();
        expect(doc.data()?['marketingAgreed'], isTrue);
        expect(doc.data()?['marketingAgreedAt'], isA<Timestamp>());

        // 스낵바가 사라진 뒤 제출 버튼 탭 -> 다음 단계 진행
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        await tester.tap(submitBtnFinder);
        await tester.pumpAndSettle();
        expect(proceeded, isTrue);
      },
    );

    testWidgets(
      '2. 네이티브 OS 권한 엔진: iOS 제한된 사진 접근 대응 & 영구 거부 시 설정 앱 이동(openAppSettings) 유도',
      (tester) async {
        // 마케팅 동의 항목이 OS 권한 화면에서 완전히 분리되었는지 확인
        expect(
          kAppPermissionItems.any((e) => e.key == 'marketing'),
          isFalse,
        );

        final fakeAdapter = _FakePermissionAdapter({
          'photos': NativePermissionOutcome.limited,
          'camera': NativePermissionOutcome.permanentlyDenied,
        });

        final container = ProviderContainer(
          overrides: [
            nativePermissionAdapterProvider.overrideWithValue(fakeAdapter),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: AppPermissionScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1) 사진 권한 탭 -> iOS 14+ 제한된 접근(limited) 허용 & '제한된 접근' 뱃지 노출
        await tester.tap(find.byKey(const Key('app_permission_row_photos')));
        await tester.pumpAndSettle();
        expect(fakeAdapter.requestedKeys, contains('photos'));
        expect(find.text('제한된 접근'), findsOneWidget);

        // 2) 카메라 권한 탭 -> 영구 거부 -> 설정 이동 다이얼로그 & openAppSettings() 호출
        await tester.tap(find.byKey(const Key('app_permission_row_camera')));
        await tester.pumpAndSettle();
        expect(find.textContaining('설정 > 하루칩에서 카메라 권한을 허용해 주세요'), findsOneWidget);

        await tester.tap(find.byKey(const Key('permission_open_settings_btn')));
        await tester.pumpAndSettle();
        expect(fakeAdapter.openedSettings, isTrue);
      },
    );

    testWidgets(
      '3. 캘린더 연동 아키텍처 분리: 기기 로컬 캘린더 권한 vs 구글/네이버 OAuth 2.0 로그인 브라우저 실행',
      (tester) async {
        final fakeAdapter = _FakePermissionAdapter({
          'calendar': NativePermissionOutcome.granted,
        });
        final launchedUris = <Uri>[];

        final container = ProviderContainer(
          overrides: [
            nativePermissionAdapterProvider.overrideWithValue(fakeAdapter),
            calendarOAuthSyncServiceProvider.overrideWithValue(
              CalendarOAuthSyncService(
                permissionAdapter: fakeAdapter,
                browserLauncher: (uri) async {
                  launchedUris.add(uri);
                  return true;
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: CalendarIntegrationScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1) 기기 로컬 캘린더 토글 -> OS 캘린더 권한 요청
        await tester.tap(find.byKey(const Key('calendar_device_local_toggle')));
        await tester.pumpAndSettle();
        expect(fakeAdapter.requestedKeys, contains('calendar'));

        // 2) 구글 캘린더 카드 탭 -> Google OAuth 2.0 URL 브라우저 실행
        await tester.ensureVisible(
          find.byKey(const Key('calendar_oauth_card_google')),
        );
        await tester.tap(find.byKey(const Key('calendar_oauth_card_google')));
        await tester.pumpAndSettle();
        expect(
          launchedUris.any((u) => u.host == 'accounts.google.com'),
          isTrue,
        );

        // 3) 네이버 캘린더 카드 탭 -> Naver OAuth 2.0 URL 브라우저 실행
        await tester.ensureVisible(
          find.byKey(const Key('calendar_oauth_card_naver')),
        );
        await tester.tap(find.byKey(const Key('calendar_oauth_card_naver')));
        await tester.pumpAndSettle();
        expect(
          launchedUris.any((u) => u.host == 'nid.naver.com'),
          isTrue,
        );
      },
    );

    test(
      '4. AndroidManifest.xml 및 iOS Info.plist 필수 OS 권한 선언 검증',
      () {
        final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
        expect(infoPlist, contains('NSPhotoLibraryUsageDescription'));
        expect(infoPlist, contains('NSCameraUsageDescription'));
        expect(infoPlist, contains('NSCalendarsUsageDescription'));

        final manifest = File('android/app/src/main/AndroidManifest.xml')
            .readAsStringSync();
        expect(manifest, contains('android.permission.READ_MEDIA_IMAGES'));
        expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
        expect(manifest, contains('android.permission.READ_CALENDAR'));
        expect(manifest, contains('android.permission.WRITE_CALENDAR'));
        expect(manifest, contains('android.permission.CAMERA'));
      },
    );
  });
}
