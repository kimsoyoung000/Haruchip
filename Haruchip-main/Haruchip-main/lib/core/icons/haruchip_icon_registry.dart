import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 하루칩 오픈소스 벡터 아이콘 스타일 구분
enum HaruChipIconStyle {
  /// 파스텔 면 채움 형태의 플랫 벡터 SVG (`assets/icons/simple/`)
  simple,

  /// 세련된 2px 두께의 미니멀 라인 벡터 SVG (`assets/icons/line/`)
  line,
}

/// 아이콘 피커 및 레지스트리에서 사용하는 안전한 아이콘 메타데이터 항목
@immutable
class HaruChipIconItem {
  const HaruChipIconItem({
    required this.key,
    required this.slug,
    required this.labelKo,
    required this.group,
    required this.style,
    required this.assetPath,
  });

  /// DB 및 로컬 저장소에 저장되는 안전한 화이트리스트 식별자 (예: `simple_heart`, `line_cake`)
  final String key;

  /// 아이콘 기본 슬러그 (예: `heart`, `cake`)
  final String slug;

  /// 접근성 및 검색/툴팁용 한국어 명칭
  final String labelKo;

  /// 피커 그룹명 (`하트/기호`, `기념일/음식`, `동물/자연`, `목표/시험`)
  final String group;

  /// 아이콘 스타일 (simple / line)
  final HaruChipIconStyle style;

  /// 번들 내부 SVG 에셋 경로
  final String assetPath;
}

/// 보안 강화형 하루칩 아이콘 레지스트리
///
/// - 원격 URL 다운로드를 금지하고 앱 바이너리 내부 번들 에셋만 사용한다.
/// - DB 문자열이나 외부 입력을 직접 파일 경로로 해석하지 않고,
///   정규식(`^[a-z0-9_]+$`) 및 사전 정의된 화이트리스트 맵([_safeIconMap])을
///   통과한 키만 에셋 경로로 변환하여 Path Traversal(`../` 등)을 원천 차단한다.
class HaruChipIconRegistry {
  HaruChipIconRegistry._();

  static const String assetPrefix = 'asset:';
  static const String filePrefix = 'file:';
  static const String defaultIconKey = 'simple_default_chip';
  static const String defaultFallbackAsset = 'assets/icons/simple/default_chip.svg';

  static final RegExp _validKeyPattern = RegExp(r'^[a-z0-9_]+$');

  /// 피커 [아이콘] 탭에서 노출되는 테마별 카테고리 그룹 순서
  static const List<String> groups = <String>[
    '군대',
    '아기',
    '반려동물',
    '덕질/엔터',
    '생일/파티',
    '뷰티/취미',
    '여행/휴식',
    '일상/기호',
    '목표/시험',
  ];

