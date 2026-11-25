import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_viewer.dart';
import 'package:haruchip/core/theme/app_font_settings_provider.dart';
import 'package:haruchip/design_system/colors.dart';
import 'package:haruchip/features/calendar/widgets/calendar_category_filter_sheet.dart';
import 'package:haruchip/features/calendar/widgets/themed_color_palette_sheet.dart';
import 'package:haruchip/features/categories/data/category_types.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/categories/widgets/category_edit_modal.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/home/widgets/add_category_dashboard_modal.dart';
import 'package:haruchip/features/settings/screens/profile_settings_screen.dart';

void main() {
  group('배경 톤 통일 · 꾸미기 2탭 다이어트 · 전역 폰트 설정 검증', () {
    test('하루칩 시그니처 옐로우 및 클린 캔버스 토큰이 정확히 정의되어 있다', () {
      expect(AppColors.cleanCanvasBg, const Color(0xFFF8F9FA));
      expect(AppColors.cleanWhiteBg, const Color(0xFFFFFFFF));
      expect(AppColors.protoBackground, const Color(0xFFF8F9FA));
      expect(AppColors.chipYellowBg, const Color(0xFFFFE699));
      expect(AppColors.chipYellowText, const Color(0xFF3A2E1A));
      expect(AppColors.chipGoldOutline, const Color(0xFFF2B84B));
    });

    testWidgets('CategoryEditModal은 [기본 정보] | [스킨] 2탭만 노출하며 Y2K/스티커/텍스트/테두리 설정이 제거되었다', (tester) async {
      final category = CategoryModel(
        id: 'cat-1',
        categoryKey: 'couple',
        name: '우리 커플',
        icon: 'simple_heart',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryEditModal(category: category),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2탭만 존재
      expect(find.text('기본 정보'), findsOneWidget);
      expect(find.text('스킨'), findsOneWidget);

      // 삭제된 탭/섹션 미존재
      expect(find.text('스티커'), findsNothing);
      expect(find.text('텍스트'), findsNothing);
      expect(find.text('배경'), findsNothing);
      expect(find.textContaining('Y2K'), findsNothing);

      // 스킨 탭 전환 → 카드 배경색, 배경 패턴 & 투명도, 사진 배경 존재 확인
      await tester.tap(find.text('스킨'));
      await tester.pumpAndSettle();

      expect(find.text('카드 배경색'), findsOneWidget);
      expect(find.textContaining('테두리'), findsNothing);

      final skinListScrollable = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('배경 패턴 & 투명도'),
        200,
        scrollable: skinListScrollable.first,
      );
      expect(find.text('배경 패턴 & 투명도'), findsOneWidget);

      // '도트' 패턴 선택 → 패턴 투명도 슬라이더 노출 확인
      await tester.tap(find.text('도트'));
      await tester.pumpAndSettle();

      expect(find.text('패턴 투명도'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('사진 배경'),
        200,
        scrollable: skinListScrollable.first,
      );
      expect(find.text('사진 배경'), findsOneWidget);
    });

    testWidgets('[프로필 & 설정] > [앱 환경설정]에서 전역 글꼴 및 글자 크기 설정이 동작한다', (tester) async {
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

      final fontTile = find.text('글꼴 및 글자 크기 설정');
      await tester.scrollUntilVisible(fontTile, 200);
      expect(fontTile, findsOneWidget);

      await tester.tap(fontTile);
      await tester.pumpAndSettle();

      // 글꼴 및 글자 크기 선택
      await tester.tap(find.text('프리텐다드'));
      await tester.tap(find.text('크게'));
      await tester.pumpAndSettle();

      final updated = container.read(appFontSettingsProvider);
      expect(updated.fontFamily, AppFontFamilyOption.pretendard);
      expect(updated.fontSize, AppFontSizeOption.large);
    });

    testWidgets('직접 설정하기 커스텀 모달이 파스텔 팔레트·아이콘 피커를 사용하고 캘린더 라벨 배경 설정이 분리되어 있다', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAddCategoryDashboardModal(context),
                  child: const Text('카테고리 추가 열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('카테고리 추가 열기'));
      await tester.pumpAndSettle();

      // STEP A → '직접 설정하기' 선택
      final customTile = find.text('직접 설정하기');
      await tester.ensureVisible(customTile);
      await tester.tap(customTile);
      await tester.pumpAndSettle();

      // STEP B 검증: 파스텔 팔레트 그리드, 전체 아이콘 버튼, 캘린더 라벨 배경 채우기 미노출
      expect(find.byType(ThemedColorPaletteGrid), findsOneWidget);
      expect(find.text('전체 아이콘'), findsOneWidget);
      expect(find.byType(HaruChipIconViewer), findsAtLeastNWidgets(1));
      expect(find.text('캘린더 라벨 배경 채우기'), findsNothing);
    });

    testWidgets('전 카테고리(예: 시험/반려동물/결혼) 상세 화면 상단 우측에 공통 [꾸미기] 버튼이 일괄 존재한다', (tester) async {
      for (final key in ['exam', 'pet', 'wedding', 'goal']) {
        final category = CategoryModel(
          id: 'cat-$key',
          categoryKey: key,
          name: '테스트 $key',
          icon: 'simple_star',
          createdAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: CategoryDetailScreen(category: category),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('category_decorate_button')),
          findsOneWidget,
          reason: 'Missing common decorate button for categoryKey=$key',
        );
      }
    });

    testWidgets('D-Day 카테고리 프리셋·필터에서 모임(group/meeting)이 영구 삭제되고 3번째 탭 칩 모임은 보존된다', (tester) async {
      // 1. 프리셋 시드에서 'meeting'/'group'/'모임' 및 'solo'/'솔로' 완전 제거 확인
      expect(
        kCategoryTypes.any(
          (c) =>
              c.key == 'meeting' ||
              c.key == 'group' ||
              c.labelKo == '모임' ||
              c.key == 'solo' ||
              c.labelKo == '솔로',
        ),
        isFalse,
      );
      expect(kCategoryTypes.length, 14);

      // 2. 레거시 'group'/'meeting' 데이터가 있어도 visible/hidden 리스트에서 제외
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(categoryListProvider.notifier).addCategory(
            categoryKey: 'group',
            name: '모임',
            emoji: '👥',
            colorHex: '#34D399',
          );
      container.read(categoryListProvider.notifier).addCategory(
            categoryKey: 'couple',
            name: '커플',
            emoji: 'simple_heart',
            colorHex: '#FF8DA1',
          );

      final visible = container.read(visibleCategoriesProvider);
      expect(visible.any((c) => c.categoryKey == 'group'), isFalse);
      expect(visible.any((c) => c.categoryKey == 'couple'), isTrue);

      // 3. 캘린더 카테고리 필터 바텀시트에 '모임' 미노출 확인
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showCalendarCategoryFilterSheet(context),
                  child: const Text('필터 열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('필터 열기'));
      await tester.pumpAndSettle();

      expect(find.text('모임'), findsNothing);
      expect(find.text('커플'), findsOneWidget);

      // 4. 3번째 하단 탭 '칩 모임' 정상 보존 확인
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: MainShellScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('칩 모임'), findsOneWidget);
    });
  });
}
