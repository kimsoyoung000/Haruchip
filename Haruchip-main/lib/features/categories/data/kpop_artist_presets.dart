import 'package:flutter/foundation.dart';

@immutable
class KpopMemberPreset {
  const KpopMemberPreset({
    required this.name,
    required this.birthDate,
    required this.position,
    this.emoji = '🎤',
  });

  final String name;
  final DateTime birthDate;
  final String position;
  final String emoji;
}

@immutable
class KpopArtistPreset {
  const KpopArtistPreset({
    required this.id,
    required this.groupName,
    required this.fandomName,
    required this.debutDate,
    required this.officialColorHex,
    required this.members,
    this.emoji = '✨',
  });

  final String id;
  final String groupName;
  final String fandomName;
  final DateTime debutDate;
  final String officialColorHex;
  final List<KpopMemberPreset> members;
  final String emoji;
}

/// 주요 K-POP 아티스트 공식 프리셋 DB
class KpopArtistDatabase {
  static final List<KpopArtistPreset> presets = [
    KpopArtistPreset(
      id: 'bts',
      groupName: '방탄소년단 (BTS)',
      fandomName: '아미 (ARMY)',
      debutDate: DateTime(2013, 6, 13),
      officialColorHex: '#FAF5FF',
      emoji: '💜',
      members: [
        KpopMemberPreset(name: 'RM (김남준)', birthDate: DateTime(1994, 9, 12), position: '리더 / 메인래퍼', emoji: '🐨'),
        KpopMemberPreset(name: '진 (김석진)', birthDate: DateTime(1992, 12, 4), position: '서브보컬', emoji: '🐹'),
        KpopMemberPreset(name: '슈가 (민윤기)', birthDate: DateTime(1993, 3, 9), position: '리드래퍼', emoji: '🐱'),
        KpopMemberPreset(name: '제이홉 (정호석)', birthDate: DateTime(1994, 2, 18), position: '메인댄서 / 서브래퍼', emoji: '🐿️'),
        KpopMemberPreset(name: '지민 (박지민)', birthDate: DateTime(1995, 10, 13), position: '메인댄서 / 리드보컬', emoji: '🐥'),
        KpopMemberPreset(name: '뷔 (김태형)', birthDate: DateTime(1995, 12, 30), position: '서브보컬', emoji: '🐻'),
        KpopMemberPreset(name: '정국 (전정국)', birthDate: DateTime(1997, 9, 1), position: '메인보컬 / 리드댄서', emoji: '🐰'),
      ],
    ),
    KpopArtistPreset(
      id: 'seventeen',
      groupName: '세븐틴 (SEVENTEEN)',
      fandomName: '캐럿 (CARAT)',
      debutDate: DateTime(2015, 5, 26),
      officialColorHex: '#FFF0F5',
      emoji: '💎',
      members: [
        KpopMemberPreset(name: '에스쿱스 (최승철)', birthDate: DateTime(1995, 8, 8), position: '총괄리더 / 힙합팀', emoji: '🍒'),
        KpopMemberPreset(name: '정한 (윤정한)', birthDate: DateTime(1995, 10, 4), position: '보컬팀', emoji: '👼'),
        KpopMemberPreset(name: '조슈아 (홍지수)', birthDate: DateTime(1995, 12, 30), position: '보컬팀', emoji: '🦌'),
        KpopMemberPreset(name: '준 (문준휘)', birthDate: DateTime(1996, 6, 10), position: '퍼포먼스팀', emoji: '🐱'),
        KpopMemberPreset(name: '호시 (권순영)', birthDate: DateTime(1996, 6, 15), position: '퍼포먼스팀 리더', emoji: '🐯'),
        KpopMemberPreset(name: '원우 (전원우)', birthDate: DateTime(1996, 7, 17), position: '힙합팀', emoji: '🐈‍⬛'),
        KpopMemberPreset(name: '우지 (이지훈)', birthDate: DateTime(1996, 11, 22), position: '보컬팀 리더 / 프로듀서', emoji: '🍚'),
        KpopMemberPreset(name: '디에잇 (서명호)', birthDate: DateTime(1997, 11, 7), position: '퍼포먼스팀', emoji: '🐸'),
        KpopMemberPreset(name: '민규 (김민규)', birthDate: DateTime(1997, 4, 6), position: '힙합팀', emoji: '🐶'),
        KpopMemberPreset(name: '도겸 (이석민)', birthDate: DateTime(1997, 2, 18), position: '메인보컬', emoji: '🍕'),
        KpopMemberPreset(name: '승관 (부승관)', birthDate: DateTime(1998, 1, 16), position: '메인보컬', emoji: '🍊'),
        KpopMemberPreset(name: '버논 (최한솔)', birthDate: DateTime(1998, 2, 18), position: '힙합팀', emoji: '🐻‍❄️'),
        KpopMemberPreset(name: '디노 (이찬)', birthDate: DateTime(1999, 2, 11), position: '퍼포먼스팀', emoji: '🦦'),
      ],
    ),
    KpopArtistPreset(
      id: 'newjeans',
      groupName: '뉴진스 (NewJeans)',
      fandomName: '버니즈 (Bunnies)',
      debutDate: DateTime(2022, 7, 22),
      officialColorHex: '#F0F9FF',
      emoji: '🐰',
      members: [
        KpopMemberPreset(name: '민지 (김민지)', birthDate: DateTime(2004, 5, 7), position: '보컬 / 댄스', emoji: '🐻'),
        KpopMemberPreset(name: '하니 (팜하니)', birthDate: DateTime(2004, 10, 6), position: '보컬 / 댄스', emoji: '🦭'),
        KpopMemberPreset(name: '다니엘 (모지혜)', birthDate: DateTime(2005, 4, 11), position: '보컬 / 댄스', emoji: '🐶'),
        KpopMemberPreset(name: '해린 (강해린)', birthDate: DateTime(2006, 5, 15), position: '보컬 / 댄스', emoji: '🐱'),
        KpopMemberPreset(name: '혜인 (이혜인)', birthDate: DateTime(2008, 4, 21), position: '보컬 / 댄스', emoji: '🐣'),
      ],
    ),
    KpopArtistPreset(
      id: 'ive',
      groupName: '아이브 (IVE)',
      fandomName: '다이브 (DIVE)',
      debutDate: DateTime(2021, 12, 1),
      officialColorHex: '#FFF0F5',
      emoji: '🎀',
      members: [
        KpopMemberPreset(name: '안유진', birthDate: DateTime(2003, 9, 1), position: '리더 / 보컬', emoji: '🐶'),
        KpopMemberPreset(name: '가을 (김가을)', birthDate: DateTime(2002, 9, 24), position: '메인래퍼', emoji: '🐿️'),
        KpopMemberPreset(name: '레이 (나오이 레이)', birthDate: DateTime(2004, 2, 3), position: '래퍼 / 보컬', emoji: '🦋'),
        KpopMemberPreset(name: '장원영', birthDate: DateTime(2004, 8, 31), position: '보컬', emoji: '🐰'),
        KpopMemberPreset(name: '리즈 (김지원)', birthDate: DateTime(2004, 11, 21), position: '메인보컬', emoji: '🐱'),
        KpopMemberPreset(name: '이서 (이현서)', birthDate: DateTime(2007, 2, 21), position: '보컬', emoji: '🐯'),
      ],
    ),
    KpopArtistPreset(
      id: 'aespa',
      groupName: '에스파 (aespa)',
      fandomName: 'MY (마이)',
      debutDate: DateTime(2020, 11, 17),
      officialColorHex: '#FAF5FF',
      emoji: '🌌',
      members: [
        KpopMemberPreset(name: '카리나 (유지민)', birthDate: DateTime(2000, 4, 11), position: '리더 / 메인댄서 / 리드래퍼', emoji: '💙'),
        KpopMemberPreset(name: '지젤 (우치나가 애리)', birthDate: DateTime(2000, 10, 30), position: '메인래퍼 / 서브보컬', emoji: '🌙'),
        KpopMemberPreset(name: '윈터 (김민정)', birthDate: DateTime(2001, 1, 1), position: '리드보컬 / 리드댄서', emoji: '⭐'),
        KpopMemberPreset(name: '닝닝 (닝이줘)', birthDate: DateTime(2002, 10, 23), position: '메인보컬', emoji: '🦋'),
      ],
    ),
    KpopArtistPreset(
      id: 'txt',
      groupName: '투모로우바이투게더 (TXT)',
      fandomName: '모아 (MOA)',
      debutDate: DateTime(2019, 3, 4),
      officialColorHex: '#F0F9FF',
      emoji: '⭐',
      members: [
        KpopMemberPreset(name: '수빈 (최수빈)', birthDate: DateTime(2000, 12, 5), position: '리더 / 보컬', emoji: '🐰'),
        KpopMemberPreset(name: '연준 (최연준)', birthDate: DateTime(1999, 9, 13), position: '댄서 / 래퍼 / 보컬', emoji: '🦊'),
        KpopMemberPreset(name: '범규 (최범규)', birthDate: DateTime(2001, 3, 13), position: '보컬 / 댄서', emoji: '🐻'),
        KpopMemberPreset(name: '태현 (강태현)', birthDate: DateTime(2002, 2, 5), position: '보컬', emoji: '🐿️'),
        KpopMemberPreset(name: '휴닝카이', birthDate: DateTime(2002, 8, 14), position: '보컬 / 막내', emoji: '🐧'),
      ],
    ),
    KpopArtistPreset(
      id: 'straykids',
      groupName: '스트레이 키즈 (Stray Kids)',
      fandomName: '스테이 (STAY)',
      debutDate: DateTime(2018, 3, 25),
      officialColorHex: '#FFFDF4',
      emoji: '👑',
      members: [
        KpopMemberPreset(name: '방찬', birthDate: DateTime(1997, 10, 3), position: '리더 / 프로듀서', emoji: '🐺'),
        KpopMemberPreset(name: '리노 (이민호)', birthDate: DateTime(1998, 10, 25), position: '댄스라차 리더 / 보컬', emoji: '🐱'),
        KpopMemberPreset(name: '창빈 (서창빈)', birthDate: DateTime(1999, 8, 11), position: '래퍼 / 프로듀서', emoji: '🐷'),
        KpopMemberPreset(name: '현진 (황현진)', birthDate: DateTime(2000, 3, 20), position: '메인댄서 / 래퍼', emoji: '🥟'),
        KpopMemberPreset(name: '한 (한지성)', birthDate: DateTime(2000, 9, 14), position: '래퍼 / 보컬 / 프로듀서', emoji: '🐿️'),
        KpopMemberPreset(name: '필릭스', birthDate: DateTime(2000, 9, 15), position: '댄서 / 래퍼', emoji: '🐥'),
        KpopMemberPreset(name: '승민 (김승민)', birthDate: DateTime(2000, 9, 22), position: '메인보컬', emoji: '🐶'),
        KpopMemberPreset(name: '아이엔 (양정인)', birthDate: DateTime(2001, 2, 8), position: '보컬 / 막내', emoji: '🦊'),
      ],
    ),
    KpopArtistPreset(
      id: 'day6',
      groupName: '데이식스 (DAY6)',
      fandomName: '마이데이 (My Day)',
      debutDate: DateTime(2015, 9, 7),
      officialColorHex: '#F0FDF4',
      emoji: '🍀',
      members: [
        KpopMemberPreset(name: '성진 (박성진)', birthDate: DateTime(1993, 1, 16), position: '리더 / 기타 / 보컬', emoji: '🐻'),
        KpopMemberPreset(name: 'Young K (강영현)', birthDate: DateTime(1993, 12, 19), position: '베이스 / 보컬 / 랩', emoji: '🦊'),
        KpopMemberPreset(name: '원필 (김원필)', birthDate: DateTime(1994, 4, 28), position: '건반 / 보컬', emoji: '🐰'),
        KpopMemberPreset(name: '도운 (윤도운)', birthDate: DateTime(1995, 8, 25), position: '드럼 / 보컬', emoji: '🐶'),
      ],
    ),
    KpopArtistPreset(
      id: 'riize',
      groupName: '라이즈 (RIIZE)',
      fandomName: '브리즈 (BRIIZE)',
      debutDate: DateTime(2023, 9, 4),
      officialColorHex: '#FFF7ED',
      emoji: '🧡',
      members: [
        KpopMemberPreset(name: '쇼타로', birthDate: DateTime(2000, 11, 25), position: '메인댄서 / 래퍼', emoji: '🧋'),
        KpopMemberPreset(name: '은석 (송은석)', birthDate: DateTime(2001, 3, 19), position: '보컬', emoji: '🪨'),
        KpopMemberPreset(name: '성찬 (정성찬)', birthDate: DateTime(2001, 9, 13), position: '래퍼', emoji: '🦌'),
        KpopMemberPreset(name: '원빈 (박원빈)', birthDate: DateTime(2002, 3, 2), position: '센터 / 보컬 / 댄서', emoji: '🎸'),
        KpopMemberPreset(name: '소희 (이소희)', birthDate: DateTime(2003, 11, 21), position: '메인보컬', emoji: '🍨'),
        KpopMemberPreset(name: '앤톤 (이찬영)', birthDate: DateTime(2004, 3, 21), position: '보컬 / 막내', emoji: '🦕'),
      ],
    ),
    KpopArtistPreset(
      id: 'zerobaseone',
      groupName: '제로베이스원 (ZEROBASEONE)',
      fandomName: '제로즈 (ZEROSE)',
      debutDate: DateTime(2023, 7, 10),
      officialColorHex: '#F0F9FF',
      emoji: '🌹',
      members: [
        KpopMemberPreset(name: '성한빈', birthDate: DateTime(2001, 6, 13), position: '리더', emoji: '🐹'),
        KpopMemberPreset(name: '김지웅', birthDate: DateTime(1998, 12, 14), position: '보컬 / 래퍼', emoji: '🦋'),
        KpopMemberPreset(name: '장하오', birthDate: DateTime(2000, 7, 25), position: '센터 / 메인보컬', emoji: '🎻'),
        KpopMemberPreset(name: '석매튜', birthDate: DateTime(2002, 5, 28), position: '보컬 / 댄스', emoji: '🦊'),
        KpopMemberPreset(name: '김태래', birthDate: DateTime(2002, 7, 14), position: '메인보컬', emoji: '🦆'),
        KpopMemberPreset(name: '리키', birthDate: DateTime(2004, 5, 20), position: '보컬', emoji: '🐈‍⬛'),
        KpopMemberPreset(name: '김규빈', birthDate: DateTime(2004, 8, 30), position: '보컬 / 랩', emoji: '🐶'),
        KpopMemberPreset(name: '박건욱', birthDate: DateTime(2005, 1, 10), position: '올라운더', emoji: '🐯'),
        KpopMemberPreset(name: '한유진', birthDate: DateTime(2007, 3, 20), position: '메인댄서 / 막내', emoji: '🐰'),
      ],
    ),
    KpopArtistPreset(
      id: 'nmixx',
      groupName: '엔믹스 (NMIXX)',
      fandomName: '엔써 (NSWER)',
      debutDate: DateTime(2022, 2, 22),
      officialColorHex: '#F0FDF4',
      emoji: '🌊',
      members: [
        KpopMemberPreset(name: '릴리 (박진)', birthDate: DateTime(2002, 10, 17), position: '메인보컬', emoji: '🐨'),
        KpopMemberPreset(name: '해원 (오해원)', birthDate: DateTime(2003, 2, 25), position: '리더 / 메인보컬', emoji: '🐻'),
        KpopMemberPreset(name: '설윤 (설윤아)', birthDate: DateTime(2004, 1, 26), position: '보컬 / 댄서', emoji: '🐰'),
        KpopMemberPreset(name: '배이 (배진솔)', birthDate: DateTime(2004, 12, 28), position: '보컬 / 댄서', emoji: '🐥'),
        KpopMemberPreset(name: '지우 (김지우)', birthDate: DateTime(2005, 4, 13), position: '메인래퍼 / 메인댄서', emoji: '🐶'),
        KpopMemberPreset(name: '규진 (장규진)', birthDate: DateTime(2006, 5, 26), position: '메인댄서 / 래퍼 / 막내', emoji: '🐱'),
      ],
    ),
    KpopArtistPreset(
      id: 'twice',
      groupName: '트와이스 (TWICE)',
      fandomName: '원스 (ONCE)',
      debutDate: DateTime(2015, 10, 20),
      officialColorHex: '#FFF7ED',
      emoji: '🍭',
      members: [
        KpopMemberPreset(name: '나연 (임나연)', birthDate: DateTime(1995, 9, 22), position: '리드보컬 / 리드댄서', emoji: '🐰'),
        KpopMemberPreset(name: '정연 (유정연)', birthDate: DateTime(1996, 11, 1), position: '리드보컬', emoji: '🐶'),
        KpopMemberPreset(name: '모모 (히라이 모모)', birthDate: DateTime(1996, 11, 9), position: '메인댄서 / 서브보컬', emoji: '🍑'),
        KpopMemberPreset(name: '사나 (미나토자키 사나)', birthDate: DateTime(1996, 12, 29), position: '서브보컬', emoji: '🐹'),
        KpopMemberPreset(name: '지효 (박지효)', birthDate: DateTime(1997, 2, 1), position: '리더 / 메인보컬', emoji: '🦄'),
        KpopMemberPreset(name: '미나 (묘이 미나)', birthDate: DateTime(1997, 3, 24), position: '메인댄서 / 서브보컬', emoji: '🐧'),
        KpopMemberPreset(name: '다현 (김다현)', birthDate: DateTime(1998, 5, 28), position: '리드래퍼 / 서브보컬', emoji: '🦅'),
        KpopMemberPreset(name: '채영 (손채영)', birthDate: DateTime(1999, 4, 23), position: '메인래퍼 / 서브보컬', emoji: '🍓'),
        KpopMemberPreset(name: '쯔위 (저우쯔위)', birthDate: DateTime(1999, 6, 14), position: '리드댄서 / 서브보컬', emoji: '🦌'),
      ],
    ),
    KpopArtistPreset(
      id: 'blackpink',
      groupName: '블랙핑크 (BLACKPINK)',
      fandomName: '블링크 (BLINK)',
      debutDate: DateTime(2016, 8, 8),
      officialColorHex: '#FFF0F5',
      emoji: '🖤💗',
      members: [
        KpopMemberPreset(name: '지수 (김지수)', birthDate: DateTime(1995, 1, 3), position: '리드보컬', emoji: '🐰'),
        KpopMemberPreset(name: '제니 (김제니)', birthDate: DateTime(1996, 1, 16), position: '메인래퍼 / 리드보컬', emoji: '🐻'),
        KpopMemberPreset(name: '로제 (박채영)', birthDate: DateTime(1997, 2, 11), position: '메인보컬 / 리드댄서', emoji: '🐿️'),
        KpopMemberPreset(name: '리사 (라리사 마노반)', birthDate: DateTime(1997, 3, 27), position: '메인댄서 / 리드래퍼', emoji: '🐱'),
      ],
    ),
    KpopArtistPreset(
      id: 'lesserafim',
      groupName: '르세라핌 (LE SSERAFIM)',
      fandomName: '피어나 (FEARNOT)',
      debutDate: DateTime(2022, 5, 2),
      officialColorHex: '#F0F9FF',
      emoji: '🪶',
      members: [
        KpopMemberPreset(name: '김채원', birthDate: DateTime(2000, 8, 1), position: '리더 / 보컬', emoji: '🐯'),
        KpopMemberPreset(name: '사쿠라 (미야와키 사쿠라)', birthDate: DateTime(1998, 3, 19), position: '보컬', emoji: '🌸'),
        KpopMemberPreset(name: '허윤진', birthDate: DateTime(2001, 10, 8), position: '메인보컬', emoji: '🦒'),
        KpopMemberPreset(name: '카즈하 (나카무라 카즈하)', birthDate: DateTime(2003, 8, 9), position: '댄서 / 래퍼', emoji: '🦢'),
        KpopMemberPreset(name: '홍은채', birthDate: DateTime(2006, 11, 10), position: '댄서 / 보컬 / 막내', emoji: '🐥'),
      ],
    ),
    KpopArtistPreset(
      id: 'enhypen',
      groupName: '엔하이픈 (ENHYPEN)',
      fandomName: '엔진 (ENGENE)',
      debutDate: DateTime(2020, 11, 30),
      officialColorHex: '#FAF5FF',
      emoji: '🔥',
      members: [
        KpopMemberPreset(name: '정원 (양정원)', birthDate: DateTime(2004, 2, 9), position: '리더', emoji: '🐱'),
        KpopMemberPreset(name: '희승 (이희승)', birthDate: DateTime(2001, 10, 15), position: '메인보컬', emoji: '🦌'),
        KpopMemberPreset(name: '제이 (박종성)', birthDate: DateTime(2002, 4, 20), position: '보컬 / 랩', emoji: '🦅'),
        KpopMemberPreset(name: '제이크 (심재윤)', birthDate: DateTime(2002, 11, 15), position: '보컬', emoji: '🐶'),
        KpopMemberPreset(name: '성훈 (박성훈)', birthDate: DateTime(2002, 12, 8), position: '보컬 / 댄서', emoji: '🐧'),
        KpopMemberPreset(name: '선우 (김선우)', birthDate: DateTime(2003, 6, 24), position: '보컬', emoji: '🦊'),
        KpopMemberPreset(name: '니키 (니시무라 리키)', birthDate: DateTime(2005, 12, 9), position: '메인댄서 / 막내', emoji: '🐆'),
      ],
    ),
    KpopArtistPreset(
      id: 'plave',
      groupName: '플레이브 (PLAVE)',
      fandomName: '플리 (PLLI)',
      debutDate: DateTime(2023, 3, 12),
      officialColorHex: '#F0F9FF',
      emoji: '💙💜',
      members: [
        KpopMemberPreset(name: '남예준', birthDate: DateTime(2001, 9, 12), position: '리더 / 보컬', emoji: '🐬'),
        KpopMemberPreset(name: '한노아', birthDate: DateTime(2001, 2, 10), position: '보컬 / 댄서', emoji: '🦙'),
        KpopMemberPreset(name: '채밤비 (채봉구)', birthDate: DateTime(2002, 7, 15), position: '메인댄서 / 보컬', emoji: '🦌'),
        KpopMemberPreset(name: '도은호', birthDate: DateTime(2003, 5, 24), position: '메인래퍼 / 보컬', emoji: '🐺'),
        KpopMemberPreset(name: '유하민', birthDate: DateTime(2004, 11, 1), position: '메인댄서 / 래퍼 / 막내', emoji: '🐈‍⬛'),
      ],
    ),
  ];

  static KpopArtistPreset? findById(String id) {
    try {
      return presets.firstWhere((p) => p.id.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static List<KpopArtistPreset> search(String query) {
    if (query.trim().isEmpty) return presets;
    final q = query.trim().toLowerCase();
    return presets.where((p) {
      return p.groupName.toLowerCase().contains(q) ||
          p.fandomName.toLowerCase().contains(q) ||
          p.members.any((m) => m.name.toLowerCase().contains(q));
    }).toList();
  }
}
