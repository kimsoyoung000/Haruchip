import '../models/exam_model.dart';

/// 공식 시험 회차 정보
class OfficialExamRound {
  const OfficialExamRound({
    required this.roundName,
    required this.year,
    required this.stages,
  });

  final String roundName; // e.g. '2026년 제1회', '제538회 (9월)'
  final int year;
  final List<ExamStageItem> stages;

  /// 최종 합격자 발표일 (또는 최종 결과/성적 발표일)
  DateTime get finalResultDate {
    // 1. finalResult 타입 단계 (최종 합격 발표)
    final finalStages = stages.where((s) => s.stageType == ExamStageType.finalResult).toList();
    if (finalStages.isNotEmpty) {
      return finalStages.first.endDate ?? finalStages.first.startDate;
    }
    // 2. writtenResult 타입 단계 (성적/합격 발표)
    final resultStages = stages.where((s) => s.stageType == ExamStageType.writtenResult).toList();
    if (resultStages.isNotEmpty) {
      return resultStages.last.endDate ?? resultStages.last.startDate;
    }
    // 3. 가장 늦은 날짜의 단계
    if (stages.isNotEmpty) {
      final latest = stages.reduce((a, b) {
        final aDate = a.endDate ?? a.startDate;
        final bDate = b.endDate ?? b.startDate;
        return aDate.isAfter(bDate) ? a : b;
      });
      return latest.endDate ?? latest.startDate;
    }
    return DateTime(year, 12, 31);
  }

  /// [자동 삭제 파기 규칙]:
  /// '최종 합격자 발표일' 다음 날(자정 00:00)이 지나면 공식 DB 목록에서 자동으로 만료(숨김 또는 삭제)
  bool isExpired([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final fDate = finalResultDate;
    final expirationMidnight = DateTime(fDate.year, fDate.month, fDate.day).add(const Duration(days: 1));
    return now.isAfter(expirationMidnight);
  }
}

/// 공식 시험 프리셋 메타데이터
class OfficialExamPreset {
  const OfficialExamPreset({
    required this.id,
    required this.groupCategory,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.type,
    required this.rounds,
    this.defaultChecklist = const ['신분증', '수험표', '컴퓨터용 사인펜', '수정테이프'],
  });

  final String id;
  final String groupCategory; // '어학/상시', '국가기술자격', '공무원/공기업', '입시/수능', '학교시험'
  final String title;
  final String description;
  final String colorHex;
  final ExamType type;
  final List<OfficialExamRound> rounds;
  final List<String> defaultChecklist;

  OfficialExamPreset copyWith({
    String? id,
    String? groupCategory,
    String? title,
    String? description,
    String? colorHex,
    ExamType? type,
    List<OfficialExamRound>? rounds,
    List<String>? defaultChecklist,
  }) {
    return OfficialExamPreset(
      id: id ?? this.id,
      groupCategory: groupCategory ?? this.groupCategory,
      title: title ?? this.title,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      rounds: rounds ?? this.rounds,
      defaultChecklist: defaultChecklist ?? this.defaultChecklist,
    );
  }

  /// 현재 시점 기준 만료되지 않은 유효 회차 목록
  List<OfficialExamRound> getActiveRounds([DateTime? relativeTo]) {
    return rounds.where((r) => !r.isExpired(relativeTo)).toList();
  }

