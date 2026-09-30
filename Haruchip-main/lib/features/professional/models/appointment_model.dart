import 'package:flutter/material.dart';

/// 하위 할 일 / 체크리스트 아이템
@immutable
class SubTaskItem {
  const SubTaskItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  final String id;
  final String title;
  final bool isDone;

  SubTaskItem copyWith({String? id, String? title, bool? isDone}) {
    return SubTaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory SubTaskItem.fromJson(Map<String, dynamic> json) {
    return SubTaskItem(
      id: json['id'] as String? ?? 'sub-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

/// 육하원칙 기반의 정갈한 일정 / 약속 모델
@immutable
class AppointmentItem {
  const AppointmentItem({
    required this.id,
    required this.title, // What
    required this.date, // When (날짜)
    this.time, // When (시간)
    this.isAllDay = false,
    this.location, // Where (장소)
    this.withPeople = const [], // With (함께하는 사람)
    this.subTasks = const [], // 하위 체크리스트
    this.memo,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay? time;
  final bool isAllDay;
  final String? location;
  final List<String> withPeople;
  final List<SubTaskItem> subTasks;
  final String? memo;
  final bool isArchived;

  /// 당일 도래 시 시간 단위 실시간 카운트다운 인터랙션
  String get realtimeCountdownLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final dayDiff = target.difference(today).inDays;

    if (dayDiff > 0) {
      return 'D-$dayDiff';
    } else if (dayDiff < 0) {
      return 'D+${-dayDiff}';
    }

    // 당일인 경우
    if (isAllDay || time == null) {
      return '오늘 D-Day';
    }

    final appointmentDateTime = DateTime(date.year, date.month, date.day, time!.hour, time!.minute);
    final diffMinutes = appointmentDateTime.difference(now).inMinutes;

    if (diffMinutes > 60) {
      final hours = (diffMinutes / 60).floor();
      return '$hours시간 전';
    } else if (diffMinutes > 0) {
      return '$diffMinutes분 전';
    } else if (diffMinutes >= -120) {
      return '진행 중';
    } else {
      return '종료';
    }
  }

  /// 포맷팅된 시간 텍스트 (예: 14:30 또는 하루 종일)
  String get formattedTime {
    if (isAllDay || time == null) return '하루 종일';
    final h = time!.hour.toString().padLeft(2, '0');
    final m = time!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 포맷팅된 날짜 (YYYY.MM.DD)
  String get formattedDate {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}.$m.$d';
  }

  AppointmentItem copyWith({
    String? id,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    bool clearTime = false,
    bool? isAllDay,
    String? location,
    List<String>? withPeople,
    List<SubTaskItem>? subTasks,
    String? memo,
    bool? isArchived,
  }) {
    return AppointmentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      withPeople: withPeople ?? this.withPeople,
      subTasks: subTasks ?? this.subTasks,
      memo: memo ?? this.memo,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'time': time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
        'isAllDay': isAllDay,
        'location': location,
        'withPeople': withPeople,
        'subTasks': subTasks.map((s) => s.toJson()).toList(),
        'memo': memo,
        'isArchived': isArchived,
      };

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedTime;
    if (json['time'] != null) {
      final tMap = json['time'] as Map<String, dynamic>;
      parsedTime = TimeOfDay(
        hour: tMap['hour'] as int? ?? 0,
        minute: tMap['minute'] as int? ?? 0,
      );
    }

    final subTasksRaw = json['subTasks'] as List<dynamic>?;
    final subTasks = subTasksRaw != null
        ? subTasksRaw.map((e) => SubTaskItem.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <SubTaskItem>[];

    final withPeopleRaw = json['withPeople'] as List<dynamic>?;
    final withPeople = withPeopleRaw != null
        ? withPeopleRaw.map((e) => e.toString()).toList()
        : <String>[];

    return AppointmentItem(
      id: json['id'] as String? ?? 'apt-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      time: parsedTime,
      isAllDay: json['isAllDay'] as bool? ?? false,
      location: json['location'] as String?,
      withPeople: withPeople,
      subTasks: subTasks,
      memo: json['memo'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

/// 기본 일정 / 약속 목업 데이터
final List<AppointmentItem> kDefaultMockAppointments = [
  AppointmentItem(
    id: 'apt-1',
    title: '디자인 시스템 싱크 미팅',
    date: DateTime.now(),
    time: const TimeOfDay(hour: 14, minute: 30),
    location: '강남 위워크 3층 회의실',
    withPeople: ['김팀장', '이지은', '박민수'],
    subTasks: const [
      SubTaskItem(id: 'st-1', title: '피그마 컴포넌트 정리본 공유', isDone: true),
      SubTaskItem(id: 'st-2', title: '노션 회의록 템플릿 준비', isDone: false),
    ],
  ),
  AppointmentItem(
    id: 'apt-2',
    title: '대학 동창 저녁 약속 🍽️',
    date: DateTime.now().add(const Duration(days: 3)),
    time: const TimeOfDay(hour: 18, minute: 30),
    location: '성수동 파스타바',
    withPeople: ['지민', '준호', '서연'],
    subTasks: const [
      SubTaskItem(id: 'st-3', title: '식당 예약 확인 및 공유', isDone: true),
    ],
  ),
  AppointmentItem(
    id: 'apt-3',
    title: '정기 치과 스케일링 검진',
    date: DateTime.now().add(const Duration(days: 12)),
    time: const TimeOfDay(hour: 11, minute: 0),
    location: '역삼 바른이치과의원',
    withPeople: const [],
  ),
];
