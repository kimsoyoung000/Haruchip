import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/providers/category_provider.dart';
import '../data/onboarding_categories.dart';
import '../providers/category_selection_provider.dart';
import '../widgets/category_selection_card.dart';
import '../widgets/toss_funnel_components.dart';
import 'onboarding_complete_screen.dart';

/// 토스(Toss) 스타일 온보딩 퍼널 [Step 2: 관심 카테고리 다중 선택]
/// 아이폰 SE/미니(높이 667dp 이하) 기종에서도 무스크롤(Zero-Scroll)로 하단 [다음] 버튼까지 완벽히 들어오는 반응형 핏
class CategorySelectionScreen extends ConsumerWidget {
  const CategorySelectionScreen({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKeys = ref.watch(categorySelectionProvider);
    final canProceed = ref.watch(canProceedFromCategorySelectionProvider);

    void handleToggle(String key) {
      ref.read(categorySelectionProvider.notifier).toggle(key);
    }

    void handleNext() {
      if (!canProceed) return;

      final notifier = ref.read(categoryListProvider.notifier);
      final types = kOnboardingCategories
          .where((c) => selectedKeys.contains(c.key))
          .map((c) => (key: c.key, labelKo: c.labelKo, emoji: c.emoji));
      notifier.seedFromKeys(types);

      if (onNext != null) {
        onNext!();
        return;
      }
      // 온보딩 3단계(대시보드 스타일 선택) 영구 삭제 -> 즉시 완료 화면 및 메인 대시보드 진입
      Navigator.of(context).push(
        SlideFadePageRoute(page: const OnboardingCompleteScreen()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            TossStepIndicator(
              currentStep: 3,
              totalSteps: 3,
              onBack: () => Navigator.maybePop(context),
            ),
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
                        // 1. 상단 타이틀 폰트 크기: 19~21sp로 다운스케일
                        Text(
                          '관심 있는 카테고리를 골라주세요',
                          style: TextStyle(
                            color: const Color(0xFF191F28),
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: isCompact ? 4 : 6),
                        // 2. 설명 보조 문구: 13sp로 축소, 행간 압축
                        Text(
                          '나에게 필요한 카테고리를 선택하세요 (중복 선택 가능)',
                          style: TextStyle(
                            color: const Color(0xFF8B95A1),
                            fontSize: isCompact ? 12 : 13,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isCompact ? 10 : 14),

                        // 3. 카테고리 칩 3열 그리드 (Zero-Scroll 뷰포트 핏)
                        Expanded(
                          child: GridView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: isCompact ? 6 : 8,
                              crossAxisSpacing: isCompact ? 6 : 8,
                              childAspectRatio: isCompact ? 2.4 : 2.5,
                            ),
                            itemCount: kOnboardingCategories.length,
                            itemBuilder: (context, index) {
                              final category = kOnboardingCategories[index];
                              return CategorySelectionCard(
                                category: category,
                                selected: selectedKeys.contains(category.key),
                                onTap: () => handleToggle(category.key),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ),
            GlassFloatingButton(
              label: canProceed ? '하루칩 시작하기' : '관심 카테고리를 1개 이상 골라주세요',
              enabled: canProceed,
              onPressed: handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