  /// 현재 유효한 회차가 남아있는지 여부
  bool hasActiveRounds([DateTime? relativeTo]) {
    return getActiveRounds(relativeTo).isNotEmpty;
  }
}

/// 현재 시점 기준 만료(파기)되지 않은 유효한 공식 시험 프리셋 목록 반환
List<OfficialExamPreset> getActiveOfficialExamPresets([DateTime? relativeTo]) {
  final now = relativeTo ?? DateTime.now();
  final activeList = <OfficialExamPreset>[];
  for (final preset in kOfficialExamPresets) {
    final activeRounds = preset.getActiveRounds(now);
    if (activeRounds.isNotEmpty) {
      activeList.add(preset.copyWith(rounds: activeRounds));
    }
  }
  return activeList;
}

/// 연간 회차별 공식 시험 프리셋 데이터베이스
final List<OfficialExamPreset> kOfficialExamPresets = [
  // ==========================================
  // 1. 어학 / 상시 자격증
  // ==========================================
  OfficialExamPreset(
    id: 'preset-toeic',
    groupCategory: '어학/상시',
    title: '토익 (TOEIC)',
    description: 'YBM 한국TOEIC위원회 주관 전국 정기 시험 (일요일 오전 09:20)',
    colorHex: '#2563EB',
    type: ExamType.qualification,
    defaultChecklist: ['신분증 (주민등록증/운전면허증/여권)', '연필(2B)', '지우개', '아날로그 손목시계'],
    rounds: [
      OfficialExamRound(
        roundName: '제538회 (2026.09.27)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'toeic-538-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 8, 10),
            endDate: DateTime(2026, 9, 21),
            testTime: '마감일 12:00까지',
          ),
          ExamStageItem(
            id: 'toeic-538-2',
            stageType: ExamStageType.writtenTest,
            name: '토익 정기시험일',
            startDate: DateTime(2026, 9, 27),
            testTime: '09:20 입실완료 (09:50~12:10 시험)',
            checklist: ['규정 신분증', '연필 및 지우개', '아날로그 시계'],
          ),
          ExamStageItem(
            id: 'toeic-538-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2026, 10, 7),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '제539회 (2026.10.25)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'toeic-539-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 9, 7),
            endDate: DateTime(2026, 10, 19),
            testTime: '마감일 12:00까지',
          ),
          ExamStageItem(
            id: 'toeic-539-2',
            stageType: ExamStageType.writtenTest,
            name: '토익 정기시험일',
            startDate: DateTime(2026, 10, 25),
            testTime: '09:20 입실완료 (09:50~12:10 시험)',
            checklist: ['규정 신분증', '연필 및 지우개', '아날로그 시계'],
          ),
          ExamStageItem(
            id: 'toeic-539-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2026, 11, 4),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '제540회 (2026.11.29)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'toeic-540-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 10, 12),
            endDate: DateTime(2026, 11, 23),
            testTime: '마감일 12:00까지',
          ),
          ExamStageItem(
            id: 'toeic-540-2',
            stageType: ExamStageType.writtenTest,
            name: '토익 정기시험일',
            startDate: DateTime(2026, 11, 29),
            testTime: '09:20 입실완료 (09:50~12:10 시험)',
            checklist: ['규정 신분증', '연필 및 지우개', '아날로그 시계'],
          ),
          ExamStageItem(
            id: 'toeic-540-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2026, 12, 9),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '제541회 (2026.12.13)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'toeic-541-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 10, 26),
            endDate: DateTime(2026, 12, 7),
            testTime: '마감일 12:00까지',
          ),
          ExamStageItem(
            id: 'toeic-541-2',
            stageType: ExamStageType.writtenTest,
            name: '토익 정기시험일',
            startDate: DateTime(2026, 12, 13),
            testTime: '09:20 입실완료',
          ),
          ExamStageItem(
            id: 'toeic-541-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2026, 12, 23),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-toefl',
    groupCategory: '어학/상시',
    title: '토플 (TOEFL iBT)',
    description: 'ETS 주관 전 세계 인정 공인 영어능력평가 시험 (시험 4~8일 후 성적 확인)',
    colorHex: '#0284C7',
    type: ExamType.qualification,
    defaultChecklist: ['유효한 여권 (필수)', '등록 확인서', '간식 및 음료 (쉬는시간용)'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년 11월 정기시험 (2026.11.21)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'toefl-2611-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 11, 17),
            testTime: '정규등록 마감 (시험 4일전)',
          ),
          ExamStageItem(
            id: 'toefl-2611-2',
            stageType: ExamStageType.writtenTest,
            name: '토플 본시험 (센터/Home)',
            startDate: DateTime(2026, 11, 21),
            testTime: '08:30 입실완료 (09:00~11:00 시험)',
          ),
          ExamStageItem(
            id: 'toefl-2611-3',
            stageType: ExamStageType.writtenResult,
            name: '온라인 성적 발표일',
            startDate: DateTime(2026, 11, 27),
            testTime: '오전 중 ETS 계정 공시',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2026년 12월 정기시험 (2026.12.19)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'toefl-2612-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 12, 15),
          ),
          ExamStageItem(
            id: 'toefl-2612-2',
            stageType: ExamStageType.writtenTest,
            name: '토플 본시험',
            startDate: DateTime(2026, 12, 19),
            testTime: '08:30 입실완료',
          ),
          ExamStageItem(
            id: 'toefl-2612-3',
            stageType: ExamStageType.writtenResult,
            name: '온라인 성적 발표일',
            startDate: DateTime(2026, 12, 25),
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년 1월 정기시험 (2027.01.16)',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'toefl-2701-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 12, 1),
            endDate: DateTime(2027, 1, 12),
          ),
          ExamStageItem(
            id: 'toefl-2701-2',
            stageType: ExamStageType.writtenTest,
            name: '토플 본시험',
            startDate: DateTime(2027, 1, 16),
            testTime: '08:30 입실완료',
          ),
          ExamStageItem(
            id: 'toefl-2701-3',
            stageType: ExamStageType.writtenResult,
            name: '온라인 성적 발표일',
            startDate: DateTime(2027, 1, 22),
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-tos',
    groupCategory: '어학/상시',
    title: '토익스피킹 (TOEIC Speaking / 토스)',
    description: 'YBM 주관 공인 영어 말하기 시험 (주말 정기 시행, 시험 5일 후 성적 발표)',
    colorHex: '#0891B2',
    type: ExamType.qualification,
    defaultChecklist: ['규정 신분증 (주민등록증/운전면허증/여권)'],
    rounds: [
      OfficialExamRound(
        roundName: '11월 4주차 (2026.11.28 토)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'tos-2611-1',
            stageType: ExamStageType.application,
            name: '접수 마감 (시험 전날 23:00)',
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 11, 27),
          ),
          ExamStageItem(
            id: 'tos-2611-2',
            stageType: ExamStageType.writtenTest,
            name: '토익스피킹 시험일 (CBT 센터)',
            startDate: DateTime(2026, 11, 28),
            testTime: '11:30 또는 13:30 입실',
          ),
          ExamStageItem(
            id: 'tos-2611-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2026, 12, 3),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '12월 2주차 (2026.12.12 토)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'tos-2612-1',
            stageType: ExamStageType.application,
            name: '접수 마감',
            startDate: DateTime(2026, 11, 15),
            endDate: DateTime(2026, 12, 11),
          ),
          ExamStageItem(
            id: 'tos-2612-2',
            stageType: ExamStageType.writtenTest,
            name: '토익스피킹 시험일',
            startDate: DateTime(2026, 12, 12),
            testTime: '지정 입실시간 (약 20분간 시험)',
          ),
          ExamStageItem(
            id: 'tos-2612-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2026, 12, 17),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년 1월 2주차 (2027.01.09 토)',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'tos-2701-1',
            stageType: ExamStageType.application,
            name: '접수 마감',
            startDate: DateTime(2026, 12, 15),
            endDate: DateTime(2027, 1, 8),
          ),
          ExamStageItem(
            id: 'tos-2701-2',
            stageType: ExamStageType.writtenTest,
            name: '토익스피킹 시험일',
            startDate: DateTime(2027, 1, 9),
          ),
          ExamStageItem(
            id: 'tos-2701-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표일',
            startDate: DateTime(2027, 1, 14),
            testTime: '낮 12:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-opic',
    groupCategory: '어학/상시',
    title: '오픽 (OPIc 영어/외국어 말하기)',
    description: 'ACTFL 공인 영어 말하기 평가 (시험일 3~5일 후 빠른 성적 발표)',
    colorHex: '#059669',
    type: ExamType.qualification,
    defaultChecklist: ['규정 신분증 (필수 지참)'],
    rounds: [
      OfficialExamRound(
        roundName: '10월 정기 회차 (상시)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'opic-oct-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감 (시험 2일전)',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 10, 15),
          ),
          ExamStageItem(
            id: 'opic-oct-2',
            stageType: ExamStageType.writtenTest,
            name: '오픽 시험일 (센터)',
            startDate: DateTime(2026, 10, 17),
            testTime: '지정 시간 10분 전 입실',
          ),
          ExamStageItem(
            id: 'opic-oct-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표 (시험 5일 후)',
            startDate: DateTime(2026, 10, 22),
            testTime: '오후 13:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '11월 정기 회차 (상시)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'opic-nov-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 11, 12),
          ),
          ExamStageItem(
            id: 'opic-nov-2',
            stageType: ExamStageType.writtenTest,
            name: '오픽 시험일 (센터)',
            startDate: DateTime(2026, 11, 14),
            testTime: '지정 시간 10분 전 입실',
          ),
          ExamStageItem(
            id: 'opic-nov-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 발표',
            startDate: DateTime(2026, 11, 19),
            testTime: '오후 13:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-comhwal',
    groupCategory: '어학/상시',
    title: '컴퓨터활용능력 1급/2급 (대한상공회의소)',
    description: '상시 시험 개설 (필기 익일 발표, 실기 2주 뒤 금요일 발표)',
    colorHex: '#0284C7',
    type: ExamType.qualification,
    defaultChecklist: ['신분증', '수험표', '필기도구'],
    rounds: [
      OfficialExamRound(
        roundName: '2026 상시 1차 (필기/실기)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'com-1',
            stageType: ExamStageType.application,
            name: '필기 시험 접수 (시험 4일전 마감)',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 10, 16),
          ),
          ExamStageItem(
            id: 'com-2',
            stageType: ExamStageType.writtenTest,
            name: '컴활 필기 시험일 (CBT)',
            startDate: DateTime(2026, 10, 20),
            testTime: '지정 교시 입실',
          ),
          ExamStageItem(
            id: 'com-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격 발표 (익일 오전 10시)',
            startDate: DateTime(2026, 10, 21),
            testTime: '오전 10:00 발표',
          ),
          ExamStageItem(
            id: 'com-4',
            stageType: ExamStageType.practicalTest,
            name: '컴활 실기 시험일 (CBT)',
            startDate: DateTime(2026, 11, 15),
            testTime: '지정 교시 입실',
          ),
          ExamStageItem(
            id: 'com-5',
            stageType: ExamStageType.finalResult,
            name: '실기 최종합격 발표 (시험 2주 뒤 금요일)',
            startDate: DateTime(2026, 12, 4),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-history',
    groupCategory: '어학/상시',
    title: '한국사능력검정시험 (한능검)',
    description: '국사편찬위원회 주관 공인 자격 평가 (심화/기본)',
    colorHex: '#B45309',
    type: ExamType.qualification,
    defaultChecklist: ['수험표', '규정 신분증', '컴퓨터용 수성사인펜', '수정테이프'],
    rounds: [
      OfficialExamRound(
        roundName: '제74회 한능검 (2026.10.18)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'hist-74-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2026, 9, 8),
            endDate: DateTime(2026, 9, 15),
          ),
          ExamStageItem(
            id: 'hist-74-2',
            stageType: ExamStageType.writtenTest,
            name: '시험일 (심화/기본)',
            startDate: DateTime(2026, 10, 18),
            testTime: '10:00 입실완료 (10:20~11:40 시험)',
          ),
          ExamStageItem(
            id: 'hist-74-3',
            stageType: ExamStageType.writtenResult,
            name: '합격자 성적 발표일',
            startDate: DateTime(2026, 10, 30),
            testTime: '오전 10:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '제75회 한능검 (2026.12.06)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'hist-75-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2026, 11, 3),
            endDate: DateTime(2026, 11, 10),
            testTime: '마감일 18:00까지',
          ),
          ExamStageItem(
            id: 'hist-75-2',
            stageType: ExamStageType.writtenTest,
            name: '시험일 (심화/기본)',
            startDate: DateTime(2026, 12, 6),
            testTime: '10:00 입실완료 (10:20~11:40 시험)',
          ),
          ExamStageItem(
            id: 'hist-75-3',
            stageType: ExamStageType.writtenResult,
            name: '합격자 성적 발표일',
            startDate: DateTime(2026, 12, 18),
            testTime: '오전 10:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '제76회 한능검 (2027.02.14)',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'hist-76-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2027, 1, 12),
            endDate: DateTime(2027, 1, 19),
          ),
          ExamStageItem(
            id: 'hist-76-2',
            stageType: ExamStageType.writtenTest,
            name: '시험일 (심화/기본)',
            startDate: DateTime(2027, 2, 14),
            testTime: '10:00 입실완료',
          ),
          ExamStageItem(
            id: 'hist-76-3',
            stageType: ExamStageType.writtenResult,
            name: '합격자 성적 발표일',
            startDate: DateTime(2027, 2, 27),
            testTime: '오전 10:00 발표',
          ),
        ],
      ),
    ],
  ),

  // ==========================================
  // 2. 국가기술자격 (Q-Net 정기 기사/산업기사)
  // ==========================================
  OfficialExamPreset(
    id: 'preset-qnet-cs',
    groupCategory: '국가기술자격',
    title: '정보처리기사 (Q-Net 정기 기사)',
    description: '한국산업인력공단 정기 국가기술자격 5단계 풀 파이프라인',
    colorHex: '#4F46E5',
    type: ExamType.qualification,
    defaultChecklist: ['신분증', '수험표', '검정색 필기도구(볼펜)', '컴퓨터용 싸인펜', '수정테이프'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년 정기 기사 2회차',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'qnet-cs-2-1',
            stageType: ExamStageType.application,
            name: '필기 원서접수 마감',
            startDate: DateTime(2026, 4, 15),
            endDate: DateTime(2026, 4, 18),
            testTime: '마감일 18:00까지',
          ),
          ExamStageItem(
            id: 'qnet-cs-2-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험 (CBT)',
            startDate: DateTime(2026, 5, 10),
            testTime: '지정 입실시간 (CBT 시험)',
            location: '지정 CBT 시험장',
          ),
          ExamStageItem(
            id: 'qnet-cs-2-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격(예정)자 발표',
            startDate: DateTime(2026, 6, 10),
            testTime: '오전 09:00 Q-Net 공지',
          ),
          ExamStageItem(
            id: 'qnet-cs-2-4',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: DateTime(2026, 7, 26),
            testTime: '09:00 입실완료 (09:30~12:00 시험)',
            location: '지정 고사장',
            checklist: ['검정색 볼펜 (필수)', '신분증', '수험표'],
          ),
          ExamStageItem(
            id: 'qnet-cs-2-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 9, 4),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2026년 정기 기사 3회차',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'qnet-cs-3-1',
            stageType: ExamStageType.application,
            name: '필기 원서접수 마감',
            startDate: DateTime(2026, 6, 18),
            endDate: DateTime(2026, 6, 21),
            testTime: '마감일 18:00까지',
          ),
          ExamStageItem(
            id: 'qnet-cs-3-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험 (CBT)',
            startDate: DateTime(2026, 7, 12),
            testTime: '지정 입실시간 (CBT 시험)',
          ),
          ExamStageItem(
            id: 'qnet-cs-3-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격(예정)자 발표',
            startDate: DateTime(2026, 8, 12),
            testTime: '오전 09:00 발표',
          ),
          ExamStageItem(
            id: 'qnet-cs-3-4',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: DateTime(2026, 10, 18),
            testTime: '09:00 입실완료 (09:30~12:00 시험)',
            checklist: ['검정색 볼펜', '신분증', '수험표'],
          ),
          ExamStageItem(
            id: 'qnet-cs-3-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 12, 11),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년 정기 기사 1회차',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'qnet-cs-271-1',
            stageType: ExamStageType.application,
            name: '필기 원서접수 마감',
            startDate: DateTime(2027, 1, 18),
            endDate: DateTime(2027, 1, 21),
            testTime: '마감일 18:00까지',
          ),
          ExamStageItem(
            id: 'qnet-cs-271-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험 (CBT)',
            startDate: DateTime(2027, 2, 15),
            endDate: DateTime(2027, 3, 7),
            testTime: '지정 입실시간 (CBT 시험)',
          ),
          ExamStageItem(
            id: 'qnet-cs-271-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격(예정)자 발표',
            startDate: DateTime(2027, 3, 13),
            testTime: '오전 09:00 발표',
          ),
          ExamStageItem(
            id: 'qnet-cs-271-4',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: DateTime(2027, 4, 25),
            testTime: '09:00 입실완료 (09:30~12:00 시험)',
            checklist: ['검정색 볼펜', '신분증', '수험표'],
          ),
          ExamStageItem(
            id: 'qnet-cs-271-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2027, 6, 18),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-qnet-cs-ind',
    groupCategory: '국가기술자격',
    title: '정보처리산업기사 (Q-Net 정기 산업기사)',
    description: '한국산업인력공단 IT 개발 및 인프라 실무 국가기술자격 파이프라인',
    colorHex: '#3B82F6',
    type: ExamType.qualification,
    defaultChecklist: ['신분증', '수험표', '검정색 볼펜', '컴퓨터용 사인펜'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년 정기 산업기사 3회차',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'qnet-csind-3-1',
            stageType: ExamStageType.application,
            name: '실기 원서접수 마감',
            startDate: DateTime(2026, 9, 10),
            endDate: DateTime(2026, 9, 13),
          ),
          ExamStageItem(
            id: 'qnet-csind-3-2',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: DateTime(2026, 10, 19),
            testTime: '09:00 입실완료',
          ),
          ExamStageItem(
            id: 'qnet-csind-3-3',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 12, 11),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년 정기 산업기사 1회차',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'qnet-csind-271-1',
            stageType: ExamStageType.application,
            name: '필기 원서접수 마감',
            startDate: DateTime(2027, 1, 18),
            endDate: DateTime(2027, 1, 21),
          ),
          ExamStageItem(
            id: 'qnet-csind-271-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험 (CBT)',
            startDate: DateTime(2027, 2, 15),
            endDate: DateTime(2027, 3, 7),
          ),
          ExamStageItem(
            id: 'qnet-csind-271-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격자 발표',
            startDate: DateTime(2027, 3, 13),
          ),
          ExamStageItem(
            id: 'qnet-csind-271-4',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: DateTime(2027, 4, 25),
          ),
          ExamStageItem(
            id: 'qnet-csind-271-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2027, 6, 18),
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-realtor',
    groupCategory: '국가기술자격',
    title: '공인중개사 (한국산업인력공단)',
    description: '부동산 중개 전문자격증 1차/2차 동차 파이프라인 (연 1회 시행)',
    colorHex: '#047857',
    type: ExamType.qualification,
    defaultChecklist: ['수험표', '신분증', '컴퓨터용 싸인펜', '수정테이프', '단기 계산기'],
    rounds: [
      OfficialExamRound(
        roundName: '제37회 공인중개사 (2026년)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'realtor-37-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간 (동차/1차/2차)',
            startDate: DateTime(2026, 8, 10),
            endDate: DateTime(2026, 8, 14),
          ),
          ExamStageItem(
            id: 'realtor-37-2',
            stageType: ExamStageType.writtenTest,
            name: '1차 및 2차 본시험',
            startDate: DateTime(2026, 10, 31),
            testTime: '1차 09:00 입실 / 2차 12:30 입실',
          ),
          ExamStageItem(
            id: 'realtor-37-3',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 11, 30),
            testTime: '오전 09:00 Q-Net 공지',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '제38회 공인중개사 (2027년)',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'realtor-38-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2027, 8, 9),
            endDate: DateTime(2027, 8, 13),
          ),
          ExamStageItem(
            id: 'realtor-38-2',
            stageType: ExamStageType.writtenTest,
            name: '1차 및 2차 본시험',
            startDate: DateTime(2027, 10, 30),
            testTime: '1차 09:00 입실 / 2차 12:30 입실',
          ),
          ExamStageItem(
            id: 'realtor-38-3',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2027, 12, 1),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-qnet-elec',
    groupCategory: '국가기술자격',
    title: '전기기사 (Q-Net 정기 기사)',
    description: '한국산업인력공단 전기분야 핵심 국가기술자격',
    colorHex: '#D97706',
    type: ExamType.qualification,
    defaultChecklist: ['신분증', '수험표', '공학용 계산기(기종 확인)', '검정 볼펜'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년 정기 기사 3회차',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'qnet-el-3-1',
            stageType: ExamStageType.application,
            name: '필기 원서접수',
            startDate: DateTime(2026, 6, 18),
            endDate: DateTime(2026, 6, 21),
          ),
          ExamStageItem(
            id: 'qnet-el-3-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험 (CBT)',
            startDate: DateTime(2026, 7, 15),
            testTime: '지정 교시 입실',
          ),
          ExamStageItem(
            id: 'qnet-el-3-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격 발표',
            startDate: DateTime(2026, 8, 12),
          ),
          ExamStageItem(
            id: 'qnet-el-3-4',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: DateTime(2026, 10, 18),
            testTime: '09:00 입실완료',
            checklist: ['공학용 계산기', '신분증', '검정 볼펜'],
          ),
          ExamStageItem(
            id: 'qnet-el-3-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격 발표',
            startDate: DateTime(2026, 12, 11),
          ),
        ],
      ),
    ],
  ),

