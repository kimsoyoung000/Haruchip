import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/onboarding/providers/dashboard_view_mode_provider.dart';
import 'package:haruchip/features/onboarding/screens/category_selection_screen.dart';
import 'package:haruchip/features/onboarding/screens/dashboard_view_mode_screen.dart';
import 'package:haruchip/features/onboarding/screens/onboarding_complete_screen.dart';
import 'package:haruchip/features/onboarding/screens/splash_screen.dart';

void main() {
  group('Onboarding & Splash Luxury Minimal Polishing Tests', () {
    testWidgets(
      '1. SplashScreen: 럭셔리 실버-화이트(#F8F9FA) 배경, HARUCHIP / 하루칩(#3A2E1A) / 서브카피 미니멀 타이포 검증',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: SplashScreen(onNext: () {}),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, const Color(0xFFF8F9FA));

        expect(find.text('HARUCHIP'), findsOneWidget);
        expect(find.text('하루칩'), findsOneWidget);
        expect(find.text('매일의 디데이, 일상의 조각을 맞추다'), findsOneWidget);

        final mainLogoText = tester.widget<Text>(find.text('하루칩'));
        expect(mainLogoText.style?.color, const Color(0xFF3A2E1A));
        expect(mainLogoText.style?.letterSpacing, -0.5);

        // 타이머 정리
        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      '2. CategorySelectionScreen: 뷰모드 선택 화면(3/3) 완전 스킵 -> OnboardingCompleteScreen 직행 & 자연스러운 문구 검증',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: CategorySelectionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 커플 카테고리 1개 선택 후 [하루칩 시작하기] 버튼 활성화 확인
        await tester.tap(find.text('커플'));
        await tester.pumpAndSettle();
        expect(find.text('하루칩 시작하기'), findsOneWidget);

        // 탭 시 DashboardViewModeScreen을 거치지 않고 OnboardingCompleteScreen으로 즉시 진입
        await tester.tap(find.text('하루칩 시작하기'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(DashboardViewModeScreen), findsNothing);
        expect(find.byType(OnboardingCompleteScreen), findsOneWidget);
        expect(find.text('당신의 특별한 하루를 단정하게 담아낼게요.'), findsOneWidget);
        expect(find.text('시작하겠습니다'), findsNothing);

        // 완료 화면 자동 전환 타이머 정리
        await tester.pump(const Duration(seconds: 1));
      },
    );

    test(
      '3. 기본 대시보드 뷰모드: 세로 스크롤 박스형(vertical) 기본 고정 및 설정 전환 동작 검증',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(resolvedDashboardViewModeProvider), 'vertical');
        container.read(dashboardViewModeProvider.notifier).select('grid');
        expect(container.read(resolvedDashboardViewModeProvider), 'grid');
        container.read(dashboardViewModeProvider.notifier).select('vertical');
        expect(container.read(resolvedDashboardViewModeProvider), 'vertical');
      },
    );
  });
}
