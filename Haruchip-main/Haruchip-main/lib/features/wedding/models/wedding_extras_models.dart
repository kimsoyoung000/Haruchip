import 'package:flutter/foundation.dart';

/// 결혼 준비 카테고리 기본 3대 메인 섹션 순서
/// (본식 후 정산·답례는 웨딩 예산·지출표 내부로 완전 통합)
const List<String> kDefaultWeddingSectionOrder = [
  'checklist',
  'invitationMeetings',
  'budget',
];

/// 청첩장 모임 소속 구분 (신랑 지인 / 신부 지인 / 공동)
enum GuestAffiliation {
  groom('신랑 지인'),
  bride('신부 지인'),
  joint('공동');

  const GuestAffiliation(this.labelKo);
  final String labelKo;

  static GuestAffiliation fromName(String? raw) {
    return GuestAffiliation.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => GuestAffiliation.joint,
    );
  }
}

/// 청첩장 모임(청모) 개별 기록 모델
@immutable
class WeddingInvitationMeeting {
  const WeddingInvitationMeeting({
    required this.id,
    required this.title,
    this.meetingDate,
    this.location = '',
    this.affiliation = GuestAffiliation.joint,
    this.attendeeCount = 4,
    this.mealCostPerPerson = 50000,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final DateTime? meetingDate;
  final String location;
  final GuestAffiliation affiliation;
  final int attendeeCount;
  final int mealCostPerPerson;
  final bool isCompleted;

  int get estimatedTotalCost => attendeeCount * mealCostPerPerson;

  /// 청모 타일 우측 표기 규격: '2026.11.29(일) · D-3' 또는 '미정'
  String formattedDateWithWeekdayAndDday({DateTime? relativeNow}) {
    if (meetingDate == null) return '미정';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final now = relativeNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(meetingDate!.year, meetingDate!.month, meetingDate!.day);
    final wd = weekdays[(d.weekday - 1).clamp(0, 6)];
    final dateStr =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}($wd)';
    final diff = d.difference(today).inDays;
    final dday =
        diff == 0 ? 'D-Day' : (diff > 0 ? 'D-$diff' : 'D+${diff.abs()}');
    return '$dateStr · $dday';
  }

  WeddingInvitationMeeting copyWith({
    String? id,
    String? title,
    DateTime? meetingDate,
    bool clearMeetingDate = false,
    String? location,
    GuestAffiliation? affiliation,
    int? attendeeCount,
    int? mealCostPerPerson,
    bool? isCompleted,
  }) {
    return WeddingInvitationMeeting(
      id: id ?? this.id,
      title: title ?? this.title,
      meetingDate:
          clearMeetingDate ? null : (meetingDate ?? this.meetingDate),
      location: location ?? this.location,
      affiliation: affiliation ?? this.affiliation,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      mealCostPerPerson: mealCostPerPerson ?? this.mealCostPerPerson,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (meetingDate != null) 'meetingDate': meetingDate!.toIso8601String(),
        'location': location,
        'affiliation': affiliation.name,
        'attendeeCount': attendeeCount,
        'mealCostPerPerson': mealCostPerPerson,
        'isCompleted': isCompleted,
      };

  factory WeddingInvitationMeeting.fromJson(Map<String, dynamic> json) {
    return WeddingInvitationMeeting(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      meetingDate: json['meetingDate'] != null
          ? DateTime.tryParse(json['meetingDate'] as String)
          : null,
      location: json['location'] as String? ?? '',
      affiliation: GuestAffiliation.fromName(json['affiliation'] as String?),
      attendeeCount: json['attendeeCount'] as int? ?? 0,
      mealCostPerPerson: json['mealCostPerPerson'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// 청첩장 모임 D-Day 임박순(오름차순) 정렬 비교자 (날짜 미정은 하단)
int compareMeetingsByCloseness(
  WeddingInvitationMeeting a,
  WeddingInvitationMeeting b, [
  DateTime? relativeNow,
]) {
  if (a.meetingDate == null && b.meetingDate == null) return 0;
  if (a.meetingDate == null) return 1;
  if (b.meetingDate == null) return -1;

  final now = relativeNow ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final ad =
      DateTime(a.meetingDate!.year, a.meetingDate!.month, a.meetingDate!.day);
  final bd =
      DateTime(b.meetingDate!.year, b.meetingDate!.month, b.meetingDate!.day);
  final aDiff = ad.difference(today).inDays;
  final bDiff = bd.difference(today).inDays;
  final aPast = aDiff < 0;
  final bPast = bDiff < 0;
  if (aPast != bPast) return aPast ? 1 : -1;
  return aPast ? bDiff.compareTo(aDiff) : aDiff.compareTo(bDiff);
}

/// 본식 후 정산 & 답례 (After Wedding) 사후 관리 항목 모델
@immutable
class AfterWeddingTask {
  const AfterWeddingTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.costAmount = 0,
    this.memo = '',
  });

  final String id;
  final String title;
  final bool isCompleted;
  final int costAmount;
  final String memo;

  AfterWeddingTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? costAmount,
    String? memo,
  }) {
    return AfterWeddingTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      costAmount: costAmount ?? this.costAmount,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'costAmount': costAmount,
        'memo': memo,
      };

  factory AfterWeddingTask.fromJson(Map<String, dynamic> json) {
    return AfterWeddingTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      costAmount: json['costAmount'] as int? ?? 0,
      memo: json['memo'] as String? ?? '',
    );
  }
}

/// 본식 후 정산 & 답례 기본 6대 프리셋
List<AfterWeddingTask> createDefaultAfterWeddingTasks() => const [
      AfterWeddingTask(
        id: 'after-1',
        title: '사회자 / 축가 / 주례 수고비 정산',
      ),
      AfterWeddingTask(
        id: 'after-2',
        title: '헬퍼 이모님 / 부케순이 / 가방순이 수고비 및 선물 전달',
      ),
      AfterWeddingTask(
        id: 'after-3',
        title: '멀리서 온 하객 차비(교통비) 송금 확인',
      ),
      AfterWeddingTask(
        id: 'after-4',
        title: '신혼여행 경비 최종 정산 (카드 결제일 잔고 확인)',
      ),
      AfterWeddingTask(
        id: 'after-5',
        title: '직장 및 지인 답례품 전달 체크',
      ),
      AfterWeddingTask(
        id: 'after-6',
        title: '양가 부모님 감사 인사 및 식사',
      ),
    ];

/// 청첩장 모임 · 하객 보증인원 · 본식 후 사후관리 · 섹션 커스터마이징 통합 상태
@immutable
class WeddingExtrasState {
  const WeddingExtrasState({
    this.guaranteedGuests = 250,
    this.extraConfirmedGuests = 0,
    this.meetings = const [],
    this.afterWeddingTasks = const [],
    this.sectionOrder = kDefaultWeddingSectionOrder,
    this.hiddenSections = const {},
  });