  /// 화이트리스트 기반 안전 에셋 매핑 테이블 (Simple + Line 전 테마 확장 + Fallback)
  static const Map<String, String> _safeIconMap = <String, String>{
    // 안전 Fallback
    'simple_default_chip': 'assets/icons/simple/default_chip.svg',
    'line_default_chip': 'assets/icons/line/default_chip.svg',

    // 1. 군대(곰신)
    'simple_beret_bear': 'assets/icons/simple/beret_bear.svg',
    'line_beret_bear': 'assets/icons/line/beret_bear.svg',
    'simple_dog_tag': 'assets/icons/simple/dog_tag.svg',
    'line_dog_tag': 'assets/icons/line/dog_tag.svg',
    'simple_letter': 'assets/icons/simple/letter.svg',
    'line_letter': 'assets/icons/line/letter.svg',
    'simple_combat_boot': 'assets/icons/simple/combat_boot.svg',
    'line_combat_boot': 'assets/icons/line/combat_boot.svg',
    'simple_military_badge': 'assets/icons/simple/military_badge.svg',
    'line_military_badge': 'assets/icons/line/military_badge.svg',
    'simple_bugle': 'assets/icons/simple/bugle.svg',
    'line_bugle': 'assets/icons/line/bugle.svg',
    'simple_medal': 'assets/icons/simple/medal.svg',
    'line_medal': 'assets/icons/line/medal.svg',

    // 2. 아기
    'simple_baby_face': 'assets/icons/simple/baby_face.svg',
    'line_baby_face': 'assets/icons/line/baby_face.svg',
    'simple_baby_bottle': 'assets/icons/simple/baby_bottle.svg',
    'line_baby_bottle': 'assets/icons/line/baby_bottle.svg',
    'simple_baby_bowl': 'assets/icons/simple/baby_bowl.svg',
    'line_baby_bowl': 'assets/icons/line/baby_bowl.svg',
    'simple_baby_rattle': 'assets/icons/simple/baby_rattle.svg',
    'line_baby_rattle': 'assets/icons/line/baby_rattle.svg',
    'simple_stroller': 'assets/icons/simple/stroller.svg',
    'line_stroller': 'assets/icons/line/stroller.svg',
    'simple_pacifier': 'assets/icons/simple/pacifier.svg',
    'line_pacifier': 'assets/icons/line/pacifier.svg',
    'simple_baby_socks': 'assets/icons/simple/baby_socks.svg',
    'line_baby_socks': 'assets/icons/line/baby_socks.svg',

    // 3. 반려동물 & 동물 라이브러리
    'simple_dog': 'assets/icons/simple/dog.svg',
    'line_dog': 'assets/icons/line/dog.svg',
    'simple_cat': 'assets/icons/simple/cat.svg',
    'line_cat': 'assets/icons/line/cat.svg',
    'simple_hamster': 'assets/icons/simple/hamster.svg',
    'line_hamster': 'assets/icons/line/hamster.svg',
    'simple_rabbit': 'assets/icons/simple/rabbit.svg',
    'line_rabbit': 'assets/icons/line/rabbit.svg',
    'simple_paw': 'assets/icons/simple/paw.svg',
    'line_paw': 'assets/icons/line/paw.svg',
    'simple_fish_bone': 'assets/icons/simple/fish_bone.svg',
    'line_fish_bone': 'assets/icons/line/fish_bone.svg',
    'simple_dog_bone': 'assets/icons/simple/dog_bone.svg',
    'line_dog_bone': 'assets/icons/line/dog_bone.svg',
    'simple_bear': 'assets/icons/simple/bear.svg',
    'line_bear': 'assets/icons/line/bear.svg',
    'simple_chick': 'assets/icons/simple/chick.svg',
    'line_chick': 'assets/icons/line/chick.svg',
    'simple_panda': 'assets/icons/simple/panda.svg',
    'line_panda': 'assets/icons/line/panda.svg',
    'simple_fox': 'assets/icons/simple/fox.svg',
    'line_fox': 'assets/icons/line/fox.svg',
    'simple_tiger': 'assets/icons/simple/tiger.svg',
    'line_tiger': 'assets/icons/line/tiger.svg',
    'simple_squirrel': 'assets/icons/simple/squirrel.svg',
    'line_squirrel': 'assets/icons/line/squirrel.svg',
    'simple_frog': 'assets/icons/simple/frog.svg',
    'line_frog': 'assets/icons/line/frog.svg',
    'simple_pig': 'assets/icons/simple/pig.svg',
    'line_pig': 'assets/icons/line/pig.svg',
    'simple_monkey': 'assets/icons/simple/monkey.svg',
    'line_monkey': 'assets/icons/line/monkey.svg',
    'simple_deer': 'assets/icons/simple/deer.svg',
    'line_deer': 'assets/icons/line/deer.svg',
    'simple_penguin': 'assets/icons/simple/penguin.svg',
    'line_penguin': 'assets/icons/line/penguin.svg',
    'simple_koala': 'assets/icons/simple/koala.svg',
    'line_koala': 'assets/icons/line/koala.svg',
    'simple_dolphin': 'assets/icons/simple/dolphin.svg',
    'line_dolphin': 'assets/icons/line/dolphin.svg',
    'simple_duck': 'assets/icons/simple/duck.svg',
    'line_duck': 'assets/icons/line/duck.svg',
    'simple_lion': 'assets/icons/simple/lion.svg',
    'line_lion': 'assets/icons/line/lion.svg',
    'simple_owl': 'assets/icons/simple/owl.svg',
    'line_owl': 'assets/icons/line/owl.svg',

    // 4. 덕질 / 문화·엔터
    'simple_lightstick': 'assets/icons/simple/lightstick.svg',
    'line_lightstick': 'assets/icons/line/lightstick.svg',
    'simple_microphone': 'assets/icons/simple/microphone.svg',
    'line_microphone': 'assets/icons/line/microphone.svg',
    'simple_ticket': 'assets/icons/simple/ticket.svg',
    'line_ticket': 'assets/icons/line/ticket.svg',
    'simple_camera': 'assets/icons/simple/camera.svg',
    'line_camera': 'assets/icons/line/camera.svg',
    'simple_vinyl_lp': 'assets/icons/simple/vinyl_lp.svg',
    'line_vinyl_lp': 'assets/icons/line/vinyl_lp.svg',
    'simple_movie_film': 'assets/icons/simple/movie_film.svg',
    'line_movie_film': 'assets/icons/line/movie_film.svg',
    'simple_tv_monitor': 'assets/icons/simple/tv_monitor.svg',
    'line_tv_monitor': 'assets/icons/line/tv_monitor.svg',
    'simple_heart_album': 'assets/icons/simple/heart_album.svg',
    'line_heart_album': 'assets/icons/line/heart_album.svg',
    'simple_music': 'assets/icons/simple/music.svg',
    'line_music': 'assets/icons/line/music.svg',

    // 5. 생일 / 파티
    'simple_cake': 'assets/icons/simple/cake.svg',
    'line_cake': 'assets/icons/line/cake.svg',
    'simple_candle': 'assets/icons/simple/candle.svg',
    'line_candle': 'assets/icons/line/candle.svg',
    'simple_gift': 'assets/icons/simple/gift.svg',
    'line_gift': 'assets/icons/line/gift.svg',
    'simple_party': 'assets/icons/simple/party.svg',
    'line_party': 'assets/icons/line/party.svg',
    'simple_party_hat': 'assets/icons/simple/party_hat.svg',
    'line_party_hat': 'assets/icons/line/party_hat.svg',
    'simple_balloon': 'assets/icons/simple/balloon.svg',
    'line_balloon': 'assets/icons/line/balloon.svg',

    // 6. 뷰티 / 패션 / 취미
    'simple_lipstick': 'assets/icons/simple/lipstick.svg',
    'line_lipstick': 'assets/icons/line/lipstick.svg',
    'simple_makeup_brush': 'assets/icons/simple/makeup_brush.svg',
    'line_makeup_brush': 'assets/icons/line/makeup_brush.svg',
    'simple_perfume': 'assets/icons/simple/perfume.svg',
    'line_perfume': 'assets/icons/line/perfume.svg',
    'simple_mirror': 'assets/icons/simple/mirror.svg',
    'line_mirror': 'assets/icons/line/mirror.svg',
    'simple_shopping_bag': 'assets/icons/simple/shopping_bag.svg',
    'line_shopping_bag': 'assets/icons/line/shopping_bag.svg',
    'simple_ribbon': 'assets/icons/simple/ribbon.svg',
    'line_ribbon': 'assets/icons/line/ribbon.svg',
    'simple_palette': 'assets/icons/simple/palette.svg',
    'line_palette': 'assets/icons/line/palette.svg',
    'simple_gamepad': 'assets/icons/simple/gamepad.svg',
    'line_gamepad': 'assets/icons/line/gamepad.svg',

    // 7. 여행 / 휴식
    'simple_suitcase': 'assets/icons/simple/suitcase.svg',
    'line_suitcase': 'assets/icons/line/suitcase.svg',
    'simple_passport': 'assets/icons/simple/passport.svg',
    'line_passport': 'assets/icons/line/passport.svg',
    'simple_airplane': 'assets/icons/simple/airplane.svg',
    'line_airplane': 'assets/icons/line/airplane.svg',
    'simple_palm_tree': 'assets/icons/simple/palm_tree.svg',
    'line_palm_tree': 'assets/icons/line/palm_tree.svg',
    'simple_tent': 'assets/icons/simple/tent.svg',
    'line_tent': 'assets/icons/line/tent.svg',
    'simple_travel_map': 'assets/icons/simple/travel_map.svg',
    'line_travel_map': 'assets/icons/line/travel_map.svg',
    'simple_sunglasses': 'assets/icons/simple/sunglasses.svg',
    'line_sunglasses': 'assets/icons/line/sunglasses.svg',
    'simple_car': 'assets/icons/simple/car.svg',
    'line_car': 'assets/icons/line/car.svg',

    // 8. 일상 / 기호 / 자연 / 음식
    'simple_heart': 'assets/icons/simple/heart.svg',
    'line_heart': 'assets/icons/line/heart.svg',
    'simple_star': 'assets/icons/simple/star.svg',
    'line_star': 'assets/icons/line/star.svg',
    'simple_sparkle': 'assets/icons/simple/sparkle.svg',
    'line_sparkle': 'assets/icons/line/sparkle.svg',
    'simple_ring': 'assets/icons/simple/ring.svg',
    'line_ring': 'assets/icons/line/ring.svg',
    'simple_smile': 'assets/icons/simple/smile.svg',
    'line_smile': 'assets/icons/line/smile.svg',
    'simple_crown': 'assets/icons/simple/crown.svg',
    'line_crown': 'assets/icons/line/crown.svg',
    'simple_infinity': 'assets/icons/simple/infinity.svg',
    'line_infinity': 'assets/icons/line/infinity.svg',
    'simple_coffee': 'assets/icons/simple/coffee.svg',
    'line_coffee': 'assets/icons/line/coffee.svg',
    'simple_beer': 'assets/icons/simple/beer.svg',
    'line_beer': 'assets/icons/line/beer.svg',
    'simple_pizza': 'assets/icons/simple/pizza.svg',
    'line_pizza': 'assets/icons/line/pizza.svg',
    'simple_strawberry': 'assets/icons/simple/strawberry.svg',
    'line_strawberry': 'assets/icons/line/strawberry.svg',
    'simple_wine': 'assets/icons/simple/wine.svg',
    'line_wine': 'assets/icons/line/wine.svg',
    'simple_flower': 'assets/icons/simple/flower.svg',
    'line_flower': 'assets/icons/line/flower.svg',
    'simple_clover': 'assets/icons/simple/clover.svg',
    'line_clover': 'assets/icons/line/clover.svg',
    'simple_sprout': 'assets/icons/simple/sprout.svg',
    'line_sprout': 'assets/icons/line/sprout.svg',
    'simple_sun': 'assets/icons/simple/sun.svg',
    'line_sun': 'assets/icons/line/sun.svg',
    'simple_moon': 'assets/icons/simple/moon.svg',
    'line_moon': 'assets/icons/line/moon.svg',

    // 9. 목표 / 시험 / 일정
    'simple_book': 'assets/icons/simple/book.svg',
    'line_book': 'assets/icons/line/book.svg',
    'simple_pencil': 'assets/icons/simple/pencil.svg',
    'line_pencil': 'assets/icons/line/pencil.svg',
    'simple_graduation': 'assets/icons/simple/graduation.svg',
    'line_graduation': 'assets/icons/line/graduation.svg',
    'simple_target': 'assets/icons/simple/target.svg',
    'line_target': 'assets/icons/line/target.svg',
    'simple_calendar': 'assets/icons/simple/calendar.svg',
    'line_calendar': 'assets/icons/line/calendar.svg',
    'simple_clock': 'assets/icons/simple/clock.svg',
    'line_clock': 'assets/icons/line/clock.svg',
    'simple_laptop': 'assets/icons/simple/laptop.svg',
    'line_laptop': 'assets/icons/line/laptop.svg',
  };

