import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/widgets/screens/widget_simulator_screen.dart';

void main() {
  group('Mobile Widget Simulator Tests', () {
    testWidgets('WidgetSimulatorScreen renders 3 widget tabs and guides correctly', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(categoryListProvider.notifier);
      notifier.addCategory(
        categoryKey: 'couple',
        name: '우리의 사랑',
        emoji: '💑',
        colorHex: '#FF5733',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WidgetSimulatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('모바일 위젯 시뮬레이터'), findsOneWidget);

      // Tabs verification
      expect(find.text('🔒 잠금화면 (1x1)'), findsOneWidget);
      expect(find.text('🖼️ 홈 2x2 (감성형)'), findsOneWidget);
      expect(find.text('📊 홈 4x2 (캘린더)'), findsOneWidget);

      // Guide banner
      expect(find.text('스마트폰 홈/잠금화면에 위젯 추가하는 법'), findsOneWidget);

      // Switch to 2x2 widget tab
      await tester.tap(find.text('🖼️ 홈 2x2 (감성형)'));
      await tester.pumpAndSettle();

      // Switch to 4x2 smart calendar tab
      await tester.tap(find.text('📊 홈 4x2 (캘린더)'));
      await tester.pumpAndSettle();
    });
  });
}
