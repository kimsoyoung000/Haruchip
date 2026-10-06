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
