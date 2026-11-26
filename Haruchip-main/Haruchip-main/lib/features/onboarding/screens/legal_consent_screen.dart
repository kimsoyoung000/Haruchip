import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/layout_tokens.dart';
import '../models/legal_consent.dart';
import '../providers/legal_consent_provider.dart';
import '../widgets/toss_funnel_components.dart';
import 'app_permission_screen.dart';
import 'login_screen.dart';

/// 법적 효력 약관 동의 화면 (개인정보보호법 · 정보통신망법 · 스토어 심사 준수)
///
/// - 기기 OS 접근 권한 화면([AppPermissionScreen])과 엄격히 분리되어 선행한다.
/// - [필수 1] 서비스 이용약관 동의 + 전문 보기 모달
/// - [필수 2] 개인정보 수집 및 이용 동의 + 전문 보기 모달
/// - [선택 1] 혜택 및 마케팅 정보 수신 동의 (체크 시 일시 토스트 + DB Timestamp 기록)
/// - 필수 2종 모두 체크 전까지 [동의하고 시작하기] 버튼 비활성화
class LegalConsentScreen extends ConsumerWidget {
  const LegalConsentScreen({
    super.key,
    this.onNext,
  });

  final VoidCallback? onNext;

  void _showLegalDocumentModal(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.65,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chipYellowBg,
                      foregroundColor: AppColors.chipYellowText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(legalConsentProvider.notifier);
    final marketingTs = await notifier.commitConsentToDatabase();
    if (!context.mounted) return;

    if (marketingTs != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              LegalConsentState.formatMarketingConsentToast(marketingTs),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    }

    if (onNext != null) {
      onNext!();
      return;
    }

    Navigator.of(context).push(
      SlideFadePageRoute(page: const AppPermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(legalConsentProvider);
    final notifier = ref.read(legalConsentProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.cleanCanvasBg,
      body: SafeArea(
        child: Column(
          children: [
            TossStepIndicator(
              currentStep: 1,
              totalSteps: 3,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayoutTokens.screenHorizontalMargin + 4,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '하루칩 시작 전\n약관에 동의해 주세요',
                      style: TextStyle(
                        color: Color(0xFF191F28),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '안전한 서비스 이용과 개인정보 보호를 위해 필수 약관 동의가 필요합니다.',
                      style: TextStyle(
                        color: Color(0xFF8B95A1),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 전체 동의하기 카드
                    InkWell(
                      key: const Key('legal_consent_agree_all'),
                      onTap: () {
                        final willAgreeMarketing = !consent.allAgreed;
                        notifier.toggleAll();
                        if (willAgreeMarketing) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  LegalConsentState.formatMarketingConsentToast(
                                    DateTime.now(),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: consent.allAgreed
                              ? const Color(0xFFFFFBEB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: consent.allAgreed
                                ? AppColors.chipGoldOutline
                                : const Color(0xFFE5E8EB),
                            width: 1.4,
                          ),
                          boxShadow: AppLayoutTokens.luxuryCardShadow,
                        ),
                        child: Row(
                          children: [
                            _CheckCircle(checked: consent.allAgreed),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '전체 동의하기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF191F28),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '필수 · 선택 포함',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 개별 법적 약관 3종 (필수 2종 + 선택 1종)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppLayoutTokens.luxuryCardShadow,
                      ),
                      child: Column(
                        children: [
                          _LegalTermRow(
                            rowKey: const Key('legal_consent_terms'),
                            viewKey: const Key('legal_consent_terms_view'),
                            badge: '필수',
                            isRequired: true,
                            title: '서비스 이용약관 동의',
                            checked: consent.serviceTermsAgreed,
                            onToggle: notifier.toggleServiceTerms,
                            onViewDetail: () => _showLegalDocumentModal(
                              context,
                              title: HaruLegalDocuments.serviceTermsTitle,
                              body: HaruLegalDocuments.serviceTermsBody,
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          _LegalTermRow(
                            rowKey: const Key('legal_consent_privacy'),
                            viewKey: const Key('legal_consent_privacy_view'),
                            badge: '필수',
                            isRequired: true,
                            title: '개인정보 수집 및 이용 동의',
                            subtitle: '수집 항목, 이용 목적, 보유 기간 안내',
                            checked: consent.privacyPolicyAgreed,
                            onToggle: notifier.togglePrivacyPolicy,
                            onViewDetail: () => _showLegalDocumentModal(
                              context,
                              title: HaruLegalDocuments.privacyPolicyTitle,
                              body: HaruLegalDocuments.privacyPolicyBody,
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          _LegalTermRow(
                            rowKey: const Key('legal_consent_marketing'),
                            viewKey: const Key('legal_consent_marketing_view'),
                            badge: '선택',
                            isRequired: false,
                            title: '혜택 및 마케팅 정보 수신 동의',
                            subtitle: '알림 / 문자 / 카카오톡 (동의 시 일시 기록)',
                            checked: consent.marketingAgreed,
                            onToggle: () {
                              final agreedAt = notifier.toggleMarketing();
                              if (agreedAt != null) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        LegalConsentState
                                            .formatMarketingConsentToast(
                                          agreedAt,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                              }
                            },
                            onViewDetail: () => _showLegalDocumentModal(
                              context,
                              title: HaruLegalDocuments.marketingConsentTitle,
                              body: HaruLegalDocuments.marketingConsentBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '이미 계정이 있으신가요? 로그인하기',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7684),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 CTA: 필수 2종 모두 체크 전까지 비활성화
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  key: const Key('legal_consent_submit_btn'),
                  onPressed: consent.canProceed
                      ? () => _handleSubmit(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chipYellowBg,
                    foregroundColor: AppColors.chipYellowText,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '동의하고 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.chipYellowText : const Color(0xFFF2F4F6),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        size: 14,
        color: checked ? AppColors.chipYellowBg : const Color(0xFFB0B8C1),
      ),
    );
  }
}

class _LegalTermRow extends StatelessWidget {
  const _LegalTermRow({
    required this.rowKey,
    required this.viewKey,
    required this.badge,
    required this.isRequired,
    required this.title,
    this.subtitle,
    required this.checked,
    required this.onToggle,
    required this.onViewDetail,
  });

  final Key rowKey;
  final Key viewKey;
  final String badge;
  final bool isRequired;
  final String title;
  final String? subtitle;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: rowKey,
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  _CheckCircle(checked: checked),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isRequired
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isRequired
                                      ? const Color(0xFFE11D48)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF191F28),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B95A1),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            key: viewKey,
            onPressed: onViewDetail,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '보기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
