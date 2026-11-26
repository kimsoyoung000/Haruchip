import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// 하루칩 전역 입력값 보안 검증 및 인젝션 방어(Input Sanitization) 유틸리티
///
/// 1) 배틀태그(`닉네임#TAG`) 검색창:
///    - 허용: 한글, 영문 대소문자, 숫자, 공백, `#`
///    - 차단: `'`, `"`, `=`, `,`, `.`, `/`, `?`, `~`, `%`, `&`, `*`, `$`, `<`, `>`, `;`, `--`, `\`, `|` 등 모든 특수기호
///    - 공백 정규화: `소영   #7F2K` -> `소영#7F2K`
/// 2) 일반 텍스트(모임명, 캘린더, 공지 등):
///    - 허용: 일반 문장부호(`~`, `,`, `!`, `?` 등)
///    - 차단/살균: NoSQL/SQL 인젝션 위험 문자(`$`, `{`, `}`, `[`, `]`, `'`, `"`, `;`, `--`)
/// 3) 백엔드 내부 모임 식별자:
///    - CSPRNG(Random.secure) 32바이트 + SHA-256 단방향 해시 기반 내부 `groupId`
class HaruInputSanitizer {
  HaruInputSanitizer._();

  static final RegExp _battleTagAllowedRegex =
      RegExp(r'[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9\s#]');
  static final RegExp _battleTagDisallowedRegex =
      RegExp(r'[^가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9\s#]');

  static final RegExp _injectionDangerRegex =
      RegExp(r'''[\$\{\}\[\]'";]|--''');

  /// 닉네임#태그 입력용 Formatter (허용 문자 외 일체 입력 차단)
  static TextInputFormatter get battleTagInputFormatter =>
      FilteringTextInputFormatter.allow(_battleTagAllowedRegex);

  /// 일반 텍스트(모임명·공지·일정 등) 입력용 Formatter (NoSQL/SQL 인젝션 위험 문자 차단)
  static TextInputFormatter get safeTextInputFormatter =>
      FilteringTextInputFormatter.deny(_injectionDangerRegex);

  /// `소영   #7F2K` -> `소영#7F2K` 정규화 및 위험 문자 전면 제거
  static String normalizeBattleTag(String raw) {
    final cleaned = raw.replaceAll(_battleTagDisallowedRegex, '').trim();
    if (!cleaned.contains('#')) {
      return cleaned.replaceAll(RegExp(r'\s+'), ' ');
    }
    final hashIdx = cleaned.indexOf('#');
    final nick =
        cleaned.substring(0, hashIdx).trim().replaceAll(RegExp(r'\s+'), ' ');
    final tag = cleaned
        .substring(hashIdx + 1)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    if (nick.isEmpty || tag.isEmpty) return '';
    return '$nick#$tag';
  }

  /// Firestore 전송 전 일반 텍스트 살균 (인젝션 문자 전면 제거)
  static String sanitizeText(String raw) {
    return raw.replaceAll(_injectionDangerRegex, '').trim();
  }

  /// 닉네임 유효성 검사 (공백 제외 2~10자 + 비속어/음란어/시스템 예약어 차단)
  static const List<String> _kForbiddenNicknameTokens = [
    '운영자',
    '관리자',
    '하루칩',
    'admin',
    'administrator',
    'system',
    '시발',
    '씨발',
    '병신',
    '개새끼',
    '미친',
    '존나',
    '야동',
    '섹스',
    '성인',
    '음란',
  ];

  /// 유효하면 null, 위반 시 사용자 안내 에러 문구 반환
  static String? validateNickname(String raw) {
    final sanitized = sanitizeText(raw);
    final compact = sanitized.replaceAll(RegExp(r'\s+'), '');
    if (compact.length < 2 || compact.length > 10) {
      return '닉네임은 공백 제외 2~10자 이내로 입력해 주세요.';
    }
    final lower = compact.toLowerCase();
    for (final token in _kForbiddenNicknameTokens) {
      if (lower.contains(token)) {
        return '사용할 수 없는 금칙어 또는 예약어가 포함되어 있습니다.';
      }
    }
    return null;
  }

  /// CSPRNG(32 bytes) + SHA-256 단방향 해시 기반 백엔드 내부 `groupId` 생성
  static String generateSecureGroupId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final digest = sha256.convert(bytes).toString();
    return 'grp_${digest.substring(0, 24)}';
  }
}
