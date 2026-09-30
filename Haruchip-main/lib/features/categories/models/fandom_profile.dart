import 'package:flutter/foundation.dart';
import 'category_model.dart';

/// 최애/차애/삼애 순위 열거형
enum BiasRank {
  first,
  second,
  third,
  member;

  String toJson() => name;

  static BiasRank fromJson(String? value) {
    return BiasRank.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BiasRank.member,
    );
  }

  String get label => switch (this) {
        BiasRank.first => '👑 최애',
        BiasRank.second => '💖 차애',
        BiasRank.third => '⭐ 삼애',
        BiasRank.member => '멤버',
      };

  String get shortLabel => switch (this) {
        BiasRank.first => '최애',
        BiasRank.second => '차애',
        BiasRank.third => '삼애',
        BiasRank.member => '멤버',
      };

  int get priority => switch (this) {
        BiasRank.first => 0,
        BiasRank.second => 1,
        BiasRank.third => 2,
        BiasRank.member => 3,
      };
}

/// 아티스트 / 멤버 정보 모델
@immutable
class FandomMember {
  const FandomMember({
    required this.id,
    required this.name,
    required this.birthDate,
    this.photoUrl,
    this.emoji = '🎤',
    this.position = '',
    this.memo = '',
    this.biasRank = BiasRank.member,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final String? photoUrl;
  final String emoji;
  final String position;
  final String memo;
  final BiasRank biasRank;

  FandomMember copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    String? photoUrl,
    String? emoji,
    String? position,
    String? memo,
    BiasRank? biasRank,
  }) {
    return FandomMember(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      emoji: emoji ?? this.emoji,
      position: position ?? this.position,
      memo: memo ?? this.memo,
      biasRank: biasRank ?? this.biasRank,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'photoUrl': photoUrl,
        'emoji': emoji,
        'position': position,
        'memo': memo,
        'biasRank': biasRank.toJson(),
      };

  factory FandomMember.fromJson(Map<String, dynamic> json) {
    return FandomMember(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      photoUrl: json['photoUrl'] as String?,
      emoji: json['emoji'] as String? ?? '🎤',
      position: json['position'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      biasRank: BiasRank.fromJson(json['biasRank'] as String?),
    );
  }
}

/// 최애곡 정보
@immutable
class FandomMusicTrack {
  const FandomMusicTrack({
    required this.title,
    required this.artist,
    this.audioPreviewUrl,
    this.albumCoverUrl,
  });

  final String title;
  final String artist;
  final String? audioPreviewUrl;
  final String? albumCoverUrl;

  FandomMusicTrack copyWith({
    String? title,
    String? artist,
    String? audioPreviewUrl,
    String? albumCoverUrl,
  }) {
    return FandomMusicTrack(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioPreviewUrl: audioPreviewUrl ?? this.audioPreviewUrl,
      albumCoverUrl: albumCoverUrl ?? this.albumCoverUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'audioPreviewUrl': audioPreviewUrl,
        'albumCoverUrl': albumCoverUrl,
      };

  factory FandomMusicTrack.fromJson(Map<String, dynamic> json) {
    return FandomMusicTrack(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      audioPreviewUrl: json['audioPreviewUrl'] as String?,
      albumCoverUrl: json['albumCoverUrl'] as String?,
    );
  }
}

/// 포토카드 탑꾸 (Topkku) 설정 데이터
@immutable
class FandomTopkkuCard {
  const FandomTopkkuCard({
    this.photocardUrl,
    this.decorations = const [],
    this.customOverlayText = '',
    this.musicTrack,
  });

  final String? photocardUrl;
  final List<StickerConfig> decorations;
  final String customOverlayText;
  final FandomMusicTrack? musicTrack;

  FandomTopkkuCard copyWith({
    String? photocardUrl,
    List<StickerConfig>? decorations,
    String? customOverlayText,
    FandomMusicTrack? musicTrack,
  }) {
    return FandomTopkkuCard(
      photocardUrl: photocardUrl ?? this.photocardUrl,
      decorations: decorations ?? this.decorations,
      customOverlayText: customOverlayText ?? this.customOverlayText,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }

  Map<String, dynamic> toJson() => {
        'photocardUrl': photocardUrl,
        'decorations': decorations.map((d) => d.toJson()).toList(),
        'customOverlayText': customOverlayText,
        if (musicTrack != null) 'musicTrack': musicTrack!.toJson(),
      };

  factory FandomTopkkuCard.fromJson(Map<String, dynamic> json) {
    return FandomTopkkuCard(
      photocardUrl: json['photocardUrl'] as String?,
      decorations: (json['decorations'] as List<dynamic>?)
              ?.map((d) => StickerConfig.fromJson(d as Map<String, dynamic>))
              .toList() ??
          const [],
      customOverlayText: json['customOverlayText'] as String? ?? '',
      musicTrack: json['musicTrack'] != null
          ? FandomMusicTrack.fromJson(json['musicTrack'] as Map<String, dynamic>)
          : null,
    );
  }
}
