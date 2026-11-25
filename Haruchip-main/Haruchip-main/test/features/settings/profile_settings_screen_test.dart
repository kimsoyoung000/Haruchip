import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_viewer.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/home/screens/trash_bin_screen.dart';
import 'package:haruchip/features/onboarding/providers/calendar_integration_provider.dart';
import 'package:haruchip/features/onboarding/providers/dashboard_view_mode_provider.dart';
import 'package:haruchip/features/settings/screens/profile_settings_screen.dart';
import 'package:haruchip/features/trash/models/trash_item.dart';
import 'package:haruchip/features/trash/providers/trash_provider.dart';
import 'package:haruchip/main.dart';

void main() {
  Widget buildTestApp({Widget? child}) {
    return ProviderScope(
      overrides: [
        trashBinProvider.overrideWith(
          (ref) => TrashBinNotifier([
            TrashItem(
              id: 'test-trash-1',
              entityType: TrashEntityType.plan,
              originalTitle: '테스트 삭제 일정',
              deletedAt: DateTime.now().subtract(const Duration(days: 2)),
              originalData: {},
            ),
          ]),
        ),
      ],
      child: MaterialApp(
        home: child ?? const ProfileSettingsScreen(),
      ),
    );
  }

  group('ProfileSettingsScreen UI & Features', () {
    testWidgets('renders all core sections: profile, data management, preferences, and account security', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 헤더 및 프로필 (보안: 고유 유저 식별 코드 HARU-8921-X9 영구 삭제 확인)
      expect(find.text('프로필 & 설정'), findsOneWidget);
      expect(find.text('하루칩 여행자'), findsOneWidget);
      expect(find.text('HARU-8921-X9'), findsNothing);
      expect(find.text('프로필 수정'), findsOneWidget);

      // 7대 도메인 섹션 확인
      expect(find.text('대시보드 (디데이) 설정'), findsOneWidget);
      expect(find.text('대시보드 뷰 모드 설정'), findsOneWidget);
      expect(find.text('타임라인 뷰'), findsOneWidget);
      expect(find.text('칩 모아보기 뷰'), findsOneWidget);

      expect(find.text('칩 캘린더 설정'), findsOneWidget);
      expect(find.text('외부 캘린더 동기화 설정'), findsOneWidget);
      expect(find.text('Google 캘린더 연동'), findsOneWidget);
      expect(find.text('네이버 캘린더 연동'), findsOneWidget);

      expect(find.text('칩 모임 설정'), findsOneWidget);
      expect(find.text('위젯 설정'), findsOneWidget);
      expect(find.text('화면 & 글꼴 설정'), findsOneWidget);

      expect(find.text('데이터 관리 & 백업'), findsOneWidget);
      expect(find.text('휴지통 (삭제된 D-Day 복구/영구삭제)'), findsOneWidget);
      expect(find.text('1개 보관 중'), findsOneWidget);
      expect(find.text('전체 데이터 백업 내보내기'), findsOneWidget);

      // 계정 및 보안 (위험 영역 최하단 격리) + 버전 정보
      expect(find.text('계정 및 보안'), findsOneWidget);
      expect(find.text('앱 접근 권한 재설정'), findsOneWidget);
      expect(find.text('화면 잠금 설정'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.text('회원 탈퇴 (계정 영구 삭제)'), findsOneWidget);
      expect(find.text('HaruChip v2.5.0'), findsOneWidget);

      // 전역 스크롤바 숨김 확인
      const behavior = HaruAppScrollBehavior();
      const child = SizedBox();
      expect(
        behavior.buildScrollbar(
          tester.element(find.byType(ProfileSettingsScreen)),
          child,
          ScrollableDetails.vertical(),
        ),
        same(child),
      );
    });

    testWidgets('modifies nickname through edit profile dialog', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인
      expect(find.text('하루칩에서 사용할 닉네임을 입력해 주세요.'), findsOneWidget);
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, '행복한 하루');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // 변경된 닉네임 확인
      expect(find.text('행복한 하루'), findsOneWidget);
    });

    testWidgets('opens avatar emoji bottom sheet when tapping avatar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 아바타 터치 (HaruChipIconViewer)
      await tester.tap(find.byType(HaruChipIconViewer).first);
      await tester.pumpAndSettle();

      expect(find.text('프로필 아이콘 선택'), findsOneWidget);
      expect(find.text('아이콘'), findsOneWidget);
      expect(find.text('사진'), findsOneWidget);

      // 아이콘 선택 (하트)
      await tester.tap(find.byTooltip('하트'));
      await tester.pumpAndSettle();

      final viewer = tester.widget<HaruChipIconViewer>(find.byType(HaruChipIconViewer).first);
      expect(viewer.iconKey, 'simple_heart');
    });

    testWidgets('toggles calendar integration and view mode providers', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Google 캘린더 토글
      expect(container.read(calendarIntegrationProvider).contains('google'), isFalse);
      final googleSwitch = find.byWidgetPredicate(
        (w) => w is Switch && w.value == false,
      );
      expect(googleSwitch, findsWidgets);
      await tester.ensureVisible(googleSwitch.first);
      await tester.tap(googleSwitch.first);
      await tester.pumpAndSettle();
      expect(container.read(calendarIntegrationProvider).contains('google'), isTrue);

      // 뷰 모드 토글 (칩 모아보기 뷰 선택)
      await tester.ensureVisible(find.text('칩 모아보기 뷰'));
      await tester.tap(find.text('칩 모아보기 뷰'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardViewModeProvider), equals('grid'));
    });

    testWidgets('shows warning dialog on 회원 탈퇴 and logout dialog on 로그아웃', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 로그아웃 다이얼로그
      await tester.ensureVisible(find.text('로그아웃'));
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      expect(find.text('현재 계정에서 로그아웃하시겠습니까?'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // 회원 탈퇴 다이얼로그 (애플 심사 필수 준수)
      await tester.ensureVisible(find.text('회원 탈퇴 (계정 영구 삭제)'));
      await tester.tap(find.text('회원 탈퇴 (계정 영구 삭제)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('모든 D-Day와 공유 방 데이터가 즉시 파기되며 복구할 수 없습니다.'), findsOneWidget);
      expect(find.text('즉시 탈퇴'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to TrashBinScreen when tapping trash tile', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('휴지통 (삭제된 D-Day 복구/영구삭제)'));
      await tester.tap(find.text('휴지통 (삭제된 D-Day 복구/영구삭제)'));
      await tester.pumpAndSettle();

      expect(find.byType(TrashBinScreen), findsOneWidget);
    });
  });

  group('MainShellScreen 4-Tab Navigation & Clean Header', () {
    testWidgets('displays simplified top header and 4 tabs with Profile & Settings', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 상단 헤더: 브랜드명 텍스트 제거 및 알림 아이콘만 존재
      expect(find.text('하루칩'), findsNothing);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

      // 제거된 요소 확인: 'HaruChip Life & D-Day', 노란 H 로고, 설정/휴지통 아이콘
      expect(find.text('HaruChip Life & D-Day'), findsNothing);
      expect(find.text('한눈에 보는 나의 디데이 요약'), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // 하단 4대 탭 구조 확인
      expect(find.text('칩 데이'), findsOneWidget);
      expect(find.text('칩 캘린더'), findsOneWidget);
      expect(find.text('칩 모임'), findsOneWidget);
      expect(find.text('프로필 & 설정'), findsOneWidget);
      expect(find.text('칩 다이어리'), findsNothing); // 완전 삭제 확인

      // 4번째 탭 탭 시 ProfileSettingsScreen으로 전환
      await tester.tap(find.text('프로필 & 설정'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSettingsScreen), findsOneWidget);
      expect(find.text('HARU-8921-X9'), findsNothing);
      expect(find.text('대시보드 (디데이) 설정'), findsOneWidget);
    });
  });
}
