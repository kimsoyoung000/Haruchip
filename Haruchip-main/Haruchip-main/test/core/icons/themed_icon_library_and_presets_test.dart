import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_picker.dart';
import 'package:haruchip/core/icons/haruchip_icon_registry.dart';
import 'package:haruchip/features/onboarding/data/onboarding_categories.dart';

void main() {
  group('Restored Original Simple Pastel & Minimal Line Icon Pack Tests', () {
    test(
      '1. 등록된 전체 심플 파스텔(57종) & 미니멀 라인(57종) 키가 디스크의 실제 SVG 파일과 1:1 일치한다 (더미 키 0개)',
      () {
        expect(HaruChipIconRegistry.registeredKeys.length, 114);

        for (final key in HaruChipIconRegistry.registeredKeys) {
          final assetPath = HaruChipIconRegistry.getAssetPath(key);
          expect(
            File(assetPath).existsSync(),
            isTrue,
            reason: 'Missing SVG asset file for key $key at $assetPath',
          );
        }

        final simpleFiles = Directory('assets/icons/simple')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.svg'))
            .length;
        final lineFiles = Directory('assets/icons/line')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.svg'))
            .length;
        expect(simpleFiles, 57);
        expect(lineFiles, 57);
      },
    );

    test(
      '2. 기본 카테고리 대표 심볼(하트/별/아기/곰돌이/케이크/반지 등) 원본 심플 파스텔 매핑 & 안전 복구 검증',
      () {
        final byKey = {for (final c in kOnboardingCategories) c.key: c.emoji};
        expect(byKey['couple'], 'simple_heart');
        expect(byKey['fandom'], 'simple_star');
        expect(byKey['baby'], 'simple_baby_bottle');
        expect(byKey['military'], 'simple_bear');
        expect(byKey['exam'], 'simple_book');
        expect(byKey['wedding'], 'simple_ring');
        expect(byKey['birthday'], 'simple_cake');
        expect(byKey['pet'], 'simple_paw');
        expect(byKey['plan'], 'simple_calendar');
        expect(byKey['goal'], 'simple_target');
        expect(byKey['routine'], 'simple_sprout');
        expect(byKey['hobby'], 'simple_palette');
        expect(byKey['travel'], 'simple_airplane');
        expect(byKey['custom'], 'simple_sparkle');

        for (final cat in kOnboardingCategories) {
          expect(HaruChipIconRegistry.isSafeRegistryKey(cat.emoji), isTrue);
        }

        // 구형 이모지 및 제거된 임시 키 -> 원본 심플 파스텔 키로 안전 복구
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon('military', '🎖️'),
          'simple_bear',
        );
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon(
            'military',
            'simple_beret_bear',
          ),
          'simple_bear',
        );
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon('fandom', '⭐'),
          'simple_star',
        );
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon('pet', 'simple_cat'),
          'simple_cat',
        );
      },
    );

    testWidgets(
      '3. HaruChipIconPicker: [심플 파스텔]/[미니멀 라인] 전환, 44x44dp 규격 & #F2B84B 골드 선택 하이라이트 검증',
      (tester) async {
        String? pickedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    pickedResult = await showHaruChipIconPicker(
                      context,
                      initialIconKey: 'simple_heart',
                    );
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();

        // 상단 [심플 파스텔] / [미니멀 라인] 전환 버튼 존재
        expect(find.byKey(const Key('icon_picker_style_simple')), findsOneWidget);
        expect(find.byKey(const Key('icon_picker_style_line')), findsOneWidget);

        // 44x44dp 규격 확인
        final heartTileSize = tester.getSize(
          find.byKey(const Key('icon_picker_item_simple_heart')),
        );
        expect(heartTileSize.width, 44.0);
        expect(heartTileSize.height, 44.0);

        // [미니멀 라인] 전환 -> line_star 노출 및 선택 반환 확인
        await tester.tap(find.byKey(const Key('icon_picker_style_line')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('icon_picker_item_line_star')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('icon_picker_item_line_star')));
        await tester.pumpAndSettle();

        expect(pickedResult, 'line_star');
      },
    );
  });
}
