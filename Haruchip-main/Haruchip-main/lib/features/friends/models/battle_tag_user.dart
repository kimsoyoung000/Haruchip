import 'dart:math';

import 'package:flutter/foundation.dart';

const String _kBattleTagChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// 영문 대문자/숫자 4자리 암호학적 난수 배틀태그 생성 (예: '7F2K')
String generateBattleTag() {
  final rng = Random.secure();
  return List.generate(
    4,
    (_) => _kBattleTagChars[rng.nextInt(_kBattleTagChars.length)],
  ).join();
}

/// 4자리 영문 대문자/숫자 태그 유효성 검사
bool isValidBattleTag(String raw) {
  return RegExp(r'^[A-Z0-9]{4}$').hasMatch(raw.trim().toUpperCase());
}

/// 배틀태그(`닉네임#TAG`) 기반 하루칩 유저 프로필 모델 (`users/{uid}`)
@immutable
class BattleTagUser {
  const BattleTagUser({
    required this.uid,
    required this.nickname,
    required this.tag,
    this.avatarIcon = 'simple_chick',
    this.photoUrl,
  });

  final String uid;
  final String nickname;
  final String tag; // 4-char uppercase alphanumeric e.g. '7F2K'
  final String avatarIcon;
  final String? photoUrl;

  /// 검색 및 친구 식별용 유니크 핸들 (예: '소영#7F2K')
  String get fullHandle => '$nickname#$tag';

