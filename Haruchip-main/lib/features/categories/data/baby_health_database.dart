import '../models/baby_profile.dart';

/// 질병관리청(KCDCA) 영유아 국가 필수 예방접종 표준 리스트 (0개월 ~ 만 12세)
const List<VaccineDose> kDefaultVaccineDoses = [
  // 0개월 (생후 4주 이내)
  VaccineDose(
    id: 'vac-bcg-1',
    name: 'BCG (결핵)',
    disease: '결핵',
    recommendedAgeMonths: 0,
    recommendedAgeLabel: '생후 4주 이내',
    memo: '피내용 또는 경피용 1회 접종',
  ),
  VaccineDose(
    id: 'vac-hepb-1',
    name: 'B형간염 1차',
    disease: 'B형간염',
    recommendedAgeMonths: 0,
    recommendedAgeLabel: '출생 시 (0개월)',
    memo: '출생 직후 24시간 이내 1차 접종',
  ),

  // 1개월
  VaccineDose(
    id: 'vac-hepb-2',
    name: 'B형간염 2차',
    disease: 'B형간염',
    recommendedAgeMonths: 1,
    recommendedAgeLabel: '생후 1개월',
    memo: '1차 접종 후 1개월 뒤',
  ),

  // 2개월
  VaccineDose(
    id: 'vac-dtap-1',
    name: 'DTaP 1차',
    disease: '디프테리아/파상풍/백일해',
    recommendedAgeMonths: 2,
    recommendedAgeLabel: '생후 2개월',
    memo: '콤보백신(5가/6가) 가능',
  ),
  VaccineDose(
    id: 'vac-ipv-1',
    name: 'IPV(폴리오) 1차',
    disease: '소아마비',
    recommendedAgeMonths: 2,
    recommendedAgeLabel: '생후 2개월',
    memo: '소아마비 예방',
  ),
  VaccineDose(
    id: 'vac-hib-1',
    name: 'Hib(뇌수막염) 1차',
    disease: 'b형헤모필루스인플루엔자',
    recommendedAgeMonths: 2,
    recommendedAgeLabel: '생후 2개월',
    memo: '뇌수막염 예방',
  ),
  VaccineDose(
    id: 'vac-pcv-1',
    name: 'PCV(폐렴구균) 1차',
    disease: '폐렴구균',
    recommendedAgeMonths: 2,
    recommendedAgeLabel: '생후 2개월',
    memo: '단백접합 백신 13가/15가',
  ),
  VaccineDose(
    id: 'vac-rota-1',
    name: '로타바이러스 1차',
    disease: '로타장염',
    recommendedAgeMonths: 2,
    recommendedAgeLabel: '생후 2개월',
    memo: '경구 투여 (로타릭스 2회/로타텍 3회)',
  ),

  // 4개월
  VaccineDose(
    id: 'vac-dtap-2',
    name: 'DTaP 2차',
    disease: '디프테리아/파상풍/백일해',
    recommendedAgeMonths: 4,
    recommendedAgeLabel: '생후 4개월',
    memo: '2차 접종',
  ),
  VaccineDose(
    id: 'vac-ipv-2',
    name: 'IPV(폴리오) 2차',
    disease: '소아마비',
    recommendedAgeMonths: 4,
    recommendedAgeLabel: '생후 4개월',
    memo: '2차 접종',
  ),
  VaccineDose(
    id: 'vac-hib-2',
    name: 'Hib(뇌수막염) 2차',
    disease: 'b형헤모필루스인플루엔자',
    recommendedAgeMonths: 4,
    recommendedAgeLabel: '생후 4개월',
    memo: '2차 접종',
  ),
  VaccineDose(
    id: 'vac-pcv-2',
    name: 'PCV(폐렴구균) 2차',
    disease: '폐렴구균',
    recommendedAgeMonths: 4,
    recommendedAgeLabel: '생후 4개월',
    memo: '2차 접종',
  ),
  VaccineDose(
    id: 'vac-rota-2',
    name: '로타바이러스 2차',
    disease: '로타장염',
    recommendedAgeMonths: 4,
    recommendedAgeLabel: '생후 4개월',
    memo: '경구 투여 2차',
  ),

  // 6개월
  VaccineDose(
    id: 'vac-hepb-3',
    name: 'B형간염 3차',
    disease: 'B형간염',
    recommendedAgeMonths: 6,
    recommendedAgeLabel: '생후 6개월',
    memo: '3차 접종 완료',
  ),
  VaccineDose(
    id: 'vac-dtap-3',
    name: 'DTaP 3차',
    disease: '디프테리아/파상풍/백일해',
    recommendedAgeMonths: 6,
    recommendedAgeLabel: '생후 6개월',
    memo: '3차 접종',
  ),
  VaccineDose(
    id: 'vac-ipv-3',
    name: 'IPV(폴리오) 3차',
    disease: '소아마비',
    recommendedAgeMonths: 6,
    recommendedAgeLabel: '생후 6개월',
    memo: '3차 접종',
  ),
  VaccineDose(
    id: 'vac-hib-3',
    name: 'Hib(뇌수막염) 3차',
    disease: 'b형헤모필루스인플루엔자',
    recommendedAgeMonths: 6,
    recommendedAgeLabel: '생후 6개월',
    memo: '3차 접종',
  ),
  VaccineDose(
    id: 'vac-pcv-3',
    name: 'PCV(폐렴구균) 3차',
    disease: '폐렴구균',
    recommendedAgeMonths: 6,
    recommendedAgeLabel: '생후 6개월',
    memo: '3차 접종',
  ),
  VaccineDose(
    id: 'vac-flu-1',
    name: '인플루엔자(독감) 1차',
    disease: '독감',
    recommendedAgeMonths: 6,
    recommendedAgeLabel: '생후 6개월 이후 (매년 가을)',
    memo: '첫해 4주 간격 2회 접종 후 매년 1회',
  ),

  // 12~15개월
  VaccineDose(
    id: 'vac-mmr-1',
    name: 'MMR 1차',
    disease: '홍역/유행성이하선염/풍진',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '생후 12~15개월',
    memo: '1차 접종',
  ),
  VaccineDose(
    id: 'vac-var-1',
    name: '수두 1차',
    disease: '수두',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '생후 12~15개월',
    memo: '1회 접종',
  ),
  VaccineDose(
    id: 'vac-hepa-1',
    name: 'A형간염 1차',
    disease: 'A형간염',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '생후 12~23개월',
    memo: '1차 접종 (6~12개월 후 2차)',
  ),
  VaccineDose(
    id: 'vac-je-1',
    name: '일본뇌염(사백신) 1차',
    disease: '일본뇌염',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '생후 12~23개월',
    memo: '1차 접종 (1주일 후 2차)',
  ),
  VaccineDose(
    id: 'vac-pcv-4',
    name: 'PCV(폐렴구균) 4차',
    disease: '폐렴구균',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '생후 12~15개월',
    memo: '4차 추가 접종',
  ),
  VaccineDose(
    id: 'vac-hib-4',
    name: 'Hib(뇌수막염) 4차',
    disease: 'b형헤모필루스인플루엔자',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '생후 12~15개월',
    memo: '4차 추가 접종',
  ),

  // 15~18개월
  VaccineDose(
    id: 'vac-dtap-4',
    name: 'DTaP 4차',
    disease: '디프테리아/파상풍/백일해',
    recommendedAgeMonths: 15,
    recommendedAgeLabel: '생후 15~18개월',
    memo: '4차 추가 접종',
  ),
  VaccineDose(
    id: 'vac-je-2',
    name: '일본뇌염(사백신) 2차',
    disease: '일본뇌염',
    recommendedAgeMonths: 12,
    recommendedAgeLabel: '1차 후 1~4주 뒤',
    memo: '2차 접종',
  ),

  // 24~36개월
  VaccineDose(
    id: 'vac-hepa-2',
    name: 'A형간염 2차',
    disease: 'A형간염',
    recommendedAgeMonths: 24,
    recommendedAgeLabel: '1차 후 6~18개월 뒤',
    memo: '2차 접종 완료',
  ),
  VaccineDose(
    id: 'vac-je-3',
    name: '일본뇌염(사백신) 3차',
    disease: '일본뇌염',
    recommendedAgeMonths: 24,
    recommendedAgeLabel: '2차 후 1년 뒤',
    memo: '3차 접종',
  ),

  // 만 4~6세
  VaccineDose(
    id: 'vac-dtap-5',
    name: 'DTaP 5차',
    disease: '디프테리아/파상풍/백일해',
    recommendedAgeMonths: 48,
    recommendedAgeLabel: '만 4~6세',
    memo: '5차 추가 접종',
  ),
  VaccineDose(
    id: 'vac-ipv-4',
    name: 'IPV(폴리오) 4차',
    disease: '소아마비',
    recommendedAgeMonths: 48,
    recommendedAgeLabel: '만 4~6세',
    memo: '4차 추가 접종',
  ),
  VaccineDose(
    id: 'vac-mmr-2',
    name: 'MMR 2차',
    disease: '홍역/유행성이하선염/풍진',
    recommendedAgeMonths: 48,
    recommendedAgeLabel: '만 4~6세',
    memo: '2차 접종 완료',
  ),
  VaccineDose(
    id: 'vac-je-4',
    name: '일본뇌염(사백신) 4차',
    disease: '일본뇌염',
    recommendedAgeMonths: 72,
    recommendedAgeLabel: '만 6세',
    memo: '4차 추가 접종',
  ),

  // 만 11~12세
  VaccineDose(
    id: 'vac-tdap-6',
    name: 'Tdap 6차',
    disease: '파상풍/디프테리아/백일해',
    recommendedAgeMonths: 132,
    recommendedAgeLabel: '만 11~12세',
    memo: '6차 추가 접종 (이후 10년마다 Td)',
  ),
  VaccineDose(
    id: 'vac-je-5',
    name: '일본뇌염(사백신) 5차',
    disease: '일본뇌염',
    recommendedAgeMonths: 144,
    recommendedAgeLabel: '만 12세',
    memo: '5차 접종 완료',
  ),
];

