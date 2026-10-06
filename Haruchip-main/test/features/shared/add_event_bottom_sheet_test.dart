import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/custom_tags_provider.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

void main() {
  group('CategoryCustomTagsNotifier Tests', () {
    test('adds and removes custom tags per category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(categoryCustomTagsProvider.notifier);

      // Add custom tag for pet
      notifier.addCustomTag('pet', '영양제급여');
      notifier.addCustomTag('pet', '발톱정리');

      var state = container.read(categoryCustomTagsProvider);
      expect(state['pet'], contains('영양제급여'));
      expect(state['pet'], contains('발톱정리'));

      // Remove custom tag
      notifier.removeCustomTag('pet', '영양제급여');
      state = container.read(categoryCustomTagsProvider);
      expect(state['pet'], isNot(contains('영양제급여')));
      expect(state['pet'], contains('발톱정리'));
    });
  });

  group('AddEventBottomSheet Widget Tests', () {
    testWidgets('renders single unified modal without top double segment tab', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top segment tabs [이벤트], [미리 알림] must not exist
      expect(find.text('이벤트'), findsNothing);
      expect(find.text('내 일정 일정 추가'), findsOneWidget);

      // Pre-event reminder row exists in the unified form
      expect(find.text('미리알림 (사전 알림)'), findsOneWidget);
    });

    testWidgets('quick tag cleanly replaces title text and updates highlight', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'pet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap '산책' tag
      expect(find.text('산책'), findsOneWidget);
      await tester.tap(find.text('산책'));
      await tester.pumpAndSettle();

      // Check text field has '산책'
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '산책');

      // Tap another tag '미용' - should replace, not append
      expect(find.text('미용'), findsOneWidget);
      await tester.tap(find.text('미용'));
      await tester.pumpAndSettle();

      expect(textField.controller?.text, '미용');
    });

    testWidgets('opens reminder bottom sheet and selects option without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reminder row
      final reminderTile = find.text('미리알림 (사전 알림)');
      expect(reminderTile, findsOneWidget);
      await tester.tap(reminderTile);
      await tester.pumpAndSettle();

      // Verify reminder modal header and options are displayed
      expect(find.text('🔔 미리알림 시간 선택'), findsOneWidget);
      expect(find.text('10분 전'), findsOneWidget);
      expect(find.text('1일 전 오전 9시'), findsOneWidget);

      // Tap '10분 전'
      await tester.tap(find.text('10분 전'));
      await tester.pumpAndSettle();

      // Reminder modal closed and 10분 전 badge is shown
      expect(find.text('🔔 미리알림 시간 선택'), findsNothing);
      expect(find.text('10분 전'), findsOneWidget);
    });
  });
}
