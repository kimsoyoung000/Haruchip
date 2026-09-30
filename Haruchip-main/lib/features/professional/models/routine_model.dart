import 'package:flutter/material.dart';

/// 루틴 / 주간 계획표 모델
@immutable
class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.title,
    required this.daysOfWeek, // 1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일
    required this.startTime,
    required this.endTime,
    this.colorHex = '#DBEAFE',
    this.location,
    this.memo,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final Set<int> daysOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String colorHex;
  final String? location;
  final String? memo;
  final bool isArchived;

  /// 요일 문자열 변환 (예: "월, 수, 금" / "평일" / "주말" / "매일")
  String get formattedDays {
    if (daysOfWeek.length == 7) return '매일';
    if (daysOfWeek.length == 5 &&
        daysOfWeek.containsAll([1, 2, 3, 4, 5])) {
      return '평일(월~금)';
    }
    if (daysOfWeek.length == 2 &&
        daysOfWeek.containsAll([6, 7])) {
      return '주말(토·일)';
    }

    const dayNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final sorted = daysOfWeek.toList()..sort();
    return sorted.map((d) => dayNames[d] ?? '').join(', ');
  }

  /// 시간대 범위 포맷팅 (예: "18:00 ~ 19:30")
  String get formattedTimeRange {
    final sh = startTime.hour.toString().padLeft(2, '0');
    final sm = startTime.minute.toString().padLeft(2, '0');
    final eh = endTime.hour.toString().padLeft(2, '0');
    final em = endTime.minute.toString().padLeft(2, '0');
    return '$sh:$sm ~ $eh:$em';
  }

  /// 다가오는 가장 빠른 요일 일정 계산
  DateTime nextUpcomingDate([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    for (int i = 0; i < 7; i++) {
      final candidateDate = now.add(Duration(days: i));
      final candidateWeekday = candidateDate.weekday; // 1=Mon..7=Sun

      if (daysOfWeek.contains(candidateWeekday)) {
        final candidateDateTime = DateTime(
          candidateDate.year,
          candidateDate.month,
          candidateDate.day,
          startTime.hour,
          startTime.minute,
        );
        if (candidateDateTime.isAfter(now)) {
          return candidateDateTime;
        }
      }
    }

    // 7일 뒤 다음 회차
    final nextWeek = now.add(const Duration(days: 7));
    return DateTime(
      nextWeek.year,
      nextWeek.month,
      nextWeek.day,
      startTime.hour,
      startTime.minute,
    );
  }

  /// "다음 [필라테스]까지 D-2 18:00" 알림 라벨
  String get nextDDayLabel {
    final now = DateTime.now();
    final next = nextUpcomingDate(now);
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(next.year, next.month, next.day);
    final diff = targetDay.difference(today).inDays;

    final sh = startTime.hour.toString().padLeft(2, '0');
    final sm = startTime.minute.toString().padLeft(2, '0');

    if (diff == 0) {
      return '오늘 $sh:$sm';
    }
    return 'D-$diff $sh:$sm';
  }

  RoutineItem copyWith({
    String? id,
    String? title,
    Set<int>? daysOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? colorHex,
    String? location,
    String? memo,
    bool? isArchived,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorHex: colorHex ?? this.colorHex,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'daysOfWeek': daysOfWeek.toList(),
        'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
        'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
        'colorHex': colorHex,
        'location': location,
        'memo': memo,
        'isArchived': isArchived,
      };

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final sMap = json['startTime'] as Map<String, dynamic>? ?? {'hour': 9, 'minute': 0};
    final eMap = json['endTime'] as Map<String, dynamic>? ?? {'hour': 10, 'minute': 0};
    final daysRaw = json['daysOfWeek'] as List<dynamic>? ?? [1, 3, 5];

    return RoutineItem(
      id: json['id'] as String? ?? 'rtn-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      daysOfWeek: daysRaw.map((e) => e as int).toSet(),
      startTime: TimeOfDay(hour: sMap['hour'] as int? ?? 9, minute: sMap['minute'] as int? ?? 0),
      endTime: TimeOfDay(hour: eMap['hour'] as int? ?? 10, minute: eMap['minute'] as int? ?? 0),
      colorHex: json['colorHex'] as String? ?? '#DBEAFE',
      location: json['location'] as String?,
      memo: json['memo'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

/// 기본 루틴 / 주간 계획표 목업 데이터
final List<RoutineItem> kDefaultMockRoutines = [
  const RoutineItem(
    id: 'rtn-1',
    title: '필라테스 체형 교정 🧘‍♀️',
    daysOfWeek: {1, 3, 5}, // 월, 수, 금
    startTime: TimeOfDay(hour: 18, minute: 0),
    endTime: TimeOfDay(hour: 19, minute: 0),
    colorHex: '#DBEAFE', // 파스텔 블루
    location: '바디랩 필라테스 스튜디오',
  ),
  const RoutineItem(
    id: 'rtn-2',
    title: '원어민 1:1 영어 회화 학원 🗣️',
    daysOfWeek: {2, 4}, // 화, 목
    startTime: TimeOfDay(hour: 20, minute: 0),
    endTime: TimeOfDay(hour: 21, minute: 30),
    colorHex: '#FEF08A', // 파스텔 옐로우
    location: '파고다어학원 강남점',
  ),
  const RoutineItem(
    id: 'rtn-3',
    title: '주말 러닝 & 헬스 루틴 🏃‍♂️',
    daysOfWeek: {6, 7}, // 토, 일
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 10, minute: 30),
    colorHex: '#DCFCE7', // 파스텔 민트
    location: '양재천 트랙',
  ),
];
