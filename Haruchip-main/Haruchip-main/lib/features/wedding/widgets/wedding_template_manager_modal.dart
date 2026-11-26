import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../data/wedding_standard_items.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_provider.dart';

/// 57종 이상 웨딩 마스터 추천 라이브러리 스마트 피커 모달
///
/// 1) 최상단: [직접 입력창] + [추가] 버튼 (추가 시 미완료·날짜 미정 상태로 안전 등록)
/// 2) 상단 슬림 검색바: 키워드 및 초성(예: 'ㅅㄴ', '한복') 즉시 필터링
/// 3) 5대 준비 영역 도메인 탭([1. 웨딩홀 & 본식] ~ [5. 뷰티 & 케어]) + 라운드 칩 그리드
/// 4) 하단 하루칩 버터 옐로우 [선택한 N개 추가하기] CTA
class WeddingTemplateManagerModal extends ConsumerStatefulWidget {
  const WeddingTemplateManagerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeddingTemplateManagerModal(),
    );
  }

  @override
  ConsumerState<WeddingTemplateManagerModal> createState() =>
      _WeddingTemplateManagerModalState();
}

class _WeddingTemplateManagerModalState
    extends ConsumerState<WeddingTemplateManagerModal> {
  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _chipGold = Color(0xFFF2B84B);
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  late final List<WeddingItem> _allTemplates;
  late final Set<String> _selectedIds;
  final List<WeddingItem> _newCustomItems = [];

  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  WeddingDomainGroup _selectedGroup = WeddingDomainGroup.hallAndCeremony;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allTemplates = createDefaultWeddingMasterItems();
    final currentItems = ref.read(weddingListProvider);
    _selectedIds = currentItems.map((i) => i.id).toSet();
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  WeddingStage _stageForDomain(WeddingDomainGroup group) {
    switch (group) {
      case WeddingDomainGroup.hallAndCeremony:
        return WeddingStage.hallAndPlanner;
      case WeddingDomainGroup.studimeAndShoot:
        return WeddingStage.studioShoot;
      case WeddingDomainGroup.ringAndSuit:
        return WeddingStage.studimeAndRing;
      case WeddingDomainGroup.honeymoonAndHome:
        return WeddingStage.houseAndLiving;
      case WeddingDomainGroup.beautyAndCare:
        return WeddingStage.finalCheckAndCeremony;
    }
  }

  void _toggleTemplate(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _addCustomItem() {
    final title = _customTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('추가할 일정명을 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentCount = _selectedIds.length + _newCustomItems.length;
    final customItem = WeddingItem(
      id: 'wedding-custom-${DateTime.now().microsecondsSinceEpoch}',
      orderIndex: currentCount + 1,
      title: title,
      standardOffsetDays: 30,
      stage: _stageForDomain(_selectedGroup),
      domainGroupOverride: _selectedGroup,
      isCompleted: false,
      targetDate: null,
    );

    setState(() {
      _newCustomItems.add(customItem);
      _customTitleController.clear();
    });
  }

  void _applySelection() {
    ref.read(weddingListProvider.notifier).syncSelectedTemplates(
          _selectedIds,
          _newCustomItems,
        );

    Navigator.pop(context);

    final total = _selectedIds.length + _newCustomItems.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('선택한 $total개의 결혼 준비 일정이 반영되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSearch = _searchQuery.trim().isNotEmpty;

    final visibleTemplates = _allTemplates.where((item) {
      if (hasSearch) {
        return matchesKoreanQuery(item.title, _searchQuery);
      }
      return item.domainGroup == _selectedGroup;
    }).toList();

    final visibleCustoms = _newCustomItems.where((item) {
      if (hasSearch) {
        return matchesKoreanQuery(item.title, _searchQuery);
      }
      return item.domainGroup == _selectedGroup;
    }).toList();

    final totalSelected = _selectedIds.length + _newCustomItems.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결혼 준비 항목 라이브러리',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _deepBrown,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          '영역별 추천 항목을 담고 날짜를 자유롭게 지정하세요',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8C7E6A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // (1) 최상단: 직접 입력창 + [추가] 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('wedding_picker_custom_input'),
                        controller: _customTitleController,
                        style: const TextStyle(fontSize: 13, color: _deepBrown),
                        decoration: InputDecoration(
                          hintText: '나만의 일정 직접 입력 (예: 아이폰 스냅 예약)',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          filled: true,
                          fillColor: _softGray,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addCustomItem(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      key: const Key('wedding_picker_custom_add_btn'),
                      onPressed: _addCustomItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _butterYellow,
                        foregroundColor: _deepBrown,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // (2) 상단 슬림 검색바 (키워드/초성 지원)
                TextField(
                  key: const Key('wedding_picker_search_input'),
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13, color: _deepBrown),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: '57종 추천 항목 검색 (예: 스냅, ㅅㄴ, 한복)',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: Color(0xFF8C7E6A),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 34),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(
                              Icons.cancel_rounded,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: _softGray,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 9),

                // (3) 5대 준비 영역 도메인 탭
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final group in WeddingDomainGroup.values)
                        _buildDomainTabChip(group),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F1EE)),

          // 라운드 칩 그리드 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hasSearch
                            ? '검색 결과 (${visibleTemplates.length + visibleCustoms.length})'
                            : '${_selectedGroup.labelKo} (${visibleTemplates.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8C7E6A),
                        ),
                      ),
                      const Text(
                        '칩 터치 시 담기 / 해제',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (visibleTemplates.isEmpty && visibleCustoms.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _softGray,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '일치하는 추천 항목이 없어요.\n상단 입력창에서 직접 추가해 보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF9CA3AF),
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final custom in visibleCustoms)
                          _buildCustomChip(custom),
                        for (final template in visibleTemplates)
                          _buildRecommendationChip(template),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // 하단 고정 CTA 버튼
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  key: const Key('wedding_picker_apply_btn'),
                  onPressed: _applySelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _butterYellow,
                    foregroundColor: _deepBrown,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '선택한 $totalSelected개 추가하기',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainTabChip(WeddingDomainGroup group) {
    final isSelected = _selectedGroup == group && _searchQuery.trim().isEmpty;
    final selectedInGroup = _allTemplates
        .where((i) => i.domainGroup == group && _selectedIds.contains(i.id))
        .length;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        key: Key('wedding_domain_tab_${group.name}'),
        onTap: () {
          setState(() {
            _selectedGroup = group;
            if (_searchQuery.isNotEmpty) {
              _searchController.clear();
              _searchQuery = '';
            }
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _butterYellow : _softGray,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.labelKo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _deepBrown : const Color(0xFF6B7280),
                ),
              ),
              if (selectedInGroup > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _deepBrown.withValues(alpha: 0.12)
                        : _chipGold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$selectedInGroup',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _deepBrown,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationChip(WeddingItem template) {
    final isSelected = _selectedIds.contains(template.id);
    return InkWell(
      key: Key('wedding_recommend_chip_${template.id}'),
      onTap: () => _toggleTemplate(template.id),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _butterYellow : _softGray,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: isSelected ? _deepBrown : const Color(0xFF8C7E6A),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                template.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _deepBrown : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomChip(WeddingItem custom) {
    return InkWell(
      onTap: () => setState(() => _newCustomItems.remove(custom)),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4CC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_task_rounded, size: 13, color: _chipGold),
            const SizedBox(width: 4),
            Text(
              custom.title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _deepBrown,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close_rounded, size: 13, color: Color(0xFF8C7E6A)),
          ],
        ),
      ),
    );
  }
}
