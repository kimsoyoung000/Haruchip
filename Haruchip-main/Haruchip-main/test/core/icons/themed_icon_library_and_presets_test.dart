import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_picker.dart';
import 'package:haruchip/core/icons/haruchip_icon_registry.dart';
import 'package:haruchip/features/onboarding/data/onboarding_categories.dart';

void main() {
  group('Default Pastel Category Icons & Themed Icon Library Tests', () {
    test(
      '1. 모든 기본 카테고리 대표 아이콘이 최신 심플 파스텔 에셋 키로 교체되었고, 모든 등록 SVG 파일이 디스크에 실존한다',
      () {
        for (final cat in kOnboardingCategories) {
          expect(
            cat.emoji.startsWith('simple_'),
            isTrue,
            reason: '${cat.key} should use a simple_* pastel SVG key, got ${cat.emoji}',
          );
          expect(
            HaruChipIconRegistry.isSafeRegistryKey(cat.emoji),
            isTrue,
            reason: '${cat.emoji} must be registered in HaruChipIconRegistry',
          );
        }

        // 모든 등록된 키의 SVG 파일이 실제 프로젝트 에셋 폴더에 존재하는지 검증
        for (final key in HaruChipIconRegistry.registeredKeys) {
          final assetPath = HaruChipIconRegistry.getAssetPath(key);
          expect(
            File(assetPath).existsSync(),
            isTrue,
            reason: 'Missing SVG asset file for key $key at $assetPath',
          );
        }
      },
    );

    test(
      '2. 테마별 아이콘 풀(군대/아기/반려동물/덕질/생일/뷰티/여행) 확장 및 레거시 이모지 자동 업그레이드 검증',
      () {
        final catalog = HaruChipIconRegistry.groupedCatalog(
          style: HaruChipIconStyle.simple,
        );

        expect(
          catalog['군대']!.map((e) => e.slug),
          containsAll(<String>[
            'beret_bear',
            'dog_tag',
            'letter',
            'combat_boot',
            'military_badge',
            'bugle',
          ]),
        );
        expect(
          catalog['아기']!.map((e) => e.slug),
          containsAll(<String>[
            'baby_face',
            'baby_bottle',
            'baby_bowl',
            'baby_rattle',
            'stroller',
            'pacifier',
            'baby_socks',
          ]),
        );
        expect(
          catalog['반려동물']!.map((e) => e.slug),
          containsAll(<String>[
            'dog',
            'cat',
            'hamster',
            'rabbit',
            'paw',
            'fish_bone',
            'dog_bone',
          ]),
        );
        expect(
          catalog['덕질/엔터']!.map((e) => e.slug),
          containsAll(<String>[
            'lightstick',
            'microphone',
            'ticket',
            'camera',
            'vinyl_lp',
            'movie_film',
            'tv_monitor',
            'heart_album',
          ]),
        );
        expect(
          catalog['생일/파티']!.map((e) => e.slug),
          containsAll(<String>[
            'cake',
            'candle',
            'gift',
            'party',
            'party_hat',
            'balloon',
          ]),
        );
        expect(
          catalog['뷰티/취미']!.map((e) => e.slug),
          containsAll(<String>[
            'lipstick',
            'makeup_brush',
            'perfume',
            'mirror',
            'shopping_bag',
            'ribbon',
            'palette',
            'gamepad',
          ]),
        );
        expect(
          catalog['여행/휴식']!.map((e) => e.slug),
          containsAll(<String>[
            'suitcase',
            'passport',
            'airplane',
            'palm_tree',
            'tent',
            'travel_map',
            'sunglasses',
            'car',
          ]),
        );

        // 레거시 이모지 업그레이드 & 사용자 커스텀 보존
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon('military', '🎖️'),
          'simple_beret_bear',
        );
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon('baby', '👶'),
          'simple_baby_face',
        );
        expect(
          HaruChipIconRegistry.upgradeLegacyCategoryIcon('pet', 'simple_cat'),
          'simple_cat',
        );
      },
    );

    testWidgets(
      '3. HaruChipIconPicker: 테마 필터 칩(전체/군대/아기 등) 필터링 및 선택 키 반환 검증',
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

        // 카테고리 필터 칩 노출 확인
        expect(find.byKey(const Key('icon_picker_filter_전체')), findsOneWidget);
        expect(find.byKey(const Key('icon_picker_filter_군대')), findsOneWidget);
        expect(find.byKey(const Key('icon_picker_filter_아기')), findsOneWidget);

        // '군대' 필터 칩 선택 -> 베레모 곰돌이 노출, 유모차 숨김
        await tester.tap(find.byKey(const Key('icon_picker_filter_군대')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('icon_picker_item_simple_beret_bear')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('icon_picker_item_simple_stroller')),
          findsNothing,
        );

        // 베레모 곰돌이 탭 -> 'simple_beret_bear' 반환
        await tester.tap(
          find.byKey(const Key('icon_picker_item_simple_beret_bear')),
        );
        await tester.pumpAndSettle();

        expect(pickedResult, 'simple_beret_bear');
      },
    );
  });
}
