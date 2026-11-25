import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_viewer.dart';
import 'package:haruchip/core/utils/safe_image_widget.dart';
import 'package:haruchip/design_system/colors.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/screens/couple_category_detail_screen.dart';
import 'package:haruchip/features/couple/models/couple_relationship.dart';
import 'package:haruchip/features/couple/providers/couple_provider.dart';
import 'package:haruchip/features/couple/widgets/couple_relationship_setup_sheet.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';

class _FixedCoupleNotifier extends CoupleNotifier {
  _FixedCoupleNotifier(this._initial);
  final CoupleRelationship _initial;

  @override
  CoupleRelationship build() => _initial;
}

// 1x1 transparent PNG bytes
final Uint8List _k1x1PngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  group('Couple UX Polish & Web-Safe Image Tests', () {
    testWidgets(
      '1 & 2. Uninitialized setup sheet opens at Today, goes straight to wheel picker, and uses HaruChip yellow CTA without circle-plus icon',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayStr =
            '${today.year}.${today.month.toString().padLeft(2, '0')}.${today.day.toString().padLeft(2, '0')}';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coupleProvider.overrideWith(
                () => _FixedCoupleNotifier(
                  CoupleRelationship(
                    partnerName: '용이',
                    partnerIcon: '❤️',
                    startDate: DateTime(2024, 5, 14),
                    reunions: const [],
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => showCoupleRelationshipSetupSheet(
                      context,
                      ref,
                      isInitialized: false,
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

        // Uninitialized -> Today's date shown instead of 2024.05.14
        expect(find.text(todayStr), findsOneWidget);
        expect(find.text('2024.05.14'), findsNothing);

        // "+ 재회 추가" text button without circle-plus icon
        expect(find.text('+ 재회 추가'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsNothing);

        // HaruChip yellow CTA button
        final submitBtn = tester.widget<ElevatedButton>(
          find.byKey(const Key('couple_setup_submit_button')),
        );
        expect(
          submitBtn.style?.backgroundColor?.resolve(<WidgetState>{}),
          AppColors.chipYellowBg,
        );

        // Tap start date -> immediately opens inline CupertinoPicker wheel (no intermediate step)
        await tester.tap(find.byKey(const Key('couple_start_date_field')));
        await tester.pumpAndSettle();

        expect(find.byType(CupertinoPicker), findsNWidgets(3));
        expect(find.text('시간대: 서울 >'), findsNothing);
      },
    );

    testWidgets(
      '3 & 5. CoupleCategoryDetailScreen shows bold N일 hero card, hides N일째 리스트/섹션 관리/재회 제외, and opens setup sheet on hero card tap',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final startDate = today.subtract(const Duration(days: 865));
        final startStr =
            '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')} ~';

        final category = CategoryModel(
          id: 'cat_couple',
          categoryKey: 'couple',
          name: '용이랑 ❤️',
          icon: 'simple_heart',
          createdAt: today,
          metadata: const {'isInitialized': true},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coupleProvider.overrideWith(
                () => _FixedCoupleNotifier(
                  CoupleRelationship(
                    partnerName: '용이',
                    partnerIcon: '❤️',
                    startDate: startDate,
                    reunions: const [],
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: CoupleCategoryDetailScreen(category: category),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hero card text: "866일" & "YYYY.MM.DD ~"
        expect(find.text('866일'), findsOneWidget);
        expect(find.text(startStr), findsOneWidget);

        // Hidden elements: no "사랑한 지", no "재회 기간 제외", no "섹션 관리", no "N일째 리스트"
        expect(find.textContaining('사랑한 지'), findsNothing);
        expect(find.textContaining('재회 기간 제외'), findsNothing);
        expect(find.text('섹션 관리'), findsNothing);
        expect(find.text('N일째 리스트'), findsNothing);

        // Only "세부 D-Day 리스트" remains
        expect(find.text('세부 D-Day 리스트'), findsOneWidget);

        // Tap anywhere on hero card -> opens setup sheet
        await tester.tap(find.byKey(const Key('couple_hero_summary_card')));
        await tester.pumpAndSettle();
        expect(find.text('만난 날 및 재회 설정'), findsOneWidget);
      },
    );

    testWidgets(
      '4. buildUserImage, resolveSafeImageProvider & HaruChipIconViewer safely render Uint8List and base64 Data URI',
      (tester) async {
        final dataUri =
            'data:image/png;base64,${base64Encode(_k1x1PngBytes)}';

        expect(resolveSafeImageProvider(_k1x1PngBytes), isA<MemoryImage>());
        expect(resolveSafeImageProvider(dataUri), isA<MemoryImage>());
        expect(resolveSafeImageProvider(''), isNull);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: buildUserImage(_k1x1PngBytes),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: buildUserImage(dataUri),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: buildUserImage(null),
                  ),
                  HaruChipIconViewer(
                    iconKey: dataUri,
                    size: 32,
                    circular: true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsNWidgets(3));
        expect(find.byType(DefaultChipAvatar), findsOneWidget);
      },
    );

    testWidgets(
      '6. Main dashboard couple card automatically displays upcoming 1000일 / 주년 D-Day in white bar',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        // Set startDate so 1000일 is 20 days from today!
        final startDate = today.subtract(const Duration(days: 980));

        final category = CategoryModel(
          id: 'cat_couple',
          categoryKey: 'couple',
          name: '용이랑 ❤️',
          icon: 'simple_heart',
          createdAt: today,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coupleProvider.overrideWith(
                () => _FixedCoupleNotifier(
                  CoupleRelationship(
                    partnerName: '용이',
                    partnerIcon: '❤️',
                    startDate: startDate,
                    reunions: const [],
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    child: CategorySummaryDashboardCard(
                      category: category,
                      countUpItems: const [],
                      countDownItems: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1000일'), findsOneWidget);
        expect(find.text('D-20'), findsOneWidget);
      },
    );
  });
}
