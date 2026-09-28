import 'package:flutter/foundation.dart';

/// Y2K 다이어리 투두 항목
@immutable
class RoomTodo {
  const RoomTodo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  RoomTodo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return RoomTodo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoomTodo.fromJson(Map<String, dynamic> json) {
    return RoomTodo(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// 캔버스에 배치된 스티커
@immutable
class PlacedSticker {
  const PlacedSticker({
    required this.id,
    required this.stickerId,
    required this.icon,
    required this.name,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isTextTape = false,
    this.text,
    this.tapeColorHex = '#FFE4E6',
  });

  final String id;
  final String stickerId;
  final String icon;
  final String name;
  final double x; // 0.0 ~ 1.0 (Canvas relative width)
  final double y; // 0.0 ~ 1.0 (Canvas relative height)
  final double scale;
  final double rotation; // Radians
  final int zIndex;
  final bool isTextTape;
  final String? text;
  final String tapeColorHex;

  PlacedSticker copyWith({
    String? id,
    String? stickerId,
    String? icon,
    String? name,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isTextTape,
    String? text,
    String? tapeColorHex,
  }) {
    return PlacedSticker(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isTextTape: isTextTape ?? this.isTextTape,
      text: text ?? this.text,
      tapeColorHex: tapeColorHex ?? this.tapeColorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stickerId': stickerId,
        'icon': icon,
        'name': name,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'zIndex': zIndex,
        'isTextTape': isTextTape,
        'text': text,
        'tapeColorHex': tapeColorHex,
      };

  factory PlacedSticker.fromJson(Map<String, dynamic> json) {
    return PlacedSticker(
      id: json['id'] as String,
      stickerId: json['stickerId'] as String,
      icon: json['icon'] as String? ?? '🎀',
      name: json['name'] as String? ?? '스티커',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      isTextTape: json['isTextTape'] as bool? ?? false,
      text: json['text'] as String?,
      tapeColorHex: json['tapeColorHex'] as String? ?? '#FFE4E6',
    );
  }
}

/// 스티커 팩 카테고리
enum StickerPackCategory {
  retroFancy, // 레트로 팬시
  memoTape, // 감성 메모/테이프
  stampPraise, // 칭찬 도장
  y2kSpecial, // Y2K 스페셜
}

/// 스티커북 인벤토리 아이템 모델
@immutable
class StickerItemModel {
  const StickerItemModel({
    required this.id,
    required this.pack,
    required this.name,
    required this.icon,
    this.isPro = false,
    this.isTape = false,
    this.defaultTapeColor = '#FFE4E6',
  });

  final String id;
  final StickerPackCategory pack;
  final String name;
  final String icon;
  final bool isPro;
  final bool isTape;
  final String defaultTapeColor;
}

/// 기본 제공 스티커 팩 데이터
const List<StickerItemModel> kDefaultStickerPacks = [
  // 1. 레트로 팬시 팩
  StickerItemModel(id: 'rf_star', pack: StickerPackCategory.retroFancy, name: '반짝이 별', icon: '⭐'),
  StickerItemModel(id: 'rf_ribbon', pack: StickerPackCategory.retroFancy, name: '키치 리본', icon: '🎀'),
  StickerItemModel(id: 'rf_cherry', pack: StickerPackCategory.retroFancy, name: '체리', icon: '🍒'),
  StickerItemModel(id: 'rf_heart', pack: StickerPackCategory.retroFancy, name: '보석 하트', icon: '💖'),
  StickerItemModel(id: 'rf_wings', pack: StickerPackCategory.retroFancy, name: '천사 날개', icon: '🪽'),
  StickerItemModel(id: 'rf_strawberry', pack: StickerPackCategory.retroFancy, name: '딸기', icon: '🍓'),
  StickerItemModel(id: 'rf_cake', pack: StickerPackCategory.retroFancy, name: '조각 케이크', icon: '🍰'),
  StickerItemModel(id: 'rf_lollipop', pack: StickerPackCategory.retroFancy, name: '롤리팝', icon: '🍭'),
  StickerItemModel(id: 'rf_magic', pack: StickerPackCategory.retroFancy, name: '요술봉', icon: '🪄', isPro: true),
  StickerItemModel(id: 'rf_crystal', pack: StickerPackCategory.retroFancy, name: '크리스탈', icon: '🔮', isPro: true),

  // 2. 감성 메모/테이프 팩
  StickerItemModel(id: 'mt_lace', pack: StickerPackCategory.memoTape, name: '레이스 마테', icon: '🎀', isTape: true, defaultTapeColor: '#FFF0F5'),
  StickerItemModel(id: 'mt_check', pack: StickerPackCategory.memoTape, name: '체크 마테', icon: '🏷️', isTape: true, defaultTapeColor: '#FEF3C7'),
  StickerItemModel(id: 'mt_pin', pack: StickerPackCategory.memoTape, name: '하트 압정', icon: '📌'),
  StickerItemModel(id: 'mt_pink_memo', pack: StickerPackCategory.memoTape, name: '분홍 메모지', icon: '📝'),
  StickerItemModel(id: 'mt_yellow_memo', pack: StickerPackCategory.memoTape, name: '노랑 메모지', icon: '📒'),
  StickerItemModel(id: 'mt_purple_memo', pack: StickerPackCategory.memoTape, name: '보라 메모지', icon: '📋', isPro: true),

  // 3. 칭찬 도장 팩
  StickerItemModel(id: 'st_great', pack: StickerPackCategory.stampPraise, name: '참 잘했어요!', icon: '💮'),
  StickerItemModel(id: 'st_wink', pack: StickerPackCategory.stampPraise, name: '윙크 스마일', icon: '😉'),
  StickerItemModel(id: 'st_crown', pack: StickerPackCategory.stampPraise, name: '왕관', icon: '👑'),
  StickerItemModel(id: 'st_100', pack: StickerPackCategory.stampPraise, name: '백점만점', icon: '💯'),
  StickerItemModel(id: 'st_thumb', pack: StickerPackCategory.stampPraise, name: '최고야', icon: '👍'),
  StickerItemModel(id: 'st_gold_star', pack: StickerPackCategory.stampPraise, name: '황금 트로피', icon: '🏆', isPro: true),
];

/// 날짜별 전체 Y2K 다이어리 상태 모델
@immutable
class Y2KDayData {
  const Y2KDayData({
    required this.dateKey,
    this.todos = const [],
    this.diaryText = '',
    this.stickers = const [],
    this.soundEnabled = true,
  });

  final String dateKey; // YYYY-MM-DD
  final List<RoomTodo> todos;
  final String diaryText;
  final List<PlacedSticker> stickers;
  final bool soundEnabled;

  int get completedTodoCount => todos.where((t) => t.isCompleted).length;
  double get progress => todos.isEmpty ? 0.0 : (completedTodoCount / todos.length).clamp(0.0, 1.0);
  int get stampCount => completedTodoCount.clamp(0, 6);

  Y2KDayData copyWith({
    String? dateKey,
    List<RoomTodo>? todos,
    String? diaryText,
    List<PlacedSticker>? stickers,
    bool? soundEnabled,
  }) {
    return Y2KDayData(
      dateKey: dateKey ?? this.dateKey,
      todos: todos ?? this.todos,
      diaryText: diaryText ?? this.diaryText,
      stickers: stickers ?? this.stickers,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'todos': todos.map((t) => t.toJson()).toList(),
        'diaryText': diaryText,
        'stickers': stickers.map((s) => s.toJson()).toList(),
        'soundEnabled': soundEnabled,
      };

  factory Y2KDayData.fromJson(Map<String, dynamic> json) {
    return Y2KDayData(
      dateKey: json['dateKey'] as String,
      todos: (json['todos'] as List<dynamic>?)
              ?.map((e) => RoomTodo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      diaryText: json['diaryText'] as String? ?? '',
      stickers: (json['stickers'] as List<dynamic>?)
              ?.map((e) => PlacedSticker.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }
}
