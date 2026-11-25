import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_viewer.dart';
import 'package:haruchip/design_system/colors.dart';
import 'package:haruchip/features/calendar/models/calendar_event.dart';
import 'package:haruchip/features/calendar/screens/calendar_screen.dart';
import 'package:haruchip/features/calendar/widgets/create_room_dialog.dart';
import 'package:haruchip/features/calendar/widgets/month_grid.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

void main() {
  group('캘린더 디자인 고도화 & 파스텔 자동 매핑 검증', () {
    test('resolveCalendarLabelPastelBg가 계열별 파스텔 배경색을 정확히 매핑한다', () {
      expect(
        resolveCalendarLabelPastelBg(const Color(0xFF29ABE2)), // 블루
        const Color(0xFFE3F2FD),
      );
      expect(
        resolveCalendarLabelPastelBg(const Color(0xFFFF85A2)), // 핑크
        const Color(0xFFFCE4EC),
      );
      expect(
        resolveCalendarLabelPastelBg(const Color(0xFFFADB14)), // 옐로우
        const Color(0xFFFFF8E1),
      );
      expect(
        resolveCalendarLabelPastelBg(const Color(0xFF1F2429)), // 블랙/그레이
        const Color(0xFFF5F5F5),
      );
    });

    testWidgets('선택일은 웜 파스텔 옐로우(#FFE699) + 딥 브라운(#3A2E1A)으로, 다일 일정은 단일 연속 바로 렌더링된다', (tester) async {
      final focused = DateTime(2026, 5, 1);
      final selected = DateTime(2026, 5, 7); // 목요일
      final multiDayTrip = CalendarEvent(
        id: 'trip-jeju',
        date: DateTime(2026, 5, 7),
        endDate: DateTime(2026, 5, 9), // 목~토 2박 3일
        title: '제주 여행',
        source: 'personal',
        colorHex: '#29ABE2',
        categoryKey: 'travel',
        fillLabelBackground: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 440,
              child: MonthGrid(
                focusedMonth: focused,
                selectedDate: selected,
                allEvents: [multiDayTrip],
                hasEventOnDate: (d) =>
                    !d.isBefore(DateTime(2026, 5, 7)) &&
                    !d.isAfter(DateTime(2026, 5, 9)),
                onDateSelected: (_) {},
                onPreviousMonth: () {},
                onNextMonth: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 다일 일정이 3일치로 쪼개지지 않고 단일 가로 연속 라벨 바(1개 텍스트)로 렌더링됨
      expect(find.text('제주 여행'), findsOneWidget);

      // 선택일(#FFE699) 배경 Container 확인
      final selectedBgFound = tester.widgetList<Container>(find.byType(Container)).any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == MonthGrid.kSelectedCellBg;
      });
      expect(selectedBgFound, isTrue);

      // 선택일 숫자 '7'의 텍스트 색상이 딥 브라운(#3A2E1A)인지 확인
      final day7Text = tester.widget<Text>(find.text('7'));
      expect(day7Text.style?.color, MonthGrid.kSelectedText);
    });

    testWidgets('하단 일정 카드 탭 시 일정 수정 모달(삭제 버튼 포함)이 열린다', (tester) async {
      final today = DateTime.now();
      final testItem = PlanItem(
        id: 'plan-edit-1',
        categoryKey: 'plan',
        title: '밥을 먹을 것',
        date: DateTime(today.year, today.month, today.day),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(planListProvider.notifier).addItem(testItem);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 하단 일정 리스트에 '밥을 먹을 것' 노출 확인 (그리드와 하단 둘 다 있을 수 있으므로 last 탭)
      final eventFinder = find.text('밥을 먹을 것');
      expect(eventFinder, findsAtLeastNWidgets(1));

      await tester.ensureVisible(eventFinder.last);
      await tester.tap(eventFinder.last);
      await tester.pumpAndSettle();

      // 수정 모달 열림 확인
      expect(find.text('완료'), findsOneWidget);
      expect(find.textContaining('일정 수정'), findsOneWidget);
    });

    testWidgets('카테고리 선택 바텀시트에서 simple_star 키가 텍스트로 노출되지 않고 HaruChipIconViewer로 렌더링된다', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(categoryListProvider.notifier).addCategory(
            categoryKey: 'hobby',
            name: '취미',
            emoji: 'simple_star',
            colorHex: '#29ABE2',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAddEventBottomSheet(
                    context,
                    categoryKey: 'hobby',
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // '카테고리' 행 탭 → 카테고리 선택 바텀시트 열기
      await tester.ensureVisible(find.text('카테고리'));
      await tester.tap(find.text('카테고리'));
      await tester.pumpAndSettle();

      // raw key 문자열('simple_star')이 텍스트로 절대 노출되지 않아야 함
      expect(find.textContaining('simple_star'), findsNothing);
      expect(find.byType(HaruChipIconViewer), findsAtLeastNWidgets(1));

      // '+ 새 카테고리 추가' 탭 → 순백 화이트 바텀시트 + 라벨 배경 채우기 토글 확인
      await tester.tap(find.text('+ 새 카테고리 추가'));
      await tester.pumpAndSettle();

      expect(find.text('새 카테고리 추가'), findsOneWidget);
      expect(find.text('캘린더 라벨 배경 채우기'), findsOneWidget);
      expect(find.byType(HaruChipIconViewer), findsAtLeastNWidgets(1));
    });

    testWidgets('캘린더 연/월 헤더 탭 시 인라인 휠 피커(CupertinoPicker)가 열리고 스크롤바가 숨겨진다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ScrollConfiguration의 scrollbars가 false인지 확인
      final scrollConfigs = tester.widgetList<ScrollConfiguration>(
        find.byType(ScrollConfiguration),
      );
      expect(
        scrollConfigs.any((sc) => sc.behavior.buildScrollbar(
                  tester.element(find.byType(CalendarScreen)),
                  const SizedBox(),
                  ScrollableDetails.vertical(),
                ) is SizedBox),
        isTrue,
      );

      // 상단 연/월 영역 탭 → CupertinoPicker 2개(연도/월) 열림
      await tester.tap(find.byKey(const Key('calendar_year_month_picker_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoPicker), findsNWidgets(2));
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('새 모임 만들기 모달이 단정한 타이틀·플레이스홀더·확장 분류·직접 입력·하루칩 옐로우 버튼을 적용한다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showCreateRoomDialog(context),
                  child: const Text('모임 만들기 열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('모임 만들기 열기'));
      await tester.pumpAndSettle();

      // ✨ 제거된 단정한 타이틀 & 새 플레이스홀더
      expect(find.text('새 모임 만들기'), findsOneWidget);
      expect(find.textContaining('✨'), findsNothing);
      expect(find.text('모임명을 입력해 주세요'), findsOneWidget);

      // 확장 분류 칩 확인
      expect(find.text('동창/동문'), findsOneWidget);
      expect(find.text('운동/스포츠'), findsOneWidget);
      expect(find.text('친목/정기모임'), findsOneWidget);
      expect(find.text('+ 직접 입력'), findsOneWidget);

      // '+ 직접 입력' 탭 시 커스텀 분류 입력창 노출
      await tester.tap(find.text('+ 직접 입력'));
      await tester.pumpAndSettle();
      expect(find.textContaining('원하는 모임 분류명을 입력해 주세요'), findsOneWidget);

      // '모임 방 개설하기' 버튼이 하루칩 웜 파스텔 옐로우(#FFE699)인지 확인
      final createBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '모임 방 개설하기'),
      );
      expect(
        createBtn.style?.backgroundColor?.resolve({}),
        AppColors.chipYellowBg,
      );
      expect(
        createBtn.style?.foregroundColor?.resolve({}),
        AppColors.chipYellowText,
      );
    });
  });
}