  final int guaranteedGuests;
  final int extraConfirmedGuests;
  final List<WeddingInvitationMeeting> meetings;
  final List<AfterWeddingTask> afterWeddingTasks;
  final List<String> sectionOrder;
  final Set<String> hiddenSections;

  /// 청모 참석 인원 합계 + 기타 확정 하객 합계
  int get meetingGuestsTotal =>
      meetings.fold<int>(0, (sum, m) => sum + m.attendeeCount);

  int get totalConfirmedGuests => meetingGuestsTotal + extraConfirmedGuests;

  /// 보증인원 대비 차이 (확정 하객 - 계약 보증인원)
  int get guestDiff => totalConfirmedGuests - guaranteedGuests;

  WeddingExtrasState copyWith({
    int? guaranteedGuests,
    int? extraConfirmedGuests,
    List<WeddingInvitationMeeting>? meetings,
    List<AfterWeddingTask>? afterWeddingTasks,
    List<String>? sectionOrder,
    Set<String>? hiddenSections,
  }) {
    return WeddingExtrasState(
      guaranteedGuests: guaranteedGuests ?? this.guaranteedGuests,
      extraConfirmedGuests: extraConfirmedGuests ?? this.extraConfirmedGuests,
      meetings: meetings ?? this.meetings,
      afterWeddingTasks: afterWeddingTasks ?? this.afterWeddingTasks,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      hiddenSections: hiddenSections ?? this.hiddenSections,
    );
  }

  Map<String, dynamic> toJson() => {
        'guaranteedGuests': guaranteedGuests,
        'extraConfirmedGuests': extraConfirmedGuests,
        'meetings': meetings.map((m) => m.toJson()).toList(),
        'afterWeddingTasks': afterWeddingTasks.map((t) => t.toJson()).toList(),
        'sectionOrder': sectionOrder,
        'hiddenSections': hiddenSections.toList(),
      };

  factory WeddingExtrasState.fromJson(Map<String, dynamic> json) {
    final rawOrder = (json['sectionOrder'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .where((k) => kDefaultWeddingSectionOrder.contains(k))
        .toList();
    final mergedOrder = <String>[
      ...?rawOrder,
      for (final k in kDefaultWeddingSectionOrder)
        if (rawOrder == null || !rawOrder.contains(k)) k,
    ];
    final rawHidden = (json['hiddenSections'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return WeddingExtrasState(
      guaranteedGuests: json['guaranteedGuests'] as int? ?? 250,
      extraConfirmedGuests: json['extraConfirmedGuests'] as int? ?? 0,
      meetings: (json['meetings'] as List<dynamic>?)
              ?.map((e) => WeddingInvitationMeeting.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      afterWeddingTasks: (json['afterWeddingTasks'] as List<dynamic>?)
              ?.map((e) => AfterWeddingTask.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          createDefaultAfterWeddingTasks(),
      sectionOrder: mergedOrder,
      hiddenSections: rawHidden,
    );
  }
}
