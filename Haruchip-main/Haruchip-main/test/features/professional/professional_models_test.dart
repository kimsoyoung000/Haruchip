import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/professional/models/appointment_model.dart';
import 'package:haruchip/features/professional/models/goal_model.dart';
import 'package:haruchip/features/professional/models/routine_model.dart';

void main() {
  group('GoalItem Model Tests', () {
    test('GoalItem json serialization and deserialization', () {
      final goal = GoalItem(
        id: 'goal-1',
        title: '토익 900점 달성',
        goalType: GoalType.yearly,
        status: GoalStatus.inProgress,
        highlighter: HighlighterColor.yellow,
        deadline: DateTime(2026, 12, 31),
        showInCalendar: true,
      );

      final json = goal.toJson();
      final fromJson = GoalItem.fromJson(json);

      expect(fromJson.id, 'goal-1');
      expect(fromJson.title, '토익 900점 달성');
      expect(fromJson.goalType, GoalType.yearly);
      expect(fromJson.status, GoalStatus.inProgress);
      expect(fromJson.highlighter, HighlighterColor.yellow);
      expect(fromJson.showInCalendar, true);
    });

    test('GoalItem D-Day calculation', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10));
      final goal = GoalItem(
        id: 'goal-2',
        title: '운동하기',
        deadline: futureDate,
      );

      expect(goal.dDayLabel, 'D-10');
    });
  });

  group('AppointmentItem Model Tests', () {
    test('AppointmentItem json serialization', () {
      final appt = AppointmentItem(
        id: 'appt-1',
        title: '팀 스프린트 회의',
        date: DateTime(2026, 5, 20, 14, 30),
        isAllDay: false,
        location: '강남역 2번 출구 카페',
        withPeople: ['김팀장', '이지은'],
        subTasks: [
          const SubTaskItem(id: 'sub-1', title: '기획서 출력', isDone: true),
          const SubTaskItem(id: 'sub-2', title: '데모 시연 준비', isDone: false),
        ],
      );

      final json = appt.toJson();
      final fromJson = AppointmentItem.fromJson(json);

      expect(fromJson.id, 'appt-1');
      expect(fromJson.title, '팀 스프린트 회의');
      expect(fromJson.isAllDay, false);
      expect(fromJson.location, '강남역 2번 출구 카페');
      expect(fromJson.withPeople, ['김팀장', '이지은']);
      expect(fromJson.subTasks.length, 2);
      expect(fromJson.subTasks[0].isDone, true);
      expect(fromJson.subTasks[1].isDone, false);
    });
  });

  group('RoutineItem Model Tests', () {
    test('RoutineItem day of week calculations', () {
      final routine = RoutineItem(
        id: 'routine-1',
        title: '필라테스',
        daysOfWeek: {1, 3, 5}, // 월, 수, 금
        startTime: const TimeOfDay(hour: 19, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
      );

      expect(routine.formattedDays, '월, 수, 금');
      expect(routine.formattedTimeRange, '19:00 ~ 20:00');
      expect(routine.nextUpcomingDate(), isNotNull);
    });
  });
}
