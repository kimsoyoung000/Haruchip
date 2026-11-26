import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/design_system/colors.dart';
import 'package:haruchip/design_system/layout_tokens.dart';
import 'package:haruchip/features/calendar/providers/calendar_display_settings_provider.dart';
import 'package:haruchip/features/calendar/screens/calendar_screen.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/screens/couple_category_detail_screen.dart';
import 'package:haruchip/features/home/providers/main_tab_provider.dart';
import 'package:haruchip/features/home/screens/dashboard_screen.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/home/widgets/add_category_dashboard_card.dart';

void main() {
  group('Global Layout Padding, Luxury White & Calendar UX Refactor Tests', () {
    testWidgets(
      '1. 메인 대시보드: 럭셔리 소프트 화이트(#FAFAFC) 배경, 하단 네비게이션바 0.8dp 경계선, 점선 추가 카드 영구 삭제 & 상단 [+] 아이콘 이관',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: MainShellScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 메인 대시보드 배경색 #FAFAFC 확인
        final mainScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(mainScaffold.backgroundColor, const Color(0xFFFAFAFC));
        expect(AppColors.protoBackground, const Color(0xFFFAFAFC));

        // 하단 네비게이션바 미세 경계선 (0xFFF0F0F2, width 0.8) 확인
        final navContainer = tester.widget<Container>(
          find.byKey(const Key('main_bottom_nav_bar')),
        );
        final navDeco = navContainer.decoration as BoxDecoration;
        expect(
          navDeco.border,
          const Border(top: BorderSide(color: Color(0xFFF0F0F2), width: 0.8)),
        );

        // 하단 점선 '새 카테고리 추가하기' 카드 영구 삭제 확인
        expect(find.byType(AddCategoryDashboardCard), findsNothing);
        expect(find.text('새 카테고리 추가하기'), findsNothing);

        // 상단 앱바 우측: [+] 버튼이 [📅 카테고리 필터] 좌측에 배치되었는지 확인
        final addBtnFinder = find.byKey(const Key('dashboard_add_category_button'));
        final filterBtnFinder =
            find.byKey(const Key('dashboard_category_filter_button'));
        expect(addBtnFinder, findsOneWidget);
        expect(filterBtnFinder, findsOneWidget);
        expect(
          tester.getCenter(addBtnFinder).dx,
          lessThan(tester.getCenter(filterBtnFinder).dx),
        );

        // [+] 버튼 탭 시 새 카테고리 추가 모달 즉시 오픈 확인
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();
        expect(find.text('카테고리 추가하기'), findsOneWidget);
      },
    );

    testWidgets(
      '2. 칩 캘린더 탭: 완전 순백색(#FFFFFF) 풀 확장 & 상단 [월간|주간|목록]+[🔍]+[📅] 우측 정렬 고정 검증',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // 온보딩 바텀시트 자동 팝업 방지
        container.read(calendarDisplaySettingsProvider.notifier).markOnboardingSeen();
        container.read(mainTabIndexProvider.notifier).select(1);

        tester.view.physicalSize = const Size(900, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: MainShellScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // MainShellScreen과 CalendarScreen 모두 순백색(#FFFFFF)
        final shellScaffold =
            tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(shellScaffold.backgroundColor, Colors.white);

        final calScaffold = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(CalendarScreen),
            matching: find.byType(Scaffold),
          ),
        );
        expect(calScaffold.backgroundColor, Colors.white);

        // 우측 정렬 확인: 월 숫자(좌측) < [월간|주간|목록] < [🔍] < [📅]
        final monthPickerDx = tester
            .getCenter(find.byKey(const Key('calendar_year_month_picker_button')))
            .dx;
        final monthTabDx = tester.getCenter(find.text('월간')).dx;
        final searchDx =
            tester.getCenter(find.byKey(const Key('calendar_search_button'))).dx;
        final filterDx = tester
            .getCenter(find.byKey(const Key('calendar_category_filter_button')))
            .dx;

        expect(monthPickerDx, lessThan(200));
        expect(monthTabDx, greaterThan(450)); // 우측 절반에 정렬
        expect(monthTabDx, lessThan(searchDx));
        expect(searchDx, lessThan(filterDx));
      },
    );

    testWidgets(
      '3. 전 카테고리 & 메인 대시보드 좌우 여백 14dp 전역 표준화 검증',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // 1) DashboardScreen 좌우 여백 14dp 확인
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final dashScroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView).first,
        );
        expect(
          (dashScroll.padding as EdgeInsets).left,
          AppLayoutTokens.screenHorizontalMargin,
        );
        expect(
          (dashScroll.padding as EdgeInsets).right,
          AppLayoutTokens.screenHorizontalMargin,
        );

        // 2) CoupleCategoryDetailScreen 좌우 여백 14dp 확인
        final coupleCat = CategoryModel(
          id: 'cat_couple',
          categoryKey: 'couple',
          name: '커플',
          icon: 'couple_heart',
          colorHex: '#FF7A9C',
          createdAt: DateTime(2026, 1, 1),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: CoupleCategoryDetailScreen(category: coupleCat),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final coupleScroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView).first,
        );
        expect((coupleScroll.padding as EdgeInsets).left, 14.0);
        expect((coupleScroll.padding as EdgeInsets).right, 14.0);
      },
    );
  });
}
