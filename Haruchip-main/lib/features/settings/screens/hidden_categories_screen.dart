import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/providers/category_provider.dart';

/// 대시보드 숨김 카테고리 보관함 관리 화면
class HiddenCategoriesScreen extends ConsumerWidget {
  const HiddenCategoriesScreen({super.key});

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenCategories = ref.watch(hiddenCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.protoHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '대시보드 숨김 카드 보관함',
          style: AppTypography.cardLabel.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
      ),
      body: Column(
        children: [
          // 안내 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF0FDF4),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: Color(0xFF16A34A)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '숨긴 카테고리는 데이터가 100% 영구 보존되며, 홈 대시보드에서만 일시적으로 감춰집니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: hiddenCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📦', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          '숨겨진 카테고리가 없습니다.',
                          style: AppTypography.heading2.copyWith(fontSize: 16, color: AppColors.protoHeading),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '대시보드 편집 모드에서 원치 않는 카드를 숨길 수 있어요',
                          style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: hiddenCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = hiddenCategories[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(category.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: AppTypography.cardLabel.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.protoHeading,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    category.hiddenAt != null
                                        ? '숨김 처리일: ${_formatDate(category.hiddenAt)}'
                                        : '대시보드 숨김 보관 중',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 11.5,
                                      color: AppColors.protoSubtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(categoryListProvider.notifier).unhideCategory(category.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✨ [${category.name}] 카테고리가 대시보드에 다시 표시됩니다!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_rounded, size: 15),
                              label: const Text('대시보드에 복구'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
