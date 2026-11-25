import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/app_permissions.dart';
import '../providers/app_permissions_provider.dart';
import '../widgets/toss_funnel_components.dart';
import 'category_selection_screen.dart';
import 'login_screen.dart';

/// 토스(Toss) 스타일 온보딩 퍼널 [Step 1: 앱 접근 권한 안내]
/// 아이폰 SE/미니 등 소형 뷰포트에서도 무스크롤(Zero-Scroll)로 하단 액션 버튼까지 완전 노출되도록 컴팩트 반응형 핏 적용.
class AppPermissionScreen extends ConsumerWidget {
  const AppPermissionScreen({
    super.key,
    this.onNext,
    this.isSettingsMode = false,
  });

  final VoidCallback? onNext;
  final bool isSettingsMode;

  void _handleContinue(BuildContext context) {
    if (onNext != null) {
      onNext!();
      return;
    }
    if (isSettingsMode) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      SlideFadePageRoute(page: const CategorySelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(appPermissionsProvider);
    final notifier = ref.read(appPermissionsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            if (!isSettingsMode)
              TossStepIndicator(
                currentStep: 1,
                totalSteps: 3,
                onBack: () => Navigator.maybePop(context),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF333D4B),
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '앱 접근 권한 관리',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
              ),

            // 반응형 뷰포트 바디 (Zero-Scroll 핏)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 560;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // 1. 상단 타이틀 & 설명 문구 (19~21sp & 13sp 다운스케일)
                        Text(
                          '하루칩을 더 편리하게 쓰기 위해\n접근 권한이 필요해요',
                          style: TextStyle(
                            color: const Color(0xFF191F28),
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: isCompact ? 4 : 6),
                        Text(
                          '선택 권한은 허용하지 않아도 해당 기능 외 기본 서비스를 계속 이용하실 수 있어요.',
                          style: TextStyle(
                            color: const Color(0xFF8B95A1),
                            fontSize: isCompact ? 12 : 13,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 12),

                        // 2. 전체 동의하기 카드
                        InkWell(
                          onTap: () => notifier.toggleAll(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: isCompact ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: permissions.allAgreed
                                  ? const Color(0xFFE8F3FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: permissions.allAgreed
                                    ? const Color(0xFF3182F6)
                                    : const Color(0xFFE5E8EB),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: permissions.allAgreed
                                        ? const Color(0xFF3182F6)
                                        : const Color(0xFFF2F4F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: permissions.allAgreed
                                        ? Colors.white
                                        : const Color(0xFFB0B8C1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    '전체 동의하기',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF191F28),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '선택 항목 포함',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7684),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 8 : 10),

                        // 3. 개별 권한 항목 리스트 (컴팩트 카드 핏, 8~10dp 수직 간격 & 10~12dp 안쪽 패딩)
                        Expanded(
                          child: ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: kAppPermissionItems.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: isCompact ? 6 : 8),
                            itemBuilder: (context, index) {
                              final item = kAppPermissionItems[index];
                              return _buildPermissionRow(
                                item: item,
                                isEnabled: permissions.isEnabled(item.key),
                                onToggle: () => notifier.toggle(item.key),
                                isCompact: isCompact,
                              );
                            },
                          ),
                        ),

                        if (!isSettingsMode) ...[
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                '이미 계정이 있으신가요? 로그인하기',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7684),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // 4. 하단 액션 버튼 (바닥 마진 축소 & 안전영역 컴팩트 밀착)
            GlassFloatingButton(
              label: isSettingsMode ? '설정 완료' : '동의하고 계속하기',
              onPressed: () => _handleContinue(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required PermissionItemInfo item,
    required bool isEnabled,
    required VoidCallback onToggle,
    required bool isCompact,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 11,
          vertical: isCompact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF3182F6).withValues(alpha: 0.35)
                : const Color(0xFFF2F4F6),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isEnabled
                    ? const Color(0xFFE8F3FF)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: isEnabled
                    ? const Color(0xFF3182F6)
                    : const Color(0xFF6B7684),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.isRequired ? '필수' : '선택',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: item.isRequired
                                ? const Color(0xFFE0523F)
                                : const Color(0xFF6B7684),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191F28),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B95A1),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isEnabled,
                activeColor: const Color(0xFF3182F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => onToggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
