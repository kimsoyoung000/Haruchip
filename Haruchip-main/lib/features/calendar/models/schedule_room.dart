import 'package:flutter/material.dart';

const Object _unset = Object();

/// 50종 파스텔톤 프리셋 컬러 팔레트 (중복 방지 1인 1컬러 시스템)
const List<String> kPreset50PastelColors = [
  '#FFD1DC', '#FFE4E1', '#FFD8BE', '#FFE5D9', '#FFF1E6',
  '#FDE2E4', '#FAD2E1', '#E2ECE9', '#BEE1E6', '#DFE7FD',
  '#CDDAFD', '#C5D3E8', '#D0F4DE', '#A9DEF9', '#E4C1F9',
  '#F3C4FB', '#FFDFD3', '#E8DFF5', '#FCF6BD', '#D0F0C0',
  '#B5EAD7', '#C7CEEA', '#FFDAC1', '#FFB7B2', '#E2F0CB',
  '#B5E2FA', '#EDC9FF', '#F9F871', '#98D8AA', '#F7D060',
  '#FF6B6B', '#4D96FF', '#6BCB77', '#FFD93D', '#F47C7C',
  '#F4ABC4', '#59CE8F', '#E1AEFF', '#FFBD80', '#A8D1D1',
  '#9EA1D4', '#FD8A8A', '#F1F7B5', '#A8ECE7', '#8062D6',
  '#9288F8', '#FFB4B4', '#FFDEB4', '#FFF9CA', '#B5F1CC',
];

/// 모임 멤버 모델
@immutable
class RoomMember {
  const RoomMember({
    required this.uid,
    required this.name,
    required this.icon,
    this.colorHex = '#DFE7FD',
    this.isHost = false,
  });

  final String uid;
  final String name;
  final String icon;
  final String colorHex;
  final bool isHost;

  RoomMember copyWith({
    String? uid,
    String? name,
    String? icon,
    String? colorHex,
    bool? isHost,
  }) {
    return RoomMember(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'icon': icon,
        'colorHex': colorHex,
        'isHost': isHost,
      };

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '👤',
      colorHex: json['colorHex'] as String? ?? '#DFE7FD',
      isHost: json['isHost'] as bool? ?? false,
    );
  }
}

/// 모임 공유 캘린더 전용 일정 모델
@immutable
class RoomSharedEvent {
  const RoomSharedEvent({
    required this.id,
    required this.roomId,
    required this.title,
    required this.authorUid,
    required this.date,
    this.time,
    this.isAllDay = false,
    this.location,
    this.memo,
  });

  final String id;
  final String roomId;
  final String title;
  final String authorUid;
  final DateTime date;
  final String? time;
  final bool isAllDay;
  final String? location;
  final String? memo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'authorUid': authorUid,
        'date': date.toIso8601String(),
        'time': time,
        'isAllDay': isAllDay,
        'location': location,
        'memo': memo,
      };

  factory RoomSharedEvent.fromJson(Map<String, dynamic> json) {
    return RoomSharedEvent(
      id: json['id'] as String? ?? 'evt-${DateTime.now().microsecondsSinceEpoch}',
      roomId: json['roomId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authorUid: json['authorUid'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      time: json['time'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      location: json['location'] as String?,
      memo: json['memo'] as String?,
    );
  }
}

/// 모임 게시판 공지 / 메모 모델
@immutable
class RoomNotice {
  const RoomNotice({
    required this.id,
    required this.authorName,
    required this.authorIcon,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
  });

  final String id;
  final String authorName;
  final String authorIcon;
  final String content;
  final DateTime createdAt;
  final bool isPinned;

