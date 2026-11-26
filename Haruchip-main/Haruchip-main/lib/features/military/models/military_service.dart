import 'package:flutter/foundation.dart';

import 'military_rank.dart';

/// 군 출타 4대 분류 + 직접입력
enum MilitaryLeaveType {
  regular, // 정기휴가
  reward, // 포상휴가
  overnight, // 외박
  outing, // 외출
  custom; // 직접입력

  String get labelKo => switch (this) {
        MilitaryLeaveType.regular => '정기휴가',
        MilitaryLeaveType.reward => '포상휴가',
        MilitaryLeaveType.overnight => '외박',
        MilitaryLeaveType.outing => '외출',
        MilitaryLeaveType.custom => '직접입력',
      };

  String get emoji => switch (this) {
        MilitaryLeaveType.regular => '🌴',
        MilitaryLeaveType.reward => '🏅',
        MilitaryLeaveType.overnight => '🌙',
        MilitaryLeaveType.outing => '🚶',
        MilitaryLeaveType.custom => '📅',
      };

  static MilitaryLeaveType fromName(String? raw) {
    return MilitaryLeaveType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => MilitaryLeaveType.regular,
    );
  }
}

/// 개별 휴가·외박·외출·면회 일정 모델
@immutable
class MilitaryLeaveRecord {
  const MilitaryLeaveRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.memo,
  });

  final String id;
  final MilitaryLeaveType type;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? memo;

  /// 총 사용 일수 (당일 = 1일, 연속 = 종료일 - 시작일 + 1)
  int get daysCount {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = e.difference(s).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  bool get isSingleDay => daysCount <= 1;

  /// 예: '정기휴가 5일' 또는 '외출 1일'
  String get summaryLabel => '$title $daysCount일';

  MilitaryLeaveRecord copyWith({
    String? id,
    MilitaryLeaveType? type,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return MilitaryLeaveRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (memo != null && memo!.isNotEmpty) 'memo': memo,
      };

  factory MilitaryLeaveRecord.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['startDate'] as String);
    final end = json['endDate'] != null
        ? DateTime.parse(json['endDate'] as String)
        : start;
    return MilitaryLeaveRecord(
      id: json['id'] as String? ?? '',
      type: MilitaryLeaveType.fromName(json['type'] as String?),
      title: json['title'] as String? ?? '휴가',
      startDate: start,
      endDate: end,
      memo: json['memo'] as String?,
    );
  }
}

/// 군대 카테고리 기본 섹션 순서 (복무 지표 · 진급 타임라인 · 출타 관리 · D-Day 리스트)
const List<String> kDefaultMilitarySectionOrder = [
  'metrics',
  'timeline',
  'leaves',
  'ddayList',
];

/// 군대(곰신) 카테고리 도메인 모델 — 핸드오프 문서 §5.3 + 출타/곰신 공유/커스텀 진급일/섹션 편집 확장
@immutable
class MilitaryService {
  const MilitaryService({
    required this.enlistDate,
    required this.dischargeDate,
    this.branch = MilitaryBranch.army,
    this.nextLeaveDate,
    this.totalVacationDays = 24,
    this.usedVacationDays = 0,
    this.soldierName = '우리 군인',
    this.shortenedDays = 0,
    this.totalRewardVacationDays = 10,
    this.leaves = const [],
    this.shareCode,
    this.connectedPartnerCode,
    this.customNextHobongDate,
    this.customNextRankDate,
    this.sectionOrder = kDefaultMilitarySectionOrder,
    this.hiddenSections = const {},
  });

  final DateTime enlistDate;
  final DateTime dischargeDate;
  final MilitaryBranch branch;
  final DateTime? nextLeaveDate;

  /// 총 부여받은 정기휴가 일수
  final int totalVacationDays;

  /// 수동 입력 사용 휴가 일수 (하위 호환 유지)
  final int usedVacationDays;

  /// 군인 닉네임
  final String soldierName;

  /// 단축일수 (조기전역/복무단축 등)
  final int shortenedDays;

  /// 총 부여받은 포상휴가 일수
  final int totalRewardVacationDays;

  /// 등록된 출타(정기휴가·포상휴가·외박·외출·직접입력) 목록
  final List<MilitaryLeaveRecord> leaves;

  /// 내 곰신-군인 공유 초대 코드 (난수 생성)
  final String? shareCode;

  /// 연결된 상대방 공유 방 코드
  final String? connectedPartnerCode;

  /// 사용자가 직접 수정한 다음 호봉 승급일 (null이면 자동 매월 1일 계산)
  final DateTime? customNextHobongDate;

  /// 사용자가 직접 수정한 다음 계급 진급일 (null이면 입대일 기준 규정 자동 계산)
  final DateTime? customNextRankDate;

  /// 군대 상세 화면 섹션 노출 순서 ('metrics', 'timeline', 'leaves', 'ddayList')
  final List<String> sectionOrder;

  /// 군대 상세 화면에서 숨김 처리된 섹션 키 집합
  final Set<String> hiddenSections;

  /// 단축일수가 반영된 실 전역일
  DateTime get effectiveDischargeDate =>
      shortenedDays > 0 ? dischargeDate.subtract(Duration(days: shortenedDays)) : dischargeDate;

  /// 정기휴가 사용 일수 합계
  int get usedRegularLeaveDays {
    final fromLeaves = leaves
        .where((l) => l.type == MilitaryLeaveType.regular)
        .fold<int>(0, (sum, l) => sum + l.daysCount);
    return fromLeaves > 0 ? fromLeaves : usedVacationDays;
  }

  /// 남은 정기휴가 일수
  int get remainingVacationDays =>
      (totalVacationDays - usedRegularLeaveDays).clamp(0, 999);

