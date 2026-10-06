import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 카테고리별 커스텀 사용자 정의 태그 저장 및 영구 관리 StateNotifier
class CategoryCustomTagsNotifier extends StateNotifier<Map<String, List<String>>> {
  CategoryCustomTagsNotifier() : super(const {});

  /// 특정 카테고리에 새 커스텀 태그 추가
  void addCustomTag(String categoryKey, String tag) {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return;

    final currentList = state[categoryKey] ?? [];
    if (currentList.contains(cleanTag)) return;

    state = {
      ...state,
      categoryKey: [...currentList, cleanTag],
    };
  }

  /// 특정 카테고리에서 커스텀 태그 삭제
  void removeCustomTag(String categoryKey, String tag) {
    final currentList = state[categoryKey] ?? [];
    if (!currentList.contains(tag)) return;

    state = {
      ...state,
      categoryKey: currentList.where((t) => t != tag).toList(),
    };
  }
}

/// 전역 카테고리별 커스텀 태그 Provider
final categoryCustomTagsProvider =
    StateNotifierProvider<CategoryCustomTagsNotifier, Map<String, List<String>>>((ref) {
  return CategoryCustomTagsNotifier();
});
