import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/onboarding/data/onboarding_categories.dart';
import 'package:haruchip/features/categories/models/solo_profile.dart';
import 'package:haruchip/features/categories/widgets/solo_top_card_widget.dart';

void main() {
  group('Category Selection Lists Tests', () {
    test('kOnboardingCategories contains baby and does not contain group', () {
      final keys = kOnboardingCategories.map((c) => c.key).toList();

      expect(keys.contains('baby'), isTrue);
      expect(keys.contains('solo'), isTrue);
      expect(keys.contains('couple'), isTrue);
      expect(keys.contains('pet'), isTrue);
      expect(keys.contains('fandom'), isTrue);
      expect(keys.contains('exam'), isTrue);
      expect(keys.contains('military'), isTrue);

      // Legacy 'group' D-Day category must be removed from category selection to avoid confusion with Meeting platform
      expect(keys.contains('group'), isFalse);

      final babyCat = kOnboardingCategories.firstWhere((c) => c.key == 'baby');
      expect(babyCat.labelKo, '아기');
      expect(babyCat.emoji, '👶');
    });
  });

  group('SoloProfile & SoloMode Tests', () {
    test('SoloMode properties and labels are correct', () {
      expect(SoloMode.selfCare.name, 'selfCare');
      expect(SoloMode.selfCare.labelKo, '나를 위한 시간');
      expect(SoloMode.selfCare.cardTitlePrefix, '나에게 집중한 지');
      expect(SoloMode.selfCare.emoji, '🌱');

      expect(SoloMode.crush.name, 'crush');
      expect(SoloMode.crush.labelKo, '마음 진행 중');
      expect(SoloMode.crush.cardTitlePrefix, '설레기 시작한 지');
      expect(SoloMode.crush.emoji, '💌');
    });

    test('SoloProfile day calculations and JSON serialization', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tenDaysAgo = today.subtract(const Duration(days: 9));

      final profile = SoloProfile(
        mode: SoloMode.selfCare,
        selfCareStartDate: tenDaysAgo,
        crushStartDate: today.subtract(const Duration(days: 2)),
        showTopCard: true,
        tags: const ['나홀로여행', '바디프로필', '취미/운동'],
      );

      expect(profile.daysCount(), 10);
      expect(profile.activeStartDate, tenDaysAgo);

      final json = profile.toJson();
      expect(json['mode'], 'selfCare');
      expect(json['showTopCard'], true);
      expect(json['tags'], ['나홀로여행', '바디프로필', '취미/운동']);

      final restored = SoloProfile.fromJson(json);
      expect(restored.mode, SoloMode.selfCare);
      expect(restored.daysCount(), 10);
      expect(restored.showTopCard, isTrue);
      expect(restored.tags.length, 3);
    });

    test('SoloProfile crush mode switches activeStartDate and day count', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final fiveDaysAgo = today.subtract(const Duration(days: 4));

      final profile = SoloProfile(
        mode: SoloMode.crush,
        selfCareStartDate: today.subtract(const Duration(days: 30)),
        crushStartDate: fiveDaysAgo,
        showTopCard: true,
      );

      expect(profile.daysCount(), 5);
      expect(profile.activeStartDate, fiveDaysAgo);
    });
  });

  group('SoloTopCardWidget UI Tests', () {
    testWidgets('renders segments, card title, date picker and quick tags', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      SoloProfile currentProfile = SoloProfile(
        mode: SoloMode.selfCare,
        selfCareStartDate: today.subtract(const Duration(days: 14)),
        crushStartDate: today,
        showTopCard: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: SoloTopCardWidget(
                    profile: currentProfile,
                    onProfileChanged: (updated) {
                      setState(() {
                        currentProfile = updated;
                      });
                    },
                    onSelectTag: (tag) {},
                    onAddNewTag: (tag) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify mode segments
      expect(find.text('나를 위한 시간'), findsWidgets);
      expect(find.text('마음 진행 중'), findsOneWidget);

      // Verify card title "나에게 집중한 지 15일째"
      expect(find.text('나에게 집중한 지 15일째'), findsOneWidget);

      // Verify quick tags
      expect(find.text('나홀로여행'), findsOneWidget);
      expect(find.text('바디프로필'), findsOneWidget);
      expect(find.text('취미/운동'), findsOneWidget);
      expect(find.text('새출발'), findsOneWidget);
      expect(find.text('데이트/소개팅'), findsOneWidget);
      expect(find.text('+ 직접 추가'), findsOneWidget);

      // Tap on crush mode segment
      await tester.tap(find.text('마음 진행 중'));
      await tester.pumpAndSettle();

      // Verify switched mode title "설레기 시작한 지 1일째"
      expect(find.text('설레기 시작한 지 1일째'), findsOneWidget);

      // Tap on '카드 숨기기'
      await tester.tap(find.text('카드 숨기기'));
      await tester.pumpAndSettle();

      // Card is hidden, unhide bar appears
      expect(find.text('설레기 시작한 지 1일째 (상단 카드 보기)'), findsOneWidget);
    });
  });
}
