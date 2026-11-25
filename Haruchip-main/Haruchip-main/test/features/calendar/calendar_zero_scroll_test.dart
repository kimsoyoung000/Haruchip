import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/screens/calendar_screen.dart';

void main() {
  Future<void> verifyZeroScrollMonthCalendar(
    WidgetTester tester,
    Size viewportSize,
  ) async {
    await tester.binding.setSurfaceSize(viewportSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    final firstDayFinder = find.text('1');
    final lastDayFinder = find.text('$lastDay');
    expect(firstDayFinder, findsWidgets);
    expect(lastDayFinder, findsWidgets);

    final firstRect = tester.getRect(firstDayFinder.first);
    final lastRect = tester.getRect(lastDayFinder.last);

    expect(firstRect.top, greaterThanOrEqualTo(0));
    expect(lastRect.bottom, lessThanOrEqualTo(viewportSize.height),
        reason: 'Last day ($lastDay) must be visible without scrolling at $viewportSize');
  }

  testWidgets('칩 캘린더: 컴팩트 모바일(360x640)에서 스크롤 없이 1일~말일 전체 표시', (tester) async {
    await verifyZeroScrollMonthCalendar(tester, const Size(360, 640));
  });

  testWidgets('칩 캘린더: 표준 모바일(390x844)에서 스크롤 없이 1일~말일 전체 표시', (tester) async {
    await verifyZeroScrollMonthCalendar(tester, const Size(390, 844));
  });

  testWidgets('칩 캘린더: 가로가 넓고 세로가 짧은 창(1024x520)에서도 스크롤 없이 1일~말일 전체 표시', (tester) async {
    await verifyZeroScrollMonthCalendar(tester, const Size(1024, 520));
  });
}
