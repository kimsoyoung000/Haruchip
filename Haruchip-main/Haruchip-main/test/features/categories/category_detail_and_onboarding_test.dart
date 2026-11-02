import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/birthday_profile.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/models/pet_profile.dart';
import 'package:haruchip/features/military/models/military_rank.dart';
import 'package:haruchip/features/onboarding/data/onboarding_categories.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';

void main() {
  group('CategoryModel & Metadata Tests', () {
    test('CategoryModel metadata serialization works cleanly', () {
      final category = CategoryModel(
        id: 'cat-test-1',
        categoryKey: 'military',
        name: '군대 (곰신)',
        createdAt: DateTime(2025, 1, 1),
        metadata: {
          'isInitialized': true,
          'branch': 'publicService',
          'enlistDate': '2025-01-10T00:00:00.000',
          'dischargeDate': '2026-10-10T00:00:00.000',
        },
      );

      final json = category.toJson();
      expect(json['metadata']['isInitialized'], isTrue);
      expect(json['metadata']['branch'], 'publicService');

      final restored = CategoryModel.fromJson(json);
      expect(restored.id, 'cat-test-1');
      expect(restored.metadata?['branch'], 'publicService');
      expect(restored.metadata?['isInitialized'], isTrue);
    });

    test('MilitaryBranch includes publicService with 21 months service', () {
      expect(MilitaryBranch.publicService.labelKo, '사회복무요원');
      expect(totalServiceMonths[MilitaryBranch.publicService], 21);

      final enlist = DateTime(2025, 1, 15);
      final discharge = defaultDischargeDate(enlist, MilitaryBranch.publicService);
      expect(discharge, DateTime(2026, 10, 15));
    });
  });

  group('Dual List Partitioning Tests', () {
    test('Items partition correctly into count-up (daysCount) and count-down (dday)', () {
      final items = [
        PlanItem(
          id: '1',
          title: '입대일',
          date: DateTime.now().subtract(const Duration(days: 100)),
          categoryKey: 'military',
          displayMode: DdayDisplayMode.daysCount,
        ),
        PlanItem(
          id: '2',
          title: '전역일',
          date: DateTime.now().add(const Duration(days: 440)),
          categoryKey: 'military',
          displayMode: DdayDisplayMode.dday,
        ),
        PlanItem(
          id: '3',
          title: '첫 휴가',
          date: DateTime.now().add(const Duration(days: 30)),
          categoryKey: 'military',
          displayMode: DdayDisplayMode.dday,
        ),
      ];

      final countUpItems = items.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
      final countDownItems = items.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();

      expect(countUpItems.length, 1);
      expect(countUpItems.first.title, '입대일');

      expect(countDownItems.length, 2);
      expect(countDownItems.map((i) => i.title), containsAll(['전역일', '첫 휴가']));
    });
  });

  group('PetProfile & Pet Category Tests', () {
    test('PetProfile JSON serialization & deserialization works accurately', () {
      final pet = PetProfile(
        id: 'pet-123',
        name: '콩이',
        species: '말티즈',
        icon: '🐶',
        personality: '활발하고 산책을 좋아하는 친구',
        adoptionDate: DateTime(2023, 5, 20),
        birthDate: DateTime(2023, 1, 15),
      );

      final json = pet.toJson();
      expect(json['id'], 'pet-123');
      expect(json['name'], '콩이');
      expect(json['species'], '말티즈');
      expect(json['icon'], '🐶');

      final restored = PetProfile.fromJson(json);
      expect(restored.id, 'pet-123');
      expect(restored.name, '콩이');
      expect(restored.species, '말티즈');
      expect(restored.personality, '활발하고 산책을 좋아하는 친구');
      expect(restored.adoptionDate, DateTime(2023, 5, 20));
      expect(restored.birthDate, DateTime(2023, 1, 15));
    });

    test('PetProfile rolling birthday calculation works properly across years', () {
      final now = DateTime.now();
      final pastBirthday = DateTime(now.year - 2, 1, 1);
      final pet1 = PetProfile(
        id: 'p1',
        name: '초코',
        adoptionDate: now.subtract(const Duration(days: 300)),
        birthDate: pastBirthday,
      );

      final nextBday1 = pet1.nextUpcomingBirthday;
      expect(nextBday1, isNotNull);
      final todayOnly = DateTime(now.year, now.month, now.day);
      expect(nextBday1!.isBefore(todayOnly), isFalse);

      final dDayLabel = pet1.nextBirthdayDDayLabel;
      expect(dDayLabel, anyOf(startsWith('D-'), equals('D-Day')));
    });

    test('PetProfile daysTogether and formattedAge calculation', () {
      final now = DateTime.now();
      final pet = PetProfile(
        id: 'p2',
        name: '나비',
        species: '코리안 숏헤어',
        icon: '🐱',
        adoptionDate: now.subtract(const Duration(days: 50)),
        birthDate: now.subtract(const Duration(days: 400)),
      );

      expect(pet.daysTogether, 51); // 50 days difference + 1 = 51일째
      expect(pet.formattedAge, contains('살'));
    });

    test('PetCategoryOption & kPetCategories define 9 animal groups with subBreeds', () {
      expect(kPetCategories.length, 9);
      final dogCategory = kPetCategories.firstWhere((c) => c.categoryKey == 'dog');
      expect(dogCategory.label, '강아지');
      expect(dogCategory.icon, '🐶');
      expect(dogCategory.subBreeds, containsAll(['말티즈', '푸들', '포메라니안', '기타 (직접 입력)']));

      final catCategory = kPetCategories.firstWhere((c) => c.categoryKey == 'cat');
      expect(catCategory.label, '고양이');
      expect(catCategory.icon, '🐱');
      expect(catCategory.subBreeds, containsAll(['코리안 숏헤어', '페르시안', '러시안 블루', '기타 (직접 입력)']));
    });

    test('getPetAvatarImageProvider handles network, asset, and base64 data URLs cleanly', () {
      expect(getPetAvatarImageProvider(null), isNull);
      expect(getPetAvatarImageProvider(''), isNull);

      final networkProvider = getPetAvatarImageProvider('https://example.com/pet.jpg');
      expect(networkProvider, isNotNull);

      final assetProvider = getPetAvatarImageProvider('assets/images/pet.png');
      expect(assetProvider, isNotNull);

      // Base64 Data URL
      const sampleBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
      final base64Provider = getPetAvatarImageProvider(sampleBase64);
      expect(base64Provider, isNotNull);
    });
  });

  group('BirthdayProfile & Avatar Tests', () {
    test('BirthdayProfile serialization and deserialization works correctly', () {
      final profile = BirthdayProfile(
        id: 'bday-test-1',
        name: '소영',
        birthDate: DateTime(1999, 12, 25),
        hasYear: true,
        isLunar: false,
        avatarType: BirthdayAvatarType.customAvatar,
        avatarConfig: const CustomAvatarConfig(
          faceShape: 'egg',
          skinColor: '#FFE0BD',
          hairStyle: 'long',
          hairColor: '#5C3A21',
          expression: 'sparkle',
          accessory: 'ribbon',
          bgColor: '#FFE4E6',
        ),
      );

      final json = profile.toJson();
      expect(json['id'], 'bday-test-1');
      expect(json['name'], '소영');
      expect(json['avatarType'], 'customAvatar');
      expect(json['avatarConfig']['expression'], 'sparkle');

      final restored = BirthdayProfile.fromJson(json);
      expect(restored.id, 'bday-test-1');
      expect(restored.name, '소영');
      expect(restored.avatarType, BirthdayAvatarType.customAvatar);
      expect(restored.avatarConfig?.expression, 'sparkle');
      expect(restored.avatarConfig?.hairStyle, 'long');
    });

    test('BirthdayProfile rolling D-Day and formatted birth date', () {
      final now = DateTime.now();
      final friend = BirthdayProfile(
        id: 'bday-test-2',
        name: '지민',
        birthDate: DateTime(2001, 7, 10),
        hasYear: true,
        isLunar: false,
        avatarType: BirthdayAvatarType.emoji,
        emoji: '🎂',
      );

      final nextDate = friend.nextBirthdayDate(now);
      final todayOnly = DateTime(now.year, now.month, now.day);
      expect(nextDate.isBefore(todayOnly), isFalse);

      final dDayLabel = friend.dDayLabel(now);
      expect(dDayLabel, anyOf(startsWith('D-'), equals('D-Day')));
      expect(friend.formattedBirthDate(), '2001.07.10');

      // Without year
      final friendNoYear = friend.copyWith(hasYear: false);
      expect(friendNoYear.formattedBirthDate(), '07.10');
      expect(friendNoYear.formattedAge(), isNull);

      // Lunar birthday
      final friendLunar = friend.copyWith(isLunar: true);
      expect(friendLunar.formattedBirthDate(), contains('(음력)'));
    });
  });

  group('Custom Category Option Tests', () {
    test('kOnboardingCategories contains custom category option', () {
      final customCat = kOnboardingCategories.firstWhere((c) => c.key == 'custom');
      expect(customCat.labelKo, '직접 설정하기');
      expect(customCat.emoji, '✨');
    });
  });
}

