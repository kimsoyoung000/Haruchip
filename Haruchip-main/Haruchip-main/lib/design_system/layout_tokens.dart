import 'package:flutter/material.dart';

/// 하루칩 전역 레이아웃 & 럭셔리 화이트 디자인 토큰.
///
/// 모든 메인 대시보드 및 카테고리 상세 화면이 동일한 좌우 여백,
/// 카드 간 간격, 카드 내부 패딩, 플랫 섀도우를 공유하도록 표준화한다.
class AppLayoutTokens {
  AppLayoutTokens._();

  /// 전 화면 표준 좌우 여백 (14dp)
  static const double screenHorizontalMargin = 14.0;

  /// 카드와 카드 사이 표준 상하 간격 (9dp, 8~10dp 범위)
  static const double cardVerticalGap = 9.0;

  /// 카드 내부 표준 패딩 (horizontal: 14dp, vertical: 12dp)
  static const EdgeInsets cardInternalPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  /// 카테고리 상세 화면 표준 스크롤 뷰 패딩
  static const EdgeInsets detailScreenPadding = EdgeInsets.fromLTRB(
    screenHorizontalMargin,
    10,
    screenHorizontalMargin,
    32,
  );

  /// 메인 대시보드 표준 스크롤 뷰 패딩
  static const EdgeInsets dashboardScreenPadding = EdgeInsets.fromLTRB(
    screenHorizontalMargin,
    6,
    screenHorizontalMargin,
    24,
  );

  /// 무테두리 순백색 카드용 초미세 소프트 섀도우
  static List<BoxShadow> get luxuryCardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// 하단 네비게이션바 상단 초경량 디바이더 라인
  static const Border navBarTopDivider = Border(
    top: BorderSide(color: Color(0xFFF0F0F2), width: 0.8),
  );
}
