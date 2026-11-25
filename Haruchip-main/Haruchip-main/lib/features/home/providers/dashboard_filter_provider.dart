import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 메인 대시보드(칩 데이) 노출 카테고리 다중 필터 상태
/// 빈 Set = 모든 보이는 카테고리 노출 / 비어있지 않으면 선택된 categoryKey만 노출
final dashboardCategoryFilterProvider =
    StateProvider<Set<String>>((ref) => const <String>{});