  /// 포상휴가 사용 일수 합계
  int get usedRewardLeaveDays => leaves
      .where((l) => l.type == MilitaryLeaveType.reward)
      .fold<int>(0, (sum, l) => sum + l.daysCount);

  /// 남은 포상휴가 일수
  int get remainingRewardVacationDays =>
      (totalRewardVacationDays - usedRewardLeaveDays).clamp(0, 999);

  /// 외박/외출 등록 횟수
  int get overnightAndOutingCount => leaves
      .where((l) =>
          l.type == MilitaryLeaveType.overnight ||
          l.type == MilitaryLeaveType.outing)
      .length;

  MilitaryService copyWith({
    DateTime? enlistDate,
    DateTime? dischargeDate,
    MilitaryBranch? branch,
    DateTime? nextLeaveDate,
    bool clearNextLeaveDate = false,
    int? totalVacationDays,
    int? usedVacationDays,
    String? soldierName,
    int? shortenedDays,
    int? totalRewardVacationDays,
    List<MilitaryLeaveRecord>? leaves,
    String? shareCode,
    String? connectedPartnerCode,
    bool clearConnectedPartnerCode = false,
    DateTime? customNextHobongDate,
    bool clearCustomNextHobongDate = false,
    DateTime? customNextRankDate,
    bool clearCustomNextRankDate = false,
    List<String>? sectionOrder,
    Set<String>? hiddenSections,
  }) {
    return MilitaryService(
      enlistDate: enlistDate ?? this.enlistDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      branch: branch ?? this.branch,
      nextLeaveDate:
          clearNextLeaveDate ? null : (nextLeaveDate ?? this.nextLeaveDate),
      totalVacationDays: totalVacationDays ?? this.totalVacationDays,
      usedVacationDays: usedVacationDays ?? this.usedVacationDays,
      soldierName: soldierName ?? this.soldierName,
      shortenedDays: shortenedDays ?? this.shortenedDays,
      totalRewardVacationDays:
          totalRewardVacationDays ?? this.totalRewardVacationDays,
      leaves: leaves ?? this.leaves,
      shareCode: shareCode ?? this.shareCode,
      connectedPartnerCode: clearConnectedPartnerCode
          ? null
          : (connectedPartnerCode ?? this.connectedPartnerCode),
      customNextHobongDate: clearCustomNextHobongDate
          ? null
          : (customNextHobongDate ?? this.customNextHobongDate),
      customNextRankDate: clearCustomNextRankDate
          ? null
          : (customNextRankDate ?? this.customNextRankDate),
      sectionOrder: sectionOrder ?? this.sectionOrder,
      hiddenSections: hiddenSections ?? this.hiddenSections,
    );
  }

  Map<String, dynamic> toJson() => {
        'enlistDate': enlistDate.toIso8601String(),
        'dischargeDate': dischargeDate.toIso8601String(),
        'branch': branch.name,
        if (nextLeaveDate != null)
          'nextLeaveDate': nextLeaveDate!.toIso8601String(),
        'totalVacationDays': totalVacationDays,
        'usedVacationDays': usedVacationDays,
        'soldierName': soldierName,
        'shortenedDays': shortenedDays,
        'totalRewardVacationDays': totalRewardVacationDays,
        'leaves': leaves.map((l) => l.toJson()).toList(),
        if (shareCode != null) 'shareCode': shareCode,
        if (connectedPartnerCode != null)
          'connectedPartnerCode': connectedPartnerCode,
        if (customNextHobongDate != null)
          'customNextHobongDate': customNextHobongDate!.toIso8601String(),
        if (customNextRankDate != null)
          'customNextRankDate': customNextRankDate!.toIso8601String(),
        'sectionOrder': sectionOrder,
        'hiddenSections': hiddenSections.toList(),
      };

  factory MilitaryService.fromJson(Map<String, dynamic> json) {
    final rawOrder = (json['sectionOrder'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .where((k) => kDefaultMilitarySectionOrder.contains(k))
        .toList();
    final mergedOrder = <String>[
      ...?rawOrder,
      for (final k in kDefaultMilitarySectionOrder)
        if (rawOrder == null || !rawOrder.contains(k)) k,
    ];
    final rawHidden = (json['hiddenSections'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return MilitaryService(
      enlistDate: DateTime.parse(json['enlistDate'] as String),
      dischargeDate: DateTime.parse(json['dischargeDate'] as String),
      branch: MilitaryBranch.fromName(json['branch'] as String?),
      nextLeaveDate: json['nextLeaveDate'] != null
          ? DateTime.parse(json['nextLeaveDate'] as String)
          : null,
      totalVacationDays: json['totalVacationDays'] as int? ?? 24,
      usedVacationDays: json['usedVacationDays'] as int? ?? 0,
      soldierName: json['soldierName'] as String? ?? '우리 군인',
      shortenedDays: json['shortenedDays'] as int? ?? 0,
      totalRewardVacationDays: json['totalRewardVacationDays'] as int? ?? 10,
      leaves: (json['leaves'] as List<dynamic>?)
              ?.map((e) => MilitaryLeaveRecord.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      shareCode: json['shareCode'] as String?,
      connectedPartnerCode: json['connectedPartnerCode'] as String?,
      customNextHobongDate: json['customNextHobongDate'] != null
          ? DateTime.parse(json['customNextHobongDate'] as String)
          : null,
      customNextRankDate: json['customNextRankDate'] != null
          ? DateTime.parse(json['customNextRankDate'] as String)
          : null,
      sectionOrder: mergedOrder,
      hiddenSections: rawHidden,
    );
  }
}