  /// 그룹별 아이콘 메타데이터 시드 (9대 테마 풀)
  static const List<({String slug, String labelKo, String group})> _catalogSeed = [
    // 군대(곰신)
    (slug: 'beret_bear', labelKo: '베레모 곰돌이', group: '군대'),
    (slug: 'dog_tag', labelKo: '군번줄', group: '군대'),
    (slug: 'letter', labelKo: '편지/소포', group: '군대'),
    (slug: 'combat_boot', labelKo: '전투화', group: '군대'),
    (slug: 'military_badge', labelKo: '국방 마크', group: '군대'),
    (slug: 'bugle', labelKo: '나팔', group: '군대'),
    (slug: 'medal', labelKo: '훈장/메달', group: '군대'),

    // 아기
    (slug: 'baby_face', labelKo: '아기 얼굴', group: '아기'),
    (slug: 'baby_bottle', labelKo: '젖병', group: '아기'),
    (slug: 'baby_bowl', labelKo: '이유식 보울', group: '아기'),
    (slug: 'baby_rattle', labelKo: '딸랑이', group: '아기'),
    (slug: 'stroller', labelKo: '유모차', group: '아기'),
    (slug: 'pacifier', labelKo: '쪽쪽이', group: '아기'),
    (slug: 'baby_socks', labelKo: '아기 양말', group: '아기'),

    // 반려동물
    (slug: 'dog', labelKo: '강아지', group: '반려동물'),
    (slug: 'cat', labelKo: '고양이', group: '반려동물'),
    (slug: 'hamster', labelKo: '햄스터', group: '반려동물'),
    (slug: 'rabbit', labelKo: '토끼', group: '반려동물'),
    (slug: 'paw', labelKo: '발자국', group: '반려동물'),
    (slug: 'fish_bone', labelKo: '생선 가시', group: '반려동물'),
    (slug: 'dog_bone', labelKo: '뼈다귀', group: '반려동물'),
    (slug: 'bear', labelKo: '곰돌이', group: '반려동물'),
    (slug: 'chick', labelKo: '병아리', group: '반려동물'),
    (slug: 'panda', labelKo: '판다', group: '반려동물'),
    (slug: 'fox', labelKo: '여우', group: '반려동물'),
    (slug: 'tiger', labelKo: '호랑이', group: '반려동물'),
    (slug: 'squirrel', labelKo: '다람쥐', group: '반려동물'),
    (slug: 'frog', labelKo: '개구리', group: '반려동물'),
    (slug: 'pig', labelKo: '돼지', group: '반려동물'),
    (slug: 'monkey', labelKo: '원숭이', group: '반려동물'),
    (slug: 'deer', labelKo: '사슴', group: '반려동물'),
    (slug: 'penguin', labelKo: '펭귄', group: '반려동물'),
    (slug: 'koala', labelKo: '코알라', group: '반려동물'),
    (slug: 'dolphin', labelKo: '돌고래', group: '반려동물'),
    (slug: 'duck', labelKo: '오리', group: '반려동물'),
    (slug: 'lion', labelKo: '사자', group: '반려동물'),
    (slug: 'owl', labelKo: '부엉이', group: '반려동물'),

    // 덕질 / 문화·엔터
    (slug: 'lightstick', labelKo: '응원봉', group: '덕질/엔터'),
    (slug: 'microphone', labelKo: '마이크', group: '덕질/엔터'),
    (slug: 'ticket', labelKo: '티켓', group: '덕질/엔터'),
    (slug: 'camera', labelKo: '카메라', group: '덕질/엔터'),
    (slug: 'vinyl_lp', labelKo: 'LP판', group: '덕질/엔터'),
    (slug: 'movie_film', labelKo: '영화 필름', group: '덕질/엔터'),
    (slug: 'tv_monitor', labelKo: 'TV/모니터', group: '덕질/엔터'),
    (slug: 'heart_album', labelKo: '하트 앨범', group: '덕질/엔터'),
    (slug: 'music', labelKo: '음악', group: '덕질/엔터'),

    // 생일 / 파티
    (slug: 'cake', labelKo: '생일 케이크', group: '생일/파티'),
    (slug: 'candle', labelKo: '촛불', group: '생일/파티'),
    (slug: 'gift', labelKo: '선물 상자', group: '생일/파티'),
    (slug: 'party', labelKo: '파티 폭죽', group: '생일/파티'),
    (slug: 'party_hat', labelKo: '고깔모자', group: '생일/파티'),
    (slug: 'balloon', labelKo: '풍선', group: '생일/파티'),

    // 뷰티 / 패션 / 취미
    (slug: 'lipstick', labelKo: '립스틱', group: '뷰티/취미'),
    (slug: 'makeup_brush', labelKo: '화장품 브러시', group: '뷰티/취미'),
    (slug: 'perfume', labelKo: '향수', group: '뷰티/취미'),
    (slug: 'mirror', labelKo: '거울', group: '뷰티/취미'),
    (slug: 'shopping_bag', labelKo: '쇼핑백', group: '뷰티/취미'),
    (slug: 'ribbon', labelKo: '리본', group: '뷰티/취미'),
    (slug: 'palette', labelKo: '팔레트/붓', group: '뷰티/취미'),
    (slug: 'gamepad', labelKo: '게임기', group: '뷰티/취미'),

    // 여행 / 휴식
    (slug: 'suitcase', labelKo: '캐리어', group: '여행/휴식'),
    (slug: 'passport', labelKo: '여권', group: '여행/휴식'),
    (slug: 'airplane', labelKo: '비행기', group: '여행/휴식'),
    (slug: 'palm_tree', labelKo: '야자수', group: '여행/휴식'),
    (slug: 'tent', labelKo: '텐트', group: '여행/휴식'),
    (slug: 'travel_map', labelKo: '지도', group: '여행/휴식'),
    (slug: 'sunglasses', labelKo: '선글라스', group: '여행/휴식'),
    (slug: 'car', labelKo: '자동차', group: '여행/휴식'),

    // 일상 / 기호
    (slug: 'heart', labelKo: '하트', group: '일상/기호'),
    (slug: 'star', labelKo: '별', group: '일상/기호'),
    (slug: 'sparkle', labelKo: '반짝이', group: '일상/기호'),
    (slug: 'ring', labelKo: '반지', group: '일상/기호'),
    (slug: 'smile', labelKo: '스마일', group: '일상/기호'),
    (slug: 'crown', labelKo: '왕관', group: '일상/기호'),
    (slug: 'infinity', labelKo: '무한대', group: '일상/기호'),
    (slug: 'coffee', labelKo: '커피', group: '일상/기호'),
    (slug: 'beer', labelKo: '모임', group: '일상/기호'),
    (slug: 'pizza', labelKo: '피자', group: '일상/기호'),
    (slug: 'strawberry', labelKo: '딸기', group: '일상/기호'),
    (slug: 'wine', labelKo: '와인', group: '일상/기호'),
    (slug: 'flower', labelKo: '꽃', group: '일상/기호'),
    (slug: 'clover', labelKo: '클로버', group: '일상/기호'),
    (slug: 'sprout', labelKo: '새싹', group: '일상/기호'),
    (slug: 'sun', labelKo: '태양', group: '일상/기호'),
    (slug: 'moon', labelKo: '달', group: '일상/기호'),

    // 목표 / 시험
    (slug: 'book', labelKo: '책', group: '목표/시험'),
    (slug: 'pencil', labelKo: '연필', group: '목표/시험'),
    (slug: 'graduation', labelKo: '학사모', group: '목표/시험'),
    (slug: 'target', labelKo: '목표', group: '목표/시험'),
    (slug: 'calendar', labelKo: '달력', group: '목표/시험'),
    (slug: 'clock', labelKo: '루틴/시계', group: '목표/시험'),
    (slug: 'laptop', labelKo: '노트북', group: '목표/시험'),
  ];