  RoomNotice copyWith({
    String? id,
    String? authorName,
    String? authorIcon,
    String? content,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return RoomNotice(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorIcon: authorIcon ?? this.authorIcon,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'authorIcon': authorIcon,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory RoomNotice.fromJson(Map<String, dynamic> json) {
    return RoomNotice(
      id: json['id'] as String? ?? 'notice-${DateTime.now().microsecondsSinceEpoch}',
      authorName: json['authorName'] as String? ?? '',
      authorIcon: json['authorIcon'] as String? ?? '📢',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
}

/// 모임 투표 옵션
@immutable
class VoteOption {
  const VoteOption({
    required this.id,
    required this.text,
    this.voterUids = const [],
  });

  final String id;
  final String text;
  final List<String> voterUids;

  VoteOption copyWith({
    String? id,
    String? text,
    List<String>? voterUids,
  }) {
    return VoteOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voterUids: voterUids ?? this.voterUids,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'voterUids': voterUids,
      };

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      voterUids: (json['voterUids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// 모임 투표 모델
@immutable
class RoomVote {
  const RoomVote({
    required this.id,
    required this.title,
    this.description,
    this.authorUid,
    this.allowMultiple = false,
    required this.options,
    required this.createdAt,
    this.isClosed = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? authorUid;
  final bool allowMultiple;
  final List<VoteOption> options;
  final DateTime createdAt;
  final bool isClosed;

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.voterUids.length);

  RoomVote copyWith({
    String? id,
    String? title,
    String? description,
    String? authorUid,
    bool? allowMultiple,
    List<VoteOption>? options,
    DateTime? createdAt,
    bool? isClosed,
  }) {
    return RoomVote(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorUid: authorUid ?? this.authorUid,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'authorUid': authorUid,
        'allowMultiple': allowMultiple,
        'options': options.map((o) => o.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isClosed': isClosed,
      };

  factory RoomVote.fromJson(Map<String, dynamic> json) {
    return RoomVote(
      id: json['id'] as String? ?? 'vote-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      authorUid: json['authorUid'] as String?,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => VoteOption.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }
}

/// 정산 차수 내 예외 공제 항목
@immutable
class SettlementException {
  const SettlementException({
    required this.id,
    required this.title,
    required this.amount,
    required this.exemptMemberUids, // 공제 대상 / 비참여 멤버들
  });

  final String id;
  final String title;
  final int amount;
  final List<String> exemptMemberUids;

  String get name => title;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'exemptMemberUids': exemptMemberUids,
      };

  factory SettlementException.fromJson(Map<String, dynamic> json) {
    return SettlementException(
      id: json['id'] as String? ?? 'exp-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      exemptMemberUids:
          (json['exemptMemberUids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// 차수별 (1차, 2차... N차) 정산 모델
@immutable
class SettlementRound {
  const SettlementRound({
    required this.id,
    required this.roundNumber,
    required this.title,
    required this.totalAmount,
    required this.payerUid,
    required this.attendeeUids,
    this.exceptions = const [],
  });

  final String id;
  final int roundNumber;
  final String title;
  final int totalAmount;
  final String payerUid;
  final List<String> attendeeUids;
  final List<SettlementException> exceptions;

  SettlementRound copyWith({
    String? id,
    int? roundNumber,
    String? title,
    int? totalAmount,
    String? payerUid,
    List<String>? attendeeUids,
    List<SettlementException>? exceptions,
  }) {
    return SettlementRound(
      id: id ?? this.id,
      roundNumber: roundNumber ?? this.roundNumber,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      payerUid: payerUid ?? this.payerUid,
      attendeeUids: attendeeUids ?? this.attendeeUids,
      exceptions: exceptions ?? this.exceptions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundNumber': roundNumber,
        'title': title,
        'totalAmount': totalAmount,
        'payerUid': payerUid,
        'attendeeUids': attendeeUids,
        'exceptions': exceptions.map((e) => e.toJson()).toList(),
      };

  factory SettlementRound.fromJson(Map<String, dynamic> json) {
    return SettlementRound(
      id: json['id'] as String? ?? 'round-${DateTime.now().microsecondsSinceEpoch}',
      roundNumber: json['roundNumber'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      totalAmount: json['totalAmount'] as int? ?? 0,
      payerUid: json['payerUid'] as String? ?? '',
      attendeeUids:
          (json['attendeeUids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      exceptions: (json['exceptions'] as List<dynamic>?)
              ?.map((e) => SettlementException.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

/// 독립 모임 방 모델
class ScheduleRoom {
  const ScheduleRoom({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    required this.dates,
    this.description,
    this.categoryTag = '모임',
    this.confirmedDate,
    this.payments = const {},
    this.settlementConfirmedAt,
    this.events = const [],
    this.notices = const [],
    this.votes = const [],
    this.rounds = const [],
  });

  final String id;
  final String name;
  final String inviteCode; // 8~10자리 보안 코드
  final String? description;
  final String categoryTag;
  final List<RoomMember> members;

  /// key: 'YYYY-MM-DD', value: 그 날짜에 가능하다고 표시한 uid 리스트
  final Map<String, List<String>> dates;
  final String? confirmedDate;

  /// 기존 호환용 payments
  final Map<String, int> payments;
  final DateTime? settlementConfirmedAt;

  /// 고도화된 모임 내부 시스템
  final List<RoomSharedEvent> events;
  List<RoomSharedEvent> get sharedEvents => events;
  final List<RoomNotice> notices;
  final List<RoomVote> votes;
  final List<SettlementRound> rounds;

  ScheduleRoom copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? description,
    String? categoryTag,
    List<RoomMember>? members,
    Map<String, List<String>>? dates,
    Object? confirmedDate = _unset,
    Map<String, int>? payments,
    Object? settlementConfirmedAt = _unset,
    List<RoomSharedEvent>? events,
    List<RoomNotice>? notices,
    List<RoomVote>? votes,
    List<SettlementRound>? rounds,
  }) {
    return ScheduleRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      description: description ?? this.description,
      categoryTag: categoryTag ?? this.categoryTag,
      members: members ?? this.members,
      dates: dates ?? this.dates,
      confirmedDate: identical(confirmedDate, _unset)
          ? this.confirmedDate
          : confirmedDate as String?,
      payments: payments ?? this.payments,
      settlementConfirmedAt: identical(settlementConfirmedAt, _unset)
          ? this.settlementConfirmedAt
          : settlementConfirmedAt as DateTime?,
      events: events ?? this.events,
      notices: notices ?? this.notices,
      votes: votes ?? this.votes,
      rounds: rounds ?? this.rounds,
    );
  }
}
