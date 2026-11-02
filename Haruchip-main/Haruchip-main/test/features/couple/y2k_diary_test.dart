import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/couple/models/y2k_diary_models.dart';
import 'package:haruchip/features/couple/providers/y2k_diary_provider.dart';

void main() {
  group('Y2K Diary Models Serialization Tests', () {
    test('RoomTodo serialization works correctly', () {
      final todo = RoomTodo(
        id: 'todo_test',
        title: '다이어리 꾸미기 🎀',
        isCompleted: true,
        createdAt: DateTime(2025, 5, 20),
      );

      final json = todo.toJson();
      expect(json['id'], 'todo_test');
      expect(json['isCompleted'], isTrue);

      final restored = RoomTodo.fromJson(json);
      expect(restored.id, 'todo_test');
      expect(restored.title, '다이어리 꾸미기 🎀');
      expect(restored.isCompleted, isTrue);
    });

    test('PlacedSticker serialization works correctly', () {
      const sticker = PlacedSticker(
        id: 'stk_test',
        stickerId: 'rf_ribbon',
        icon: '🎀',
        name: '키치 리본',
        x: 0.35,
        y: 0.45,
        scale: 1.5,
        rotation: 0.25,
        isTextTape: true,
        text: 'Hello Y2K',
        tapeColorHex: '#FFE4E6',
      );

      final json = sticker.toJson();
      expect(json['id'], 'stk_test');
      expect(json['scale'], 1.5);
      expect(json['isTextTape'], isTrue);
      expect(json['text'], 'Hello Y2K');

      final restored = PlacedSticker.fromJson(json);
      expect(restored.id, 'stk_test');
      expect(restored.name, '키치 리본');
      expect(restored.x, 0.35);
      expect(restored.scale, 1.5);
      expect(restored.isTextTape, isTrue);
      expect(restored.text, 'Hello Y2K');
    });

    test('Y2KDayData calculates progress and stamps accurately', () {
      final now = DateTime(2025, 5, 20);
      final dayData = Y2KDayData(
        dateKey: '2025-05-20',
        todos: [
          RoomTodo(id: 't1', title: '일정 1', isCompleted: true, createdAt: now),
          RoomTodo(id: 't2', title: '일정 2', isCompleted: true, createdAt: now),
          RoomTodo(id: 't3', title: '일정 3', isCompleted: false, createdAt: now),
          RoomTodo(id: 't4', title: '일정 4', isCompleted: false, createdAt: now),
        ],
      );

      expect(dayData.completedTodoCount, 2);
      expect(dayData.progress, 0.5);
      expect(dayData.stampCount, 2);
    });
  });

  group('Y2K Diary Provider Tests', () {
    test('Todo add, toggle, and delete works across dates', () {
      final container = ProviderContainer();
      final date = DateTime(2025, 6, 1);

      // 1. Add todo
      container.read(y2kDiaryProvider.notifier).addTodo(date, '슈의 의상실 플레이하기 👗');
      var day = container.read(y2kDiaryProvider.notifier).getDayData(date);
      expect(day.todos.length, 1);
      expect(day.todos.first.title, '슈의 의상실 플레이하기 👗');
      expect(day.todos.first.isCompleted, isFalse);

      // 2. Toggle todo
      final todoId = day.todos.first.id;
      container.read(y2kDiaryProvider.notifier).toggleTodo(date, todoId);
      day = container.read(y2kDiaryProvider.notifier).getDayData(date);
      expect(day.todos.first.isCompleted, isTrue);
      expect(day.stampCount, 1);

      // 3. Delete todo
      container.read(y2kDiaryProvider.notifier).deleteTodo(date, todoId);
      day = container.read(y2kDiaryProvider.notifier).getDayData(date);
      expect(day.todos.isEmpty, isTrue);
      expect(day.stampCount, 0);
    });

    test('Sticker add, update, and clear operates properly', () {
      final container = ProviderContainer();
      final date = DateTime(2025, 6, 2);

      // 1. Add sticker
      const model = StickerItemModel(
        id: 'rf_cherry',
        pack: StickerPackCategory.retroFancy,
        name: '체리',
        icon: '🍒',
      );
      container.read(y2kDiaryProvider.notifier).addSticker(date, model);
      var day = container.read(y2kDiaryProvider.notifier).getDayData(date);
      expect(day.stickers.length, 1);
      expect(day.stickers.first.icon, '🍒');

      // 2. Update sticker
      final added = day.stickers.first;
      final moved = added.copyWith(x: 0.8, y: 0.9, scale: 2.0);
      container.read(y2kDiaryProvider.notifier).updateSticker(date, moved);
      day = container.read(y2kDiaryProvider.notifier).getDayData(date);
      expect(day.stickers.first.x, 0.8);
      expect(day.stickers.first.scale, 2.0);

      // 3. Clear canvas
      container.read(y2kDiaryProvider.notifier).clearCanvas(date);
      day = container.read(y2kDiaryProvider.notifier).getDayData(date);
      expect(day.stickers.isEmpty, isTrue);
    });
  });
}