  /// 기본 카테고리별 최신 심플 파스텔 대표 아이콘 매핑
  static String defaultIconForCategoryKey(String categoryKey) {
    return switch (categoryKey) {
      'couple' => 'simple_heart',
      'fandom' => 'simple_lightstick',
      'baby' => 'simple_baby_face',
      'military' => 'simple_beret_bear',
      'exam' => 'simple_book',
      'wedding' => 'simple_ring',
      'birthday' => 'simple_cake',
      'pet' => 'simple_paw',
      'plan' => 'simple_calendar',
      'goal' => 'simple_target',
      'routine' => 'simple_clock',
      'hobby' => 'simple_palette',
      'travel' => 'simple_airplane',
      'custom' => 'simple_sparkle',
      _ => defaultIconKey,
    };
  }

  static const Set<String> _legacyDefaultEmojis = <String>{
    '❤️',
    '⭐',
    '👶',
    '🎖️',
    '📚',
    '💍',
    '🎂',
    '🐾',
    '📅',
    '🎯',
    '⏱️',
    '🎨',
    '✈️',
    '✨',
  };

  /// 기존 저장된 구형 이모지 기본 아이콘을 최신 심플 파스텔 에셋 키로 안전하게 업그레이드한다.
  /// (사용자가 직접 지정한 사진·커스텀 에셋 키는 그대로 보존)
  static String upgradeLegacyCategoryIcon(String categoryKey, String rawIcon) {
    final trimmed = rawIcon.trim();
    if (trimmed.isEmpty || _legacyDefaultEmojis.contains(trimmed)) {
      return defaultIconForCategoryKey(categoryKey);
    }
    return rawIcon;
  }

