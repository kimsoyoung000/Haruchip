import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/data/kpop_artist_presets.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/models/fandom_profile.dart';

void main() {
  group('KpopArtistDatabase Tests', () {
    test('contains major K-POP artist presets', () {
      expect(KpopArtistDatabase.presets.isNotEmpty, isTrue);

      final bts = KpopArtistDatabase.findById('bts');
      expect(bts, isNotNull);
      expect(bts!.groupName, contains('BTS'));
      expect(bts.fandomName, contains('ARMY'));
      expect(bts.members.length, 7);

      final newjeans = KpopArtistDatabase.findById('newjeans');
      expect(newjeans, isNotNull);
      expect(newjeans!.members.length, 5);

      final seventeen = KpopArtistDatabase.findById('seventeen');
      expect(seventeen, isNotNull);
      expect(seventeen!.members.length, 13);
    });

    test('searches presets by group name, fandom name, or member name', () {
      final results1 = KpopArtistDatabase.search('뉴진스');
      expect(results1.any((p) => p.id == 'newjeans'), isTrue);

      final results2 = KpopArtistDatabase.search('카리나');
      expect(results2.any((p) => p.id == 'aespa'), isTrue);

      final results3 = KpopArtistDatabase.search('캐럿');
      expect(results3.any((p) => p.id == 'seventeen'), isTrue);
    });
  });

  group('FandomProfile & BiasRank Tests', () {
    test('BiasRank priority sorting order', () {
      final members = [
        FandomMember(
          id: '1',
          name: '멤버 C',
          birthDate: DateTime(2000, 5, 1),
          biasRank: BiasRank.member,
        ),
        FandomMember(
          id: '2',
          name: '멤버 A',
          birthDate: DateTime(2000, 1, 1),
          biasRank: BiasRank.first,
        ),
        FandomMember(
          id: '3',
          name: '멤버 B',
          birthDate: DateTime(2000, 3, 1),
          biasRank: BiasRank.second,
        ),
        FandomMember(
          id: '4',
          name: '멤버 D',
          birthDate: DateTime(2000, 2, 1),
          biasRank: BiasRank.third,
        ),
      ];

      members.sort((a, b) {
        final rankComp = a.biasRank.priority.compareTo(b.biasRank.priority);
        if (rankComp != 0) return rankComp;
        return a.birthDate.compareTo(b.birthDate);
      });

      expect(members[0].biasRank, BiasRank.first);
      expect(members[1].biasRank, BiasRank.second);
      expect(members[2].biasRank, BiasRank.third);
      expect(members[3].biasRank, BiasRank.member);
    });

    test('FandomMember serialization and deserialization', () {
      final member = FandomMember(
        id: 'mem_1',
        name: '장원영',
        birthDate: DateTime(2004, 8, 31),
        position: '센터 / 보컬',
        emoji: '🐰',
        biasRank: BiasRank.first,
      );

      final json = member.toJson();
      final reconstructed = FandomMember.fromJson(json);

      expect(reconstructed.id, 'mem_1');
      expect(reconstructed.name, '장원영');
      expect(reconstructed.birthDate.year, 2004);
      expect(reconstructed.biasRank, BiasRank.first);
      expect(reconstructed.emoji, '🐰');
    });

    test('FandomTopkkuCard serialization and deserialization', () {
      final topkku = FandomTopkkuCard(
        customOverlayText: 'IVE 입덕 100일째 💖',
        musicTrack: const FandomMusicTrack(
          title: 'I AM',
          artist: 'IVE',
        ),
        decorations: const [
          StickerConfig(
            id: 'st_1',
            stickerType: '🎀',
            x: 50,
            y: 50,
          ),
        ],
      );

      final json = topkku.toJson();
      final reconstructed = FandomTopkkuCard.fromJson(json);

      expect(reconstructed.customOverlayText, 'IVE 입덕 100일째 💖');
      expect(reconstructed.musicTrack?.title, 'I AM');
      expect(reconstructed.decorations.length, 1);
      expect(reconstructed.decorations.first.stickerType, '🎀');
    });
  });

  group('CategoryModel showVisualCard Tests', () {
    test('defaults to true when showVisualCard metadata is omitted', () {
      final category = CategoryModel(
        id: 'cat_custom',
        categoryKey: 'custom',
        name: '나만의 기념일',
        createdAt: DateTime.now(),
      );

      expect(category.showVisualCard, isTrue);
    });

    test('reads showVisualCard false correctly from metadata', () {
      final category = CategoryModel(
        id: 'cat_custom',
        categoryKey: 'custom',
        name: '노션 스타일 D-Day',
        createdAt: DateTime.now(),
        metadata: {
          'showVisualCard': false,
        },
      );

      expect(category.showVisualCard, isFalse);
    });
  });
}
