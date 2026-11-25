import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/icons/haruchip_icon_picker.dart';
import 'package:haruchip/core/icons/haruchip_icon_registry.dart';
import 'package:haruchip/core/icons/haruchip_icon_viewer.dart';
import 'package:path/path.dart' as p;

void main() {
  group('HaruChipIconRegistry 보안 및 번들 무결성 검증', () {
    test('등록된 112종(+Fallback 2종)의 모든 에셋 파일이 디스크에 존재하고 안전한 SVG이다', () {
      final keys = HaruChipIconRegistry.registeredKeys;
      expect(keys.length, 114);

      for (final key in keys) {
        final assetPath = HaruChipIconRegistry.getAssetPath(key);
        expect(assetPath, startsWith('assets/icons/'));
        expect(assetPath, endsWith('.svg'));

        final file = File(assetPath);
        expect(file.existsSync(), isTrue, reason: 'Missing SVG asset: $assetPath');

        final content = file.readAsStringSync();
        expect(content, contains('<svg'));
        expect(content, contains('viewBox="0 0 24 24"'));
        expect(content.toLowerCase(), isNot(contains('<script')));
      }
    });

    test('4개 그룹에 Simple 40종, Line 40종이 정확히 매핑되어 있다', () {
      expect(
        HaruChipIconRegistry.groups,
        equals(['하트/기호', '기념일/음식', '동물/자연', '목표/시험']),
      );

      final simpleCatalog = HaruChipIconRegistry.groupedCatalog(
        style: HaruChipIconStyle.simple,
      );
      final lineCatalog = HaruChipIconRegistry.groupedCatalog(
        style: HaruChipIconStyle.line,
      );

      final simpleCount = simpleCatalog.values.fold<int>(0, (s, l) => s + l.length);
      final lineCount = lineCatalog.values.fold<int>(0, (s, l) => s + l.length);
      expect(simpleCount, 56);
      expect(lineCount, 56);
      expect(HaruChipIconRegistry.isSafeRegistryKey('simple_panda'), isTrue);
      expect(HaruChipIconRegistry.isSafeRegistryKey('line_fox'), isTrue);
      expect(HaruChipIconRegistry.isSafeRegistryKey('simple_hamster'), isTrue);
      expect(HaruChipIconRegistry.isSafeRegistryKey('simple_dolphin'), isTrue);
    });

    test('Path Traversal 및 미등록 키는 무조건 안전 Fallback으로 차단한다', () {
      const maliciousInputs = [
        '../pubspec.yaml',
        '../../etc/passwd',
        'asset:../../etc/passwd',
        'simple_../heart',
        'line_heart/../../secret',
        'simple_nonexistent_key',
        'assets/icons/simple/heart.svg',
        'simple_heart\x00.png',
        '',
      ];

      for (final input in maliciousInputs) {
        expect(
          HaruChipIconRegistry.getAssetPath(input),
          HaruChipIconRegistry.defaultFallbackAsset,
          reason: 'Failed to fallback for malicious/unknown input: $input',
        );
        expect(HaruChipIconRegistry.isSafeRegistryKey(input), isFalse);
      }
    });

    test('asset: 접두사가 붙은 정상 화이트리스트 키는 안전하게 허용한다', () {
      expect(HaruChipIconRegistry.isSafeRegistryKey('simple_heart'), isTrue);
      expect(HaruChipIconRegistry.isSafeRegistryKey('asset:line_cake'), isTrue);
      expect(
        HaruChipIconRegistry.getAssetPath('asset:line_cake'),
        'assets/icons/line/cake.svg',
      );
    });
  });

  group('HaruChipIconSandbox 경로 격리 검증', () {
    late Directory tempRoot;
    late Directory sandboxDir;
    late File insideFile;
    late File outsideFile;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('haruchip_sandbox_test_');
      sandboxDir = Directory(p.join(tempRoot.path, 'haruchip_icons'))..createSync();
      insideFile = File(p.join(sandboxDir.path, 'avatar.png'))..writeAsBytesSync([1, 2, 3]);
      outsideFile = File(p.join(tempRoot.path, 'secret.png'))..writeAsBytesSync([4, 5, 6]);
      HaruChipIconSandbox.debugOverrideSandboxRoot(sandboxDir.path);
    });

    tearDown(() {
      HaruChipIconSandbox.debugOverrideSandboxRoot(null);
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('샌드박스 내부의 허용 확장자 파일만 통과한다', () {
      final resolved = HaruChipIconSandbox.resolveSafeSandboxFileSync(
        'file:${insideFile.path}',
      );
      expect(resolved, isNotNull);
      expect(p.canonicalize(resolved!.path), p.canonicalize(insideFile.path));
    });

    test('샌드박스 외부 경로 및 .. 경로 조작은 차단된다', () {
      expect(
        HaruChipIconSandbox.resolveSafeSandboxFileSync('file:${outsideFile.path}'),
        isNull,
      );
      expect(
        HaruChipIconSandbox.resolveSafeSandboxFileSync(
          'file:${sandboxDir.path}/../secret.png',
        ),
        isNull,
      );
    });
  });

  group('HaruChipIconViewer & HaruChipIconPicker 위젯 검증', () {
    testWidgets('화이트리스트 키는 SvgPicture, 기존 이모지는 Text로 하위 호환 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HaruChipIconViewer(iconKey: 'simple_heart', size: 24),
                HaruChipIconViewer(iconKey: 'asset:../../etc/passwd', size: 24),
                HaruChipIconViewer(iconKey: '🎂', size: 24),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsNWidgets(2));
      expect(find.text('🎂'), findsOneWidget);
      expect(find.text('asset:../../etc/passwd'), findsNothing);
    });

    testWidgets('HaruChipIconPicker는 [아이콘]/[사진] 탭과 4개 그룹을 표시하고 선택 키를 반환한다', (tester) async {
      String? pickedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
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

      expect(find.text('아이콘'), findsOneWidget);
      expect(find.text('사진'), findsOneWidget);
      expect(find.text('심플 파스텔'), findsOneWidget);
      expect(find.text('미니멀 라인'), findsOneWidget);
      expect(find.text('하트/기호'), findsOneWidget);

      // 라인 스타일로 전환 후 첫 번째 아이콘(하트) 탭
      await tester.tap(find.text('미니멀 라인'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('하트'));
      await tester.pumpAndSettle();

      expect(pickedResult, 'line_heart');
    });
  });
}