  /// 선택적 `asset:` 접두사를 제거하고 정규화된 키를 반환한다.
  static String normalizeKey(String rawKey) {
    final trimmed = rawKey.trim();
    if (trimmed.startsWith(assetPrefix)) {
      return trimmed.substring(assetPrefix.length).trim();
    }
    return trimmed;
  }

  /// 화이트리스트 및 정규식 검증을 모두 통과한 안전한 아이콘 키인지 확인한다.
  static bool isSafeRegistryKey(String rawKey) {
    final normalized = normalizeKey(rawKey);
    if (normalized.isEmpty || !_validKeyPattern.hasMatch(normalized)) {
      return false;
    }
    return _safeIconMap.containsKey(normalized);
  }

  /// 경로 조작(`../`, `/`, `\`) 또는 미등록 에셋 키 접근 시도인지 판별한다.
  ///
  /// 이 조건에 해당하지만 [isSafeRegistryKey]를 통과하지 못한 입력은
  /// 이모지 텍스트로 노출하지 않고 안전 Fallback([defaultFallbackAsset])으로 차단한다.
  static bool isAssetKeyAttempt(String rawKey) {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith(assetPrefix) ||
        trimmed.startsWith('simple_') ||
        trimmed.startsWith('line_') ||
        trimmed.startsWith('assets/')) {
      return true;
    }
    if (trimmed.contains('..') ||
        trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        trimmed.contains('\x00')) {
      return true;
    }
    return false;
  }

  /// 화이트리스트 기반 안전 에셋 경로 조회.
  ///
  /// 등록되지 않았거나 정규식을 통과하지 못한 키는 무조건 [defaultFallbackAsset]을 반환한다.
  static String getAssetPath(String key) {
    final normalized = normalizeKey(key);
    if (!_validKeyPattern.hasMatch(normalized) || !_safeIconMap.containsKey(normalized)) {
      return defaultFallbackAsset;
    }
    return _safeIconMap[normalized]!;
  }

  /// 등록된 전체 안전 키 목록 (테스트 및 검증용)
  static Set<String> get registeredKeys => Set<String>.unmodifiable(_safeIconMap.keys);

  /// 특정 스타일 및 그룹에 속한 아이콘 항목 목록 반환
  static List<HaruChipIconItem> iconsByGroup(
    String group, {
    HaruChipIconStyle style = HaruChipIconStyle.simple,
  }) {
    final prefix = style == HaruChipIconStyle.simple ? 'simple_' : 'line_';
    return _catalogSeed
        .where((e) => e.group == group)
        .map((e) {
          final key = '$prefix${e.slug}';
          return HaruChipIconItem(
            key: key,
            slug: e.slug,
            labelKo: e.labelKo,
            group: e.group,
            style: style,
            assetPath: getAssetPath(key),
          );
        })
        .toList(growable: false);
  }

  /// 피커용 전체 그룹 맵 반환 (`group -> List<HaruChipIconItem>`)
  static Map<String, List<HaruChipIconItem>> groupedCatalog({
    HaruChipIconStyle style = HaruChipIconStyle.simple,
  }) {
    return <String, List<HaruChipIconItem>>{
      for (final group in groups) group: iconsByGroup(group, style: style),
    };
  }

  /// 빠른 선택 프리셋 목록 (모달 내 컴팩트 미리보기용)
  static const List<String> quickPresetKeys = <String>[
    'simple_heart',
    'simple_star',
    'simple_cake',
    'simple_gift',
    'simple_ring',
    'simple_airplane',
    'simple_book',
    'simple_paw',
    'simple_coffee',
    'simple_baby_bottle',
    'simple_beer',
    'simple_palette',
  ];

  /// 모임/프로필 빠른 선택 프리셋 목록
  static const List<String> profileQuickPresetKeys = <String>[
    'simple_chick',
    'simple_dog',
    'simple_cat',
    'simple_bear',
    'simple_paw',
    'simple_smile',
    'simple_star',
    'simple_heart',
    'simple_flower',
    'simple_clover',
    'simple_coffee',
    'simple_crown',
  ];

  /// 모임 대표 아이콘 빠른 선택 프리셋 목록
  static const List<String> groupQuickPresetKeys = <String>[
    'simple_beer',
    'simple_coffee',
    'simple_pizza',
    'simple_wine',
    'simple_party',
    'simple_music',
    'simple_airplane',
    'simple_book',
    'simple_star',
    'simple_heart',
    'simple_clover',
    'simple_crown',
  ];

  /// 키에 해당하는 한국어 라벨 조회 (접근성/스낵바 안내용)
  static String labelForKey(String rawKey) {
    if (rawKey.startsWith(filePrefix)) {
      return '내 사진';
    }
    final normalized = normalizeKey(rawKey);
    if (!isSafeRegistryKey(normalized)) {
      return rawKey.trim().isEmpty ? '기본 아이콘' : rawKey;
    }
    final slug = normalized.startsWith('simple_')
        ? normalized.substring('simple_'.length)
        : normalized.startsWith('line_')
            ? normalized.substring('line_'.length)
            : normalized;
    for (final item in _catalogSeed) {
      if (item.slug == slug) {
        return item.labelKo;
      }
    }
    return '하루칩 아이콘';
  }
}

