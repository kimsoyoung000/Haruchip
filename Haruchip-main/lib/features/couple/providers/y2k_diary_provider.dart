import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/y2k_diary_models.dart';

String formatDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Y2K 일자별 데이터 저장소 Notifier
class Y2KDiaryNotifier extends Notifier<Map<String, Y2KDayData>> {
  @override
  Map<String, Y2KDayData> build() {
    final today = DateTime.now();
    final todayKey = formatDateKey(today);

    // Initial mock data for today
    return {
      todayKey: Y2KDayData(
        dateKey: todayKey,
        todos: [
          RoomTodo(
            id: 'todo_1',
            title: '오늘의 디데이 확인하기 💖',
            isCompleted: true,
            createdAt: today,
          ),
          RoomTodo(
            id: 'todo_2',
            title: '하루 10분 다꾸 & 일기 쓰기 🎨',
            isCompleted: true,
            createdAt: today,
          ),
          RoomTodo(
            id: 'todo_3',
            title: '소중한 사람에게 한마디 남기기 💌',
            isCompleted: false,
            createdAt: today,
          ),
        ],
        diaryText: '오늘은 하루칩 다이어리를 꾸미는 날! 슈게임 플래시 감성이 너무 귀엽고 아기자기하다 🍓✨',
        stickers: [
          const PlacedSticker(
            id: 'stk_init_1',
            stickerId: 'rf_ribbon',
            icon: '🎀',
            name: '키치 리본',
            x: 0.22,
            y: 0.18,
            scale: 1.2,
            rotation: -0.15,
          ),
          const PlacedSticker(
            id: 'stk_init_2',
            stickerId: 'rf_cherry',
            icon: '🍒',
            name: '체리',
            x: 0.78,
            y: 0.22,
            scale: 1.1,
            rotation: 0.2,
          ),
          const PlacedSticker(
            id: 'stk_init_3',
            stickerId: 'custom_tape',
            icon: '🏷️',
            name: '손글씨 테이프',
            x: 0.5,
            y: 0.82,
            scale: 1.0,
            rotation: -0.05,
            isTextTape: true,
            text: '✨ Y2K Retro Memory ✨',
            tapeColorHex: '#FFE4E6',
          ),
        ],
        soundEnabled: true,
      ),
    };
  }

  Y2KDayData getDayData(DateTime date) {
    final key = formatDateKey(date);
    return state[key] ??
        Y2KDayData(
          dateKey: key,
          todos: [],
          diaryText: '',
          stickers: [],
          soundEnabled: state.values.isNotEmpty ? state.values.first.soundEnabled : true,
        );
  }

  void _updateDay(String dateKey, Y2KDayData Function(Y2KDayData current) updater) {
    final current = state[dateKey] ?? Y2KDayData(dateKey: dateKey);
    final updated = updater(current);
    state = {...state, dateKey: updated};
  }

  void addTodo(DateTime date, String title) {
    if (title.trim().isEmpty) return;
    final key = formatDateKey(date);
    _updateDay(key, (day) {
      final newTodo = RoomTodo(
        id: 'todo_${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      return day.copyWith(todos: [...day.todos, newTodo]);
    });
  }

  void toggleTodo(DateTime date, String id) {
    final key = formatDateKey(date);
    _updateDay(key, (day) {
      final updatedTodos = day.todos.map((t) {
        if (t.id == id) {
          return t.copyWith(isCompleted: !t.isCompleted);
        }
        return t;
      }).toList();
      return day.copyWith(todos: updatedTodos);
    });
  }

  void deleteTodo(DateTime date, String id) {
    final key = formatDateKey(date);
    _updateDay(key, (day) {
      final updatedTodos = day.todos.where((t) => t.id != id).toList();
      return day.copyWith(todos: updatedTodos);
    });
  }

  void updateDiaryText(DateTime date, String text) {
    final key = formatDateKey(date);
    _updateDay(key, (day) => day.copyWith(diaryText: text));
  }

  void addSticker(
    DateTime date,
    StickerItemModel model, {
    String? customText,
    String? tapeColor,
  }) {
    final key = formatDateKey(date);
    _updateDay(key, (day) {
      final newSticker = PlacedSticker(
        id: 'stk_${DateTime.now().microsecondsSinceEpoch}',
        stickerId: model.id,
        icon: model.icon,
        name: model.name,
        x: 0.5,
        y: 0.45,
        scale: 1.0,
        rotation: 0.0,
        zIndex: day.stickers.length,
        isTextTape: model.isTape || customText != null,
        text: customText,
        tapeColorHex: tapeColor ?? model.defaultTapeColor,
      );
      return day.copyWith(stickers: [...day.stickers, newSticker]);
    });
  }

  void updateSticker(DateTime date, PlacedSticker sticker) {
    final key = formatDateKey(date);
    _updateDay(key, (day) {
      final updatedList = day.stickers.map((s) {
        if (s.id == sticker.id) return sticker;
        return s;
      }).toList();
      return day.copyWith(stickers: updatedList);
    });
  }

  void deleteSticker(DateTime date, String id) {
    final key = formatDateKey(date);
    _updateDay(key, (day) {
      final updatedList = day.stickers.where((s) => s.id != id).toList();
      return day.copyWith(stickers: updatedList);
    });
  }

  void clearCanvas(DateTime date) {
    final key = formatDateKey(date);
    _updateDay(key, (day) => day.copyWith(stickers: []));
  }

  void toggleSound(DateTime date) {
    final key = formatDateKey(date);
    _updateDay(key, (day) => day.copyWith(soundEnabled: !day.soundEnabled));
  }
}

final y2kDiaryProvider = NotifierProvider<Y2KDiaryNotifier, Map<String, Y2KDayData>>(
  Y2KDiaryNotifier.new,
);

/// 현재 선택된 Y2K 다이어리 날짜
final selectedDiaryDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 현재 선택된 날짜의 DayData
final currentDayDataProvider = Provider<Y2KDayData>((ref) {
  final date = ref.watch(selectedDiaryDateProvider);
  final allData = ref.watch(y2kDiaryProvider);
  final key = formatDateKey(date);
  return allData[key] ?? Y2KDayData(dateKey: key);
});
