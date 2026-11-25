import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/providers/calendar_display_settings_provider.dart';
import 'package:haruchip/features/calendar/providers/calendar_provider.dart';
import 'package:haruchip/features/calendar/screens/calendar_screen.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/settings/screens/profile_settings_screen.dart';

void main() {
  testWidgets('칩 캘린더 미니멀 플랫 헤더 검증 (큰 월 숫자 + 세그먼트 + 검색/필터 아이콘, 톱니바퀴/일·월 시작 제거)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalendarScreen())),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(find.text('${now.month}'), findsWidgets);
    expect(find.text('월간'), findsOneWidget);
    expect(find.text('주간'), findsOneWidget);
    expect(find.text('목록'), findsOneWidget);
    expect(find.byKey(const Key('calendar_search_button')), findsOneWidget);
    expect(find.byKey(const Key('calendar_category_filter_button')), findsOneWidget);

    // 제거 대상 확인
    expect(find.text('일 시작'), findsNothing);
    expect(find.text('월 시작'), findsNothing);
    expect(find.text('스마트 캘린더'), findsNothing);
    expect(find.text('연동 설정'), findsNothing);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byIcon(Icons.notifications_rounded), findsNothing);
  });

  testWidgets('알림 센터(종 아이콘)는 1번째 탭(칩 데이)에만 단독 노출되고 2/3/4번째 탭에서는 숨김',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(calendarDisplaySettingsProvider.notifier).markOnboardingSeen();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MainShellScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

    for (final tab in ['칩 캘린더', '칩 모임', '프로필 & 설정']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_rounded), findsNothing);
    }

    await tester.tap(find.text('칩 데이'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
  });

  testWidgets('카테고리 필터 모달: 원형 체크박스 다중 선택 + 우측 (i) 아이콘으로 테마 팔레트 색상 변경',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final today = DateTime.now();
    container.read(planListProvider.notifier).addItem(
          PlanItem(id: 'f-1', title: '커플 데이트', date: today, categoryKey: 'couple'),
        );
    container.read(planListProvider.notifier).addItem(
          PlanItem(id: 'f-2', title: '자격증 시험', date: today, categoryKey: 'exam'),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 상단 우측 [카테고리 필터] 아이콘 탭 -> [카테고리] 모달 오픈
    await tester.tap(find.byKey(const Key('calendar_category_filter_button')));
    await tester.pumpAndSettle();
    expect(find.text('카테고리'), findsOneWidget);

    // '커플' 체크 해제 -> 커플 일정만 숨김되고 시험 일정은 유지됨
    await tester.tap(find.text('커플'));
    await tester.pumpAndSettle();
    expect(container.read(eventsForDateProvider(today)).map((e) => e.id),
        isNot(contains('f-1')));
    expect(container.read(eventsForDateProvider(today)).map((e) => e.id),
        contains('f-2'));

    // 우측 (i) 아이콘 탭 -> 테마별 파스텔 컬러 팔레트 오픈
    await tester.tap(find.byKey(const Key('filter_category_info_couple')));
    await tester.pumpAndSettle();
    for (final label in ['기본', '단순', '화려한', '파스텔', '시원한', '세련된', '사용자 지정']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    // 전체 표시 버튼으로 복구
    await tester.tap(find.text('전체 표시'));
    await tester.pumpAndSettle();
    expect(container.read(calendarSelectedCategoriesProvider), isEmpty);
    expect(container.read(eventsForDateProvider(today)).map((e) => e.id),
        containsAll(['f-1', 'f-2']));
  });

  testWidgets('일정 검색 엔진: 키워드로 미래 일정 검색 후 결과 탭 시 해당 월/일로 즉시 포커스 이동',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final targetDate = DateTime(2027, 3, 14);
    container.read(planListProvider.notifier).addItem(
          PlanItem(
            id: 'search-target-1',
            title: '경주 봄꽃 여행',
            date: targetDate,
            categoryKey: 'travel',
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 돋보기 아이콘 탭
    await tester.tap(find.byKey(const Key('calendar_search_button')));
    await tester.pumpAndSettle();

    // 키워드 입력
    await tester.enterText(find.byType(TextField), '경주 봄꽃');
    await tester.pumpAndSettle();
    expect(find.text('경주 봄꽃 여행'), findsOneWidget);

    // 결과 탭 -> 2027년 3월 14일로 캘린더 포커스 이동
    await tester.tap(find.text('경주 봄꽃 여행'));
    await tester.pumpAndSettle();

    expect(container.read(selectedMonthProvider), DateTime(2027, 3, 1));
    expect(container.read(selectedDateProvider), DateTime(2027, 3, 14));
  });

  testWidgets('프로필 & 설정 > 앱 환경설정 내 [캘린더 표시 설정] 및 [캘린더 시작 요일(일/월)] 제어',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final mondayBtn = find.text('월요일부터 시작');
    await tester.scrollUntilVisible(mondayBtn, 300);
    expect(find.text('캘린더 표시 설정'), findsOneWidget);
    expect(find.text('캘린더 시작 요일'), findsOneWidget);

    expect(container.read(calendarDisplaySettingsProvider).startOnMonday, isFalse);
    await tester.tap(mondayBtn);
    await tester.pumpAndSettle();
    expect(container.read(calendarDisplaySettingsProvider).startOnMonday, isTrue);

    // 표시 설정 바텀시트 호출 확인 (세로 스크롤/테마 색상 제거, 글꼴 크기만 표시)
    await tester.tap(find.text('캘린더 표시 설정'));
    await tester.pumpAndSettle();
    expect(find.text('글꼴 크기'), findsWidgets);
    expect(find.text('세로 스크롤'), findsNothing);
    expect(find.text('테마 색상'), findsNothing);
  });

  testWidgets('칩 캘린더 최초 진입 시 표시 설정 바텀시트 1회 안내', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainShellScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('칩 캘린더'));
    await tester.pumpAndSettle();
    expect(find.text('글꼴 크기'), findsWidgets);

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('칩 데이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('칩 캘린더'));
    await tester.pumpAndSettle();
    expect(find.text('글꼴 크기'), findsNothing);
  });
}
