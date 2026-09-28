import 'package:flutter/material.dart';

import '../../../design_system/typography.dart';
import 'login_screen.dart';

/// 온보딩 플로우의 "스플래시" 단계 — 새로 추가하는 첫 화면.
///
/// 전체 온보딩 순서(CLAUDE.md §8):
/// **스플래시** → 권한요청 → 로그인 → 카테고리 선택(다중) → 대시보드
/// 뷰모드 → 위젯 안내
///
/// haruchip_app.html `renderOnboardingHTML()`의 `onboardingStep === 1`
/// 분기(194~201줄)를 그대로 재현한다(§5/§6): 노란 그라디언트 배경 +
/// 🌻 아이콘 박스 + "스마트 디데이 & 일정 관리" 배지 + 헤드라인/부제 +
/// "시작하기" 버튼. 권한요청 단계는 네이티브 권한 다이얼로그가 필요해
/// 이 담당자 범위 밖이다 — 이 화면은 곧바로 로그인 화면으로 이동한다.
///
/// [onNext]를 넘기면(주로 테스트) 그 콜백을 대신 호출하고, 넘기지 않으면
/// 다음 단계인 [LoginScreen]으로 실제 이동한다(다른 온보딩 화면들과 동일한
/// 패턴).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.onNext});

  /// 다음 단계(로그인)로 넘어갈 때 호출된다.
  final VoidCallback? onNext;

  void _handleStart(BuildContext context) {
    if (onNext != null) {
      onNext!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEB), Color(0xFFFFFDF9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFDF00), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text('🌻', style: TextStyle(fontSize: 44)),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                      ),
                      child: Text(
                        '나의 소중한 시간 조각들',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '하루칩',
                      style: AppTypography.heading1.copyWith(
                        color: const Color(0xFF1E293B),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '소중한 날들을 더 특별하게,\n하루칩과 함께 시작해요',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMuted.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleStart(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '시작하기',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
