import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/screens/main_shell_screen.dart';
import '../../../services/storage/user_session.dart';
import 'legal_consent_screen.dart';

/// 앱 시작 스플래시 화면 (자동 전환)
///
/// 요구사항 명세:
/// - 로고 에셋(달력 아이콘)을 중앙에 배치
///   * 상단: 하루칩 로고 (미니멀 소프트 섀도우)
///   * 중앙 타이틀: HaruChip
///   * 서브 텍스트: "하루의 소중한 조각들을 담아봐요"
/// - 별도의 '시작하기' 터치 버튼 없이, 1.8초~2.0초 간 부드러운 페이드인/아웃 후
///   자동으로 화면 전환:
///   * 기존 로그인 세션 유지 유저 -> 메인 대시보드([MainShellScreen])로 즉시 진입
///   * 최초 진입 또는 미인증 유저 -> 온보딩 1단계([AppPermissionScreen])로 매끄럽게 연결
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onNext,
    this.isLoggedIn,
  });

  /// 다음 단계로 넘어갈 때 호출되는 콜백 (주로 테스트 환경)
  final VoidCallback? onNext;

  /// 기존 로그인 세션 유지 여부
  final bool? isLoggedIn;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1.9초 전체 주기: 페이드인 (0~600ms) -> 유지 (600~1500ms) -> 페이드아웃 (1500~1900ms)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20.0,
      ),
    ]).animate(_animController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60.0,
      ),
    ]).animate(_animController);

    _animController.forward();

    // 1.9초 후 자동으로 다음 온보딩 퍼널 단계로 이동
    _navigationTimer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      _proceedToNext();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNext() async {
    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }
    // 로그인 세션이 있으면 서버에 저장된 내 데이터를 다 불러온 뒤에 홈을 그린다.
    try {
      await ProviderScope.containerOf(context, listen: false)
          .read(userSessionProvider.notifier)
          .waitUntilReady();
    } catch (_) {}
    if (!mounted) return;
    final loggedIn = widget.isLoggedIn ??
        (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null);

    final Widget targetScreen = loggedIn
        ? const MainShellScreen()
        : const LegalConsentScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 미니멀 버터 옐로우(#FFE699) 소프트 칩 포인트
                Container(
                  width: 44,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE699),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),

                // 영문 미니멀 서브타이틀: HARUCHIP
                const Text(
                  'HARUCHIP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A6A52),
                    letterSpacing: 3.2,
                  ),
                ),
                const SizedBox(height: 8),

                // 한글 볼드 메인 로고 타이포: 하루칩 (#3A2E1A, 자간 -0.5)
                const Text(
                  '하루칩',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A2E1A),
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),

                // 감성 미니멀 서브카피
                const Text(
                  '매일의 디데이, 일상의 조각을 맞추다',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