/// 앱 내부 저장소(Sandbox) 격리 사진 저장 및 경로 무결성 검증 유틸리티
///
/// - 사용자가 [사진] 탭에서 고른 이미지는 앱 전용 내부 디렉토리(`haruchip_icons/`)로
///   안전하게 복사한 뒤 `file:<sandbox_path>` 키로만 저장한다.
/// - 렌더링 시에도 앱 샌드박스 루트 밖 경로(`../`, 임의 절대경로 등)는 엄격히 거부한다.
class HaruChipIconSandbox {
  HaruChipIconSandbox._();

  static const String _sandboxFolderName = 'haruchip_icons';
  static const Set<String> _allowedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static String? _cachedSandboxRootPath;

  /// 테스트 또는 초기화 시 샌드박스 루트 경로를 미리 캐싱한다.
  static Future<Directory> getSandboxDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final sandboxDir = Directory(p.join(docsDir.path, _sandboxFolderName));
    if (!await sandboxDir.exists()) {
      await sandboxDir.create(recursive: true);
    }
    _cachedSandboxRootPath = p.canonicalize(sandboxDir.path);
    return sandboxDir;
  }

  /// 현재 캐싱된 샌드박스 루트 경로 (동기 Fast-Path용)
  static String? get cachedSandboxRootPath => _cachedSandboxRootPath;

  /// 테스트 전용: 샌드박스 루트 경로 오버라이드
  @visibleForTesting
  static void debugOverrideSandboxRoot(String? path) {
    _cachedSandboxRootPath = path != null ? p.canonicalize(path) : null;
  }

  /// 갤러리에서 선택한 사진 파일을 앱 샌드박스 내부로 안전하게 격리 복사하고
  /// `file:<canonicalPath>` 형식의 키를 반환한다.
  static Future<String?> savePhotoToSandbox(File sourceFile) async {
    if (!await sourceFile.exists()) return null;

    final rawExt = p.extension(sourceFile.path).toLowerCase();
    final safeExt = _allowedExtensions.contains(rawExt) ? rawExt : '.jpg';
    final sandboxDir = await getSandboxDirectory();
    final fileName = 'icon_${DateTime.now().microsecondsSinceEpoch}$safeExt';
    final targetPath = p.canonicalize(p.join(sandboxDir.path, fileName));

    // 생성된 대상 경로가 반드시 샌드박스 디렉토리 내부인지 재검증
    if (!p.isWithin(p.canonicalize(sandboxDir.path), targetPath)) {
      return null;
    }

    final copied = await sourceFile.copy(targetPath);
    return '${HaruChipIconRegistry.filePrefix}${p.canonicalize(copied.path)}';
  }

  /// `file:` 키에서 경로를 추출하고, 경로 조작 및 샌드박스 이탈 여부를 검증한다.
  static File? resolveSafeSandboxFileSync(String iconKey) {
    final root = _cachedSandboxRootPath;
    if (root == null) return null;
    return _validateAgainstRoot(iconKey, root);
  }

  /// 비동기 경로 무결성 검증 (캐시가 비어있을 때 샌드박스 루트를 먼저 확보)
  static Future<File?> resolveSafeSandboxFile(String iconKey) async {
    if (!iconKey.startsWith(HaruChipIconRegistry.filePrefix)) {
      return null;
    }
    try {
      final root = _cachedSandboxRootPath ?? (await getSandboxDirectory()).path;
      return _validateAgainstRoot(iconKey, root);
    } catch (_) {
      return null;
    }
  }

  static File? _validateAgainstRoot(String iconKey, String sandboxRoot) {
    if (!iconKey.startsWith(HaruChipIconRegistry.filePrefix)) {
      return null;
    }
    final rawPath = iconKey.substring(HaruChipIconRegistry.filePrefix.length).trim();
    if (rawPath.isEmpty ||
        rawPath.contains('\x00') ||
        rawPath.contains('..')) {
      return null;
    }

    final canonicalRoot = p.canonicalize(sandboxRoot);
    final canonicalTarget = p.canonicalize(rawPath);

    // 반드시 샌드박스 디렉토리 내부의 파일이어야 함 (Path Traversal 차단)
    if (!p.isWithin(canonicalRoot, canonicalTarget)) {
      return null;
    }

    final ext = p.extension(canonicalTarget).toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      return null;
    }

    final file = File(canonicalTarget);
    if (!file.existsSync()) {
      return null;
    }
    return file;
  }
}