  BattleTagUser copyWith({
    String? uid,
    String? nickname,
    String? tag,
    String? avatarIcon,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return BattleTagUser(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      tag: tag ?? this.tag,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nickname': nickname,
        'tag': tag,
        'fullHandle': fullHandle,
        'avatarIcon': avatarIcon,
        if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
      };

  factory BattleTagUser.fromJson(Map<String, dynamic> json) {
    final rawTag = (json['tag'] as String?)?.trim().toUpperCase();
    return BattleTagUser(
      uid: json['uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '하루칩 여행자',
      tag: (rawTag != null && isValidBattleTag(rawTag))
          ? rawTag
          : generateBattleTag(),
      avatarIcon: json['avatarIcon'] as String? ?? 'simple_chick',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// 받은 친구 요청 항목
@immutable
class FriendRequestItem {
  const FriendRequestItem({
    required this.id,
    required this.fromUser,
    required this.createdAt,
  });

  final String id;
  final BattleTagUser fromUser;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUser': fromUser.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    return FriendRequestItem(
      id: json['id'] as String? ?? '',
      fromUser: BattleTagUser.fromJson(
        Map<String, dynamic>.from(json['fromUser'] as Map),
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// 커플·군대·결혼 카테고리 1:1 파트너 실시간 동기화 연결 정보
@immutable
class CategoryPartnerLink {
  const CategoryPartnerLink({
    required this.categoryKey,
    required this.partner,
    required this.roomId,
    required this.connectedAt,
  });

  final String categoryKey; // 'couple' | 'military' | 'wedding'
  final BattleTagUser partner;
  final String roomId;
  final DateTime connectedAt;

  Map<String, dynamic> toJson() => {
        'categoryKey': categoryKey,
        'partner': partner.toJson(),
        'roomId': roomId,
        'connectedAt': connectedAt.toIso8601String(),
      };

  factory CategoryPartnerLink.fromJson(Map<String, dynamic> json) {
    return CategoryPartnerLink(
      categoryKey: json['categoryKey'] as String? ?? '',
      partner: BattleTagUser.fromJson(
        Map<String, dynamic>.from(json['partner'] as Map),
      ),
      roomId: json['roomId'] as String? ?? '',
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// 친구·차단·파트너 연결·로컬 별명 통합 상태
@immutable
class FriendSystemState {
  const FriendSystemState({
    required this.myProfile,
    this.friends = const [],
    this.incomingRequests = const [],
    this.sentRequestUids = const {},
    this.blockedUsers = const [],
    this.partnerLinks = const {},
    this.friendAliases = const {},
  });

  final BattleTagUser myProfile;
  final List<BattleTagUser> friends;
  final List<FriendRequestItem> incomingRequests;
  final Set<String> sentRequestUids;
  final List<BattleTagUser> blockedUsers;
  final Map<String, CategoryPartnerLink> partnerLinks;

  /// 나만 볼 수 있는 친구별 로컬 별명(별칭) 맵 (`uid -> 별명`)
  final Map<String, String> friendAliases;

  bool isFriend(String uid) => friends.any((f) => f.uid == uid);
  bool isBlocked(String uid) => blockedUsers.any((b) => b.uid == uid);
  bool hasSentRequest(String uid) => sentRequestUids.contains(uid);
  CategoryPartnerLink? partnerFor(String categoryKey) =>
      partnerLinks[categoryKey];

  String? aliasFor(String uid) {
    final v = friendAliases[uid]?.trim();
    return (v != null && v.isNotEmpty) ? v : null;
  }

  /// 별명이 있으면 `설정한 별명 (본래 닉네임#태그)` 표기, 없으면 `본래 닉네임#태그`
  String displayLabelFor(BattleTagUser user) {
    final alias = aliasFor(user.uid);
    if (alias != null) return '$alias (${user.fullHandle})';
    return user.fullHandle;
  }

  /// 모임 대화상대 목록용 표시명: 별명이 있으면 `설정한 별명 (원래이름#태그 또는 원래이름)`
  String displayMemberName(String uid, String fallbackName) {
    final alias = aliasFor(uid);
    if (alias == null) return fallbackName;
    final friend = friends.where((f) => f.uid == uid).firstOrNull;
    if (friend != null) return '$alias (${friend.fullHandle})';
    return '$alias ($fallbackName)';
  }

  FriendSystemState copyWith({
    BattleTagUser? myProfile,
    List<BattleTagUser>? friends,
    List<FriendRequestItem>? incomingRequests,
    Set<String>? sentRequestUids,
    List<BattleTagUser>? blockedUsers,
    Map<String, CategoryPartnerLink>? partnerLinks,
    Map<String, String>? friendAliases,
  }) {
    return FriendSystemState(
      myProfile: myProfile ?? this.myProfile,
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      sentRequestUids: sentRequestUids ?? this.sentRequestUids,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      partnerLinks: partnerLinks ?? this.partnerLinks,
      friendAliases: friendAliases ?? this.friendAliases,
    );
  }

  Map<String, dynamic> toJson() => {
        'myProfile': myProfile.toJson(),
        'friends': friends.map((f) => f.toJson()).toList(),
        'incomingRequests': incomingRequests.map((r) => r.toJson()).toList(),
        'sentRequestUids': sentRequestUids.toList(),
        'blockedUsers': blockedUsers.map((b) => b.toJson()).toList(),
        'partnerLinks':
            partnerLinks.map((k, v) => MapEntry(k, v.toJson())),
        'friendAliases': friendAliases,
      };

  factory FriendSystemState.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['partnerLinks'] as Map<String, dynamic>? ?? const {};
    final rawAliases =
        json['friendAliases'] as Map<String, dynamic>? ?? const {};
    return FriendSystemState(
      myProfile: BattleTagUser.fromJson(
        Map<String, dynamic>.from(json['myProfile'] as Map),
      ),
      friends: (json['friends'] as List<dynamic>?)
              ?.map((e) =>
                  BattleTagUser.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      incomingRequests: (json['incomingRequests'] as List<dynamic>?)
              ?.map((e) => FriendRequestItem.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      sentRequestUids: (json['sentRequestUids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      blockedUsers: (json['blockedUsers'] as List<dynamic>?)
              ?.map((e) =>
                  BattleTagUser.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      partnerLinks: rawLinks.map(
        (k, v) => MapEntry(
          k,
          CategoryPartnerLink.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      friendAliases: rawAliases.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}