/// 국민건강보험공단 영유아 건강검진 1~8차 표준 리스트
const List<HealthCheckupDose> kDefaultHealthCheckupDoses = [
  HealthCheckupDose(
    stage: 1,
    name: '1차 영유아 건강검진',
    startDays: 14,
    endDays: 35,
    periodLabel: '생후 14일 ~ 35일',
    memo: '신체 계측, 수유 및 영양, 돌연사 증후군 예방 교육',
  ),
  HealthCheckupDose(
    stage: 2,
    name: '2차 영유아 건강검진',
    startDays: 120, // 4개월
    endDays: 209, // 6개월
    periodLabel: '생후 4개월 ~ 6개월',
    memo: '신체 계측, 발달 선별검사, 수면/이유식 교육',
  ),
  HealthCheckupDose(
    stage: 3,
    name: '3차 영유아 건강검진',
    startDays: 270, // 9개월
    endDays: 394, // 12개월
    periodLabel: '생후 9개월 ~ 12개월',
    memo: '신체 계측, 구강검진(선택), 발달 평가',
  ),
  HealthCheckupDose(
    stage: 4,
    name: '4차 영유아 건강검진 (구강 1차 포함)',
    startDays: 540, // 18개월
    endDays: 759, // 24개월
    periodLabel: '생후 18개월 ~ 24개월',
    memo: '대근육/소근육 발달, 언어 발달, 치아 우식증 예방',
  ),
  HealthCheckupDose(
    stage: 5,
    name: '5차 영유아 건강검진 (구강 2차 포함)',
    startDays: 900, // 30개월
    endDays: 1124, // 36개월
    periodLabel: '생후 30개월 ~ 36개월',
    memo: '인지 및 언어 평가, 정서/사회성 발달 검진',
  ),
  HealthCheckupDose(
    stage: 6,
    name: '6차 영유아 건강검진 (구강 3차 포함)',
    startDays: 1260, // 42개월
    endDays: 1489, // 48개월
    periodLabel: '생후 42개월 ~ 48개월',
    memo: '시력 선별 검사, 안전사고 예방 교육',
  ),
  HealthCheckupDose(
    stage: 7,
    name: '7차 영유아 건강검진',
    startDays: 1620, // 54개월
    endDays: 1854, // 60개월
    periodLabel: '생후 54개월 ~ 60개월',
    memo: '학령전기 성장/발달 심층 종합 평가',
  ),
  HealthCheckupDose(
    stage: 8,
    name: '8차 영유아 건강검진',
    startDays: 1980, // 66개월
    endDays: 2189, // 71개월
    periodLabel: '생후 66개월 ~ 71개월',
    memo: '초등학교 입학 전 최종 성장 발달 점검',
  ),
];

/// 성장 마일스톤 기념일 목록
const List<({int days, String label, String description})> kBabyGrowthMilestones = [
  (days: 50, label: '50일', description: '50일 기념 홈스냅 & 터미타임 연습'),
  (days: 100, label: '100일', description: '백일잔치, 100일 떡, 스튜디오 백일 사진'),
  (days: 200, label: '200일', description: '200일 기념 케이크 & 이유식 중기 시작'),
  (days: 300, label: '300일', description: '300일 기념 & 잡고 서기 연습'),
  (days: 365, label: '첫돌 (1년)', description: '첫돌 잔치, 돌잡이, 돌반지, 돌스냅'),
  (days: 730, label: '두돌 (2년)', description: '두돌 생일 축하 & 언어 폭발기'),
  (days: 1095, label: '세돌 (3년)', description: '세돌 생일 & 어린이집 적응'),
];