  // ==========================================
  // 3. 공무원 / 공기업 채용
  // ==========================================
  OfficialExamPreset(
    id: 'preset-gov-9',
    groupCategory: '공무원/공기업',
    title: '국가직 9급 공무원 공채',
    description: '인사혁신처 사이버국가고시센터 주관 공개경쟁채용시험',
    colorHex: '#0891B2',
    type: ExamType.qualification,
    defaultChecklist: ['응시표', '규정 신분증', '컴퓨터용 흑색 사인펜', '수정테이프'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년도 국가직 9급 공채',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'gov9-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2026, 1, 18),
            endDate: DateTime(2026, 1, 22),
            testTime: '마감일 21:00까지',
          ),
          ExamStageItem(
            id: 'gov9-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험일',
            startDate: DateTime(2026, 3, 28),
            testTime: '09:20 입실완료 (10:00~11:40 시험)',
            location: '지정 고사장',
          ),
          ExamStageItem(
            id: 'gov9-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격자 발표',
            startDate: DateTime(2026, 4, 25),
            testTime: '오전 09:00 사이버국가고시',
          ),
          ExamStageItem(
            id: 'gov9-4',
            stageType: ExamStageType.practicalTest,
            name: '면접 시험',
            startDate: DateTime(2026, 5, 28),
            endDate: DateTime(2026, 6, 2),
            testTime: '지정 조별 입실',
          ),
          ExamStageItem(
            id: 'gov9-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 6, 20),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년도 국가직 9급 공채',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'gov9-27-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2027, 1, 18),
            endDate: DateTime(2027, 1, 22),
            testTime: '마감일 21:00까지',
          ),
          ExamStageItem(
            id: 'gov9-27-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험일',
            startDate: DateTime(2027, 3, 27),
            testTime: '09:20 입실완료 (10:00~11:40 시험)',
          ),
          ExamStageItem(
            id: 'gov9-27-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격자 발표',
            startDate: DateTime(2027, 4, 23),
            testTime: '오전 09:00 사이버국가고시센터',
          ),
          ExamStageItem(
            id: 'gov9-27-4',
            stageType: ExamStageType.practicalTest,
            name: '면접 시험',
            startDate: DateTime(2027, 5, 28),
            endDate: DateTime(2027, 6, 2),
          ),
          ExamStageItem(
            id: 'gov9-27-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2027, 6, 18),
            testTime: '오전 09:00 발표',
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-local-9',
    groupCategory: '공무원/공기업',
    title: '지방직 9급 공무원 공채',
    description: '지자체별 지방공무원 공개경쟁임용 필기/면접 시험',
    colorHex: '#0D9488',
    type: ExamType.qualification,
    defaultChecklist: ['응시표', '규정 신분증', '컴퓨터용 사인펜', '수정테이프'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년도 지방직 9급 공채',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'loc9-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2026, 3, 25),
            endDate: DateTime(2026, 3, 29),
          ),
          ExamStageItem(
            id: 'loc9-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험일',
            startDate: DateTime(2026, 6, 20),
            testTime: '09:20 입실완료 (10:00~11:40 시험)',
          ),
          ExamStageItem(
            id: 'loc9-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격자 발표 (시·도별)',
            startDate: DateTime(2026, 7, 18),
          ),
          ExamStageItem(
            id: 'loc9-4',
            stageType: ExamStageType.practicalTest,
            name: '면접 시험',
            startDate: DateTime(2026, 8, 10),
            endDate: DateTime(2026, 8, 20),
          ),
          ExamStageItem(
            id: 'loc9-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 9, 10),
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년도 지방직 9급 공채',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'loc9-27-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2027, 3, 22),
            endDate: DateTime(2027, 3, 26),
          ),
          ExamStageItem(
            id: 'loc9-27-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험일',
            startDate: DateTime(2027, 6, 19),
            testTime: '09:20 입실완료 (10:00~11:40 시험)',
          ),
          ExamStageItem(
            id: 'loc9-27-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격자 발표',
            startDate: DateTime(2027, 7, 16),
          ),
          ExamStageItem(
            id: 'loc9-27-4',
            stageType: ExamStageType.practicalTest,
            name: '면접 시험',
            startDate: DateTime(2027, 8, 9),
            endDate: DateTime(2027, 8, 19),
          ),
          ExamStageItem(
            id: 'loc9-27-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2027, 9, 8),
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-public-corp',
    groupCategory: '공무원/공기업',
    title: '주요 공기업 채용 (NCS & 직무시험)',
    description: '공기업/공공기관 블라인드 채용 통합 5단계 (서류 -> NCS 필기 -> 전공 -> 면접 -> 최종)',
    colorHex: '#1D4ED8',
    type: ExamType.qualification,
    defaultChecklist: ['수험표', '규정 신분증', '컴퓨터용 사인펜', '수정테이프', '필기도구'],
    rounds: [
      OfficialExamRound(
        roundName: '2026년 하반기 통합 공채',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'pubcorp-26h-1',
            stageType: ExamStageType.application,
            name: '입사지원서 접수 마감',
            startDate: DateTime(2026, 10, 15),
            endDate: DateTime(2026, 10, 28),
            testTime: '마감일 17:00까지',
          ),
          ExamStageItem(
            id: 'pubcorp-26h-2',
            stageType: ExamStageType.writtenTest,
            name: 'NCS 직업기초능력 & 전공 필기시험',
            startDate: DateTime(2026, 11, 21),
            testTime: '09:30 입실완료 (10:00~12:00 필기)',
          ),
          ExamStageItem(
            id: 'pubcorp-26h-3',
            stageType: ExamStageType.writtenResult,
            name: '필기시험 합격자 발표',
            startDate: DateTime(2026, 11, 27),
            testTime: '17:00 채용 홈페이지',
          ),
          ExamStageItem(
            id: 'pubcorp-26h-4',
            stageType: ExamStageType.practicalTest,
            name: '직무/인성 면접 전형',
            startDate: DateTime(2026, 12, 7),
            endDate: DateTime(2026, 12, 11),
          ),
          ExamStageItem(
            id: 'pubcorp-26h-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2026, 12, 24),
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2027년 상반기 통합 공채',
        year: 2027,
        stages: [
          ExamStageItem(
            id: 'pubcorp-27s-1',
            stageType: ExamStageType.application,
            name: '입사지원서 접수 마감',
            startDate: DateTime(2027, 3, 10),
            endDate: DateTime(2027, 3, 24),
          ),
          ExamStageItem(
            id: 'pubcorp-27s-2',
            stageType: ExamStageType.writtenTest,
            name: 'NCS & 전공 필기시험',
            startDate: DateTime(2027, 4, 17),
            testTime: '09:30 입실완료',
          ),
          ExamStageItem(
            id: 'pubcorp-27s-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격 발표',
            startDate: DateTime(2027, 4, 23),
          ),
          ExamStageItem(
            id: 'pubcorp-27s-4',
            stageType: ExamStageType.practicalTest,
            name: '면접 전형',
            startDate: DateTime(2027, 5, 10),
            endDate: DateTime(2027, 5, 14),
          ),
          ExamStageItem(
            id: 'pubcorp-27s-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: DateTime(2027, 5, 28),
          ),
        ],
      ),
    ],
  ),

  // ==========================================
  // 4. 입시 / 수능 및 전국 모의고사
  // ==========================================
  OfficialExamPreset(
    id: 'preset-suneung',
    groupCategory: '입시/수능',
    title: '2027학년도 대학수학능력시험 (수능)',
    description: '한국교육과정평가원 주관 2027학년도 대입 수능 (11월 셋째 주 목요일)',
    colorHex: '#DC2626',
    type: ExamType.qualification,
    defaultChecklist: ['수험표', '신분증', '컴퓨터용 사인펜', '수정테이프', '샤프심(0.5mm)', '도시락/물'],
    rounds: [
      OfficialExamRound(
        roundName: '2027학년도 수능 본시험',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'sun-1',
            stageType: ExamStageType.application,
            name: '수능 응시원서 접수',
            startDate: DateTime(2026, 8, 20),
            endDate: DateTime(2026, 9, 4),
            testTime: '09:00 ~ 17:00 출신고/교육청',
          ),
          ExamStageItem(
            id: 'sun-2',
            stageType: ExamStageType.writtenTest,
            name: '수능 시험일 (D-Day)',
            startDate: DateTime(2026, 11, 19),
            testTime: '08:10까지 입실완료 (08:40~17:45 시험)',
            location: '지정 시험장 학교',
            checklist: ['수험표', '신분증', '도시락', '아날로그 시계'],
          ),
          ExamStageItem(
            id: 'sun-3',
            stageType: ExamStageType.writtenResult,
            name: '수능 성적 통지일',
            startDate: DateTime(2026, 12, 8),
            testTime: '오전 09:00 성적표 배부',
          ),
        ],
      ),
      OfficialExamRound(
        roundName: '2026년 9월 평가원 모의평가',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'mock9-1',
            stageType: ExamStageType.application,
            name: '원서 접수 기간',
            startDate: DateTime(2026, 6, 22),
            endDate: DateTime(2026, 7, 2),
          ),
          ExamStageItem(
            id: 'mock9-2',
            stageType: ExamStageType.writtenTest,
            name: '9월 모의평가 시험일',
            startDate: DateTime(2026, 9, 2),
            testTime: '08:10 입실완료',
          ),
          ExamStageItem(
            id: 'mock9-3',
            stageType: ExamStageType.writtenResult,
            name: '성적 통지일',
            startDate: DateTime(2026, 9, 30),
          ),
        ],
      ),
    ],
  ),

  // ==========================================
  // 5. 학교 시험 프리셋 (중간고사 / 기말고사)
  // ==========================================
  OfficialExamPreset(
    id: 'preset-school-midterm',
    groupCategory: '학교시험',
    title: '2학기 중간고사 (타임테이블 템플릿)',
    description: '중·고·대학교 중간고사 과목별 날짜 & 교시 타임테이블',
    colorHex: '#7C3AED',
    type: ExamType.midterm,
    defaultChecklist: ['학생증/신분증', '컴퓨터용 싸인펜', '수정테이프', '계산기', '필기도구'],
    rounds: [
      OfficialExamRound(
        roundName: '2학기 중간고사 (3일간)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'mid-1',
            stageType: ExamStageType.writtenTest,
            name: '중간고사 시작일 (Day 1)',
            startDate: DateTime(2026, 10, 19),
            testTime: '1교시 09:00 시작',
          ),
          ExamStageItem(
            id: 'mid-2',
            stageType: ExamStageType.writtenResult,
            name: '시험 종료 및 성적 확인',
            startDate: DateTime(2026, 10, 23),
          ),
        ],
      ),
    ],
  ),

  OfficialExamPreset(
    id: 'preset-school-final',
    groupCategory: '학교시험',
    title: '2학기 기말고사 (타임테이블 템플릿)',
    description: '학기말 총정리 기말고사 과목별 타임테이블',
    colorHex: '#9333EA',
    type: ExamType.finalExam,
    defaultChecklist: ['학생증/신분증', '컴퓨터용 싸인펜', '수정테이프', '필기도구'],
    rounds: [
      OfficialExamRound(
        roundName: '2학기 기말고사 (4일간)',
        year: 2026,
        stages: [
          ExamStageItem(
            id: 'fin-1',
            stageType: ExamStageType.writtenTest,
            name: '기말고사 시작일 (Day 1)',
            startDate: DateTime(2026, 12, 14),
            testTime: '1교시 09:00 시작',
          ),
          ExamStageItem(
            id: 'fin-2',
            stageType: ExamStageType.writtenResult,
            name: '종강 및 성적 공시',
            startDate: DateTime(2026, 12, 24),
          ),
        ],
      ),
    ],
  ),
];
