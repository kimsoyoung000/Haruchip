import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../military/models/military_rank.dart';
import '../../military/providers/military_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

/// 1. 군대 (Military) 온보딩 설정 바텀시트
Future<bool?> showMilitaryOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MilitaryOnboardingSheet(category: category),
  );
}

class _MilitaryOnboardingSheet extends ConsumerStatefulWidget {
  const _MilitaryOnboardingSheet({required this.category});

  final CategoryModel category;

  @override
  ConsumerState<_MilitaryOnboardingSheet> createState() => _MilitaryOnboardingSheetState();
}

class _MilitaryOnboardingSheetState extends ConsumerState<_MilitaryOnboardingSheet> {
  late MilitaryBranch _branch;
  late DateTime _enlistDate;
  late DateTime _dischargeDate;
  DateTime? _nextLeaveDate;

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    if (meta != null && meta['enlistDate'] != null) {
      _branch = MilitaryBranch.values.firstWhere(
        (b) => b.name == meta['branch'],
        orElse: () => MilitaryBranch.army,
      );
      _enlistDate = DateTime.parse(meta['enlistDate'] as String);
      _dischargeDate = meta['dischargeDate'] != null
          ? DateTime.parse(meta['dischargeDate'] as String)
          : defaultDischargeDate(_enlistDate, _branch);
    } else {
      final service = ref.read(militaryServiceProvider);
      _branch = service.branch;
      _enlistDate = service.enlistDate;
      _dischargeDate = service.dischargeDate;
      _nextLeaveDate = service.nextLeaveDate;
    }
  }

  void _onBranchSelected(MilitaryBranch branch) {
    setState(() {
      _branch = branch;
      _dischargeDate = defaultDischargeDate(_enlistDate, branch);
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    // 1. 군대 서비스 프로바이더 갱신
    ref.read(militaryServiceProvider.notifier).setService(
          enlistDate: _enlistDate,
          dischargeDate: _dischargeDate,
          branch: _branch,
        );
    if (_nextLeaveDate != null) {
      ref.read(militaryServiceProvider.notifier).setNextLeave(_nextLeaveDate);
    }

    // 2. 카테고리 메타데이터 갱신
    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'branch': _branch.name,
        'enlistDate': _enlistDate.toIso8601String(),
        'dischargeDate': _dischargeDate.toIso8601String(),
        if (_nextLeaveDate != null) 'nextLeaveDate': _nextLeaveDate!.toIso8601String(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    // 3. 플랜 아이템 자동 추가/보정 (입대일 N일째 & 전역일 D-Day)
    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    // 입대일 아이템 추가
    final hasEnlist = existingItems.any((i) => i.title.contains('입대'));
    if (!hasEnlist) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-enlist-${DateTime.now().microsecondsSinceEpoch}',
              title: '입대일',
              date: _enlistDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.daysCount,
            ),
          );
    }

    // 전역일 아이템 추가
    final hasDischarge = existingItems.any((i) => i.title.contains('전역'));
    if (!hasDischarge) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-discharge-${DateTime.now().microsecondsSinceEpoch}',
              title: '전역일 (만기제대)',
              date: _dischargeDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.dday,
            ),
          );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final enlist = DateTime(_enlistDate.year, _enlistDate.month, _enlistDate.day);
    final discharge = DateTime(_dischargeDate.year, _dischargeDate.month, _dischargeDate.day);

    final totalDays = discharge.difference(enlist).inDays;
    final elapsedDays = today.difference(enlist).inDays;
    final progress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 0.0;
    final daysLeft = discharge.difference(today).inDays;

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎖️ 복무 정보 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 복무율 미리보기 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_branch.labelKo} 복무율 ${(progress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 15),
                          ),
                          Text(
                            daysLeft > 0 ? 'D-$daysLeft' : (daysLeft == 0 ? 'D-Day' : 'D+${-daysLeft}'),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15803D), fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFDCFCE7),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. 군종 선택
                const Text('군종 선택', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final branch in MilitaryBranch.values)
                      ChoiceChip(
                        label: Text('${branch.labelKo} (${totalServiceMonths[branch]}개월)'),
                        selected: _branch == branch,
                        selectedColor: const Color(0xFF007AFF),
                        backgroundColor: const Color(0xFFF2F2F7),
                        labelStyle: TextStyle(
                          color: _branch == branch ? Colors.white : AppColors.protoHeading,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        onSelected: (_) => _onBranchSelected(branch),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. 입대일
                const Text('입대일 (시작일)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _enlistDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _enlistDate = picked;
                        _dischargeDate = defaultDischargeDate(picked, _branch);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_enlistDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. 전역일 (수동 보정 가능)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('전역일 (예정일)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      '자동 계산 (${totalServiceMonths[_branch]}개월 기준)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _dischargeDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _dischargeDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_dischargeDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. 다음 휴가일 (선택)
                const Text('다음 휴가일 (선택)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _nextLeaveDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _nextLeaveDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _nextLeaveDate != null ? _formatDate(_nextLeaveDate!) : '휴가일 설정 안 됨 (선택 사항)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _nextLeaveDate != null ? const Color(0xFF007AFF) : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.beach_access_rounded, size: 18, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: const Text('설정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. 아기 (Baby) 온보딩 설정 바텀시트
Future<bool?> showBabyOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BabyOnboardingSheet(category: category),
  );
}

class _BabyOnboardingSheet extends ConsumerStatefulWidget {
  const _BabyOnboardingSheet({required this.category});

  final CategoryModel category;

  @override
  ConsumerState<_BabyOnboardingSheet> createState() => _BabyOnboardingSheetState();
}

class _BabyOnboardingSheetState extends ConsumerState<_BabyOnboardingSheet> {
  late TextEditingController _nameController;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    _nameController = TextEditingController(text: meta?['babyName'] as String? ?? '우리 아기 👶');
    _birthDate = meta?['birthDate'] != null
        ? DateTime.parse(meta!['birthDate'] as String)
        : DateTime.now().subtract(const Duration(days: 100));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calculateBabyAge(DateTime birth) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bDate = DateTime(birth.year, birth.month, birth.day);
    final days = today.difference(bDate).inDays + 1;
    if (days <= 0) return '출생 예정';

    var months = (today.year - bDate.year) * 12 + (today.month - bDate.month);
    if (today.day < bDate.day) months -= 1;
    if (months < 0) months = 0;

    return '$days일째 ($months개월)';
  }

  void _save() {
    final name = _nameController.text.trim().isEmpty ? '우리 아기 👶' : _nameController.text.trim();
    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'babyName': name,
        'birthDate': _birthDate.toIso8601String(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    final hasBirth = existingItems.any((i) => i.title.contains('탄생') || i.title.contains('태어난'));
    if (!hasBirth) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-baby-${DateTime.now().microsecondsSinceEpoch}',
              title: '$name 태어난 날',
              date: _birthDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.daysCount,
            ),
          );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final ageText = _calculateBabyAge(_birthDate);

    return Container(
      height: mediaQuery.size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '👶 아기 정보 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 미리보기 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Text('👶', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.trim().isEmpty ? '우리 아기' : _nameController.text.trim(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ageText,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 아기 이름
                const Text('아기 이름 / 태명', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '예: 우리 아기, 튼튼이',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // 탄생일 (생년월일)
                const Text('탄생일 (생년월일)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _birthDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _birthDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_birthDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: const Text('설정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. 솔로 (Solo) 온보딩 설정 바텀시트
Future<bool?> showSoloOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SoloOnboardingSheet(category: category),
  );
}

class _SoloOnboardingSheet extends ConsumerStatefulWidget {
  const _SoloOnboardingSheet({required this.category});

  final CategoryModel category;

  @override
  ConsumerState<_SoloOnboardingSheet> createState() => _SoloOnboardingSheetState();
}

class _SoloOnboardingSheetState extends ConsumerState<_SoloOnboardingSheet> {
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    _startDate = meta?['soloStartDate'] != null
        ? DateTime.parse(meta!['soloStartDate'] as String)
        : DateTime.now().subtract(const Duration(days: 30));
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'soloStartDate': _startDate.toIso8601String(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    final hasSolo = existingItems.any((i) => i.title.contains('솔로'));
    if (!hasSolo) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-solo-${DateTime.now().microsecondsSinceEpoch}',
              title: '솔로 시작일',
              date: _startDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.daysCount,
            ),
          );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final days = today.difference(start).inDays + 1;

    return Container(
      height: mediaQuery.size.height * 0.70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🌟 솔로 시작일 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('자유로운 솔로 라이프', style: TextStyle(fontSize: 13, color: Color(0xFF7E22CE))),
                          Text(
                            '솔로 ${days > 0 ? days : 1}일째',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF9333EA)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('솔로 시작일 (싱글/이별 시작일)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _startDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_startDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: const Text('설정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. 덕질 (Fandom) 온보딩 설정 바텀시트
Future<bool?> showFandomOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FandomOnboardingSheet(category: category),
  );
}

class _FandomOnboardingSheet extends ConsumerStatefulWidget {
  const _FandomOnboardingSheet({required this.category});

  final CategoryModel category;

  @override
  ConsumerState<_FandomOnboardingSheet> createState() => _FandomOnboardingSheetState();
}

class _FandomOnboardingSheetState extends ConsumerState<_FandomOnboardingSheet> {
  late TextEditingController _starNameController;
  late DateTime _fandomStartDate;

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    _starNameController = TextEditingController(text: meta?['starName'] as String? ?? '최애 ⭐');
    _fandomStartDate = meta?['fandomStartDate'] != null
        ? DateTime.parse(meta!['fandomStartDate'] as String)
        : DateTime.now().subtract(const Duration(days: 100));
  }

  @override
  void dispose() {
    _starNameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final starName = _starNameController.text.trim().isEmpty ? '최애 ⭐' : _starNameController.text.trim();
    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'starName': starName,
        'fandomStartDate': _fandomStartDate.toIso8601String(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    final hasFandom = existingItems.any((i) => i.title.contains('입덕'));
    if (!hasFandom) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-fandom-${DateTime.now().microsecondsSinceEpoch}',
              title: '$starName 입덕일',
              date: _fandomStartDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.daysCount,
            ),
          );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(_fandomStartDate.year, _fandomStartDate.month, _fandomStartDate.day);
    final days = today.difference(start).inDays + 1;

    return Container(
      height: mediaQuery.size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💜 덕질 / 최애 정보 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF4FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0ABFC)),
                  ),
                  child: Row(
                    children: [
                      const Text('💜', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _starNameController.text.trim().isEmpty ? '우리 최애' : _starNameController.text.trim(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '함께한 지 ${days > 0 ? days : 1}일째',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC026D3)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('최애 이름 / 그룹명', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _starNameController,
                  decoration: InputDecoration(
                    hintText: '예: 아이유, BTS, 나애리',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                const Text('입덕 날짜 (처음 반한 날)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _fandomStartDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _fandomStartDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_fandomStartDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: const Text('설정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. 반려동물 (Pet) 온보딩 설정 바텀시트 (다중 등록 지원)
Future<bool?> showPetOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PetOnboardingSheet(category: category),
  );
}

class _PetOnboardingItem {
  _PetOnboardingItem({
    required this.name,
    required this.icon,
    required this.adoptionDate,
    this.birthDate,
    this.isBirthUnknown = false,
    this.approxAgeText = '',
  });

  String name;
  String icon;
  DateTime adoptionDate;
  DateTime? birthDate;
  bool isBirthUnknown;
  String approxAgeText;
}

class _PetOnboardingSheet extends ConsumerStatefulWidget {
  const _PetOnboardingSheet({required this.category});

  final CategoryModel category;

  @override
  ConsumerState<_PetOnboardingSheet> createState() => _PetOnboardingSheetState();
}

class _PetOnboardingSheetState extends ConsumerState<_PetOnboardingSheet> {
  final List<_PetOnboardingItem> _pets = [];

  static const List<({String icon, String label})> kPetIconOptions = [
    (icon: '🐶', label: '강아지'),
    (icon: '🐱', label: '고양이'),
    (icon: '🐹', label: '햄스터'),
    (icon: '🐰', label: '토끼'),
    (icon: '🦜', label: '앵무새'),
    (icon: '🐠', label: '물고기'),
    (icon: '🐢', label: '거북이'),
    (icon: '🦔', label: '고슴도치'),
    (icon: '🦎', label: '도마뱀'),
    (icon: '🐾', label: '기타'),
  ];

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    final petListJson = meta?['pets'] as List<dynamic>?;
    if (petListJson != null && petListJson.isNotEmpty) {
      for (final item in petListJson) {
        final m = item as Map<String, dynamic>;
        _pets.add(_PetOnboardingItem(
          name: m['name'] as String? ?? '댕댕이',
          icon: m['icon'] as String? ?? '🐶',
          adoptionDate: m['adoptionDate'] != null
              ? DateTime.parse(m['adoptionDate'] as String)
              : DateTime.now().subtract(const Duration(days: 200)),
          birthDate: m['birthDate'] != null ? DateTime.parse(m['birthDate'] as String) : null,
          isBirthUnknown: m['isBirthUnknown'] as bool? ?? false,
          approxAgeText: m['approxAgeText'] as String? ?? '',
        ));
      }
    } else {
      _pets.add(_PetOnboardingItem(
        name: '댕댕이',
        icon: '🐶',
        adoptionDate: DateTime.now().subtract(const Duration(days: 200)),
        birthDate: DateTime.now().subtract(const Duration(days: 365)),
      ));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'pets': _pets.map((p) => {
          'name': p.name,
          'icon': p.icon,
          'adoptionDate': p.adoptionDate.toIso8601String(),
          if (p.birthDate != null) 'birthDate': p.birthDate!.toIso8601String(),
          'isBirthUnknown': p.isBirthUnknown,
          'approxAgeText': p.approxAgeText,
        }).toList(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    for (final pet in _pets) {
      final petAdoptTitle = '${pet.name} 만난 날';
      if (!existingItems.any((i) => i.title == petAdoptTitle)) {
        ref.read(planListProvider.notifier).addItem(
              PlanItem(
                id: 'plan-pet-adopt-${DateTime.now().microsecondsSinceEpoch}',
                title: petAdoptTitle,
                date: pet.adoptionDate,
                categoryKey: widget.category.categoryKey,
                isAllDay: true,
                displayMode: DdayDisplayMode.daysCount,
              ),
            );
      }

      if (!pet.isBirthUnknown && pet.birthDate != null) {
        final petBirthTitle = '${pet.name} 생일';
        if (!existingItems.any((i) => i.title == petBirthTitle)) {
          ref.read(planListProvider.notifier).addItem(
                PlanItem(
                  id: 'plan-pet-birth-${DateTime.now().microsecondsSinceEpoch}',
                  title: petBirthTitle,
                  date: pet.birthDate!,
                  categoryKey: widget.category.categoryKey,
                  isAllDay: true,
                  displayMode: DdayDisplayMode.dday,
                ),
              );
        }
      }
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🐾 반려동물 정보 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (int i = 0; i < _pets.length; i++) ...[
                  _buildPetCard(i),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pets.add(_PetOnboardingItem(
                        name: '새로운 친구',
                        icon: '🐾',
                        adoptionDate: DateTime.now(),
                      ));
                    });
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF007AFF)),
                  label: const Text('반려동물 추가', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF007AFF)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: const Text('설정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(int index) {
    final pet = _pets[index];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '반려동물 #${index + 1} (${pet.icon} ${pet.name})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.protoHeading),
              ),
              if (_pets.length > 1)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                  onPressed: () {
                    setState(() => _pets.removeAt(index));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 아이콘 그리드 선택기
          const Text('대표 동물 아이콘', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3C))),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final opt in kPetIconOptions)
                  GestureDetector(
                    onTap: () => setState(() => pet.icon = opt.icon),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: pet.icon == opt.icon ? const Color(0xFF007AFF) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pet.icon == opt.icon ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                        ),
                      ),
                      child: Text(
                        '${opt.icon} ${opt.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pet.icon == opt.icon ? Colors.white : AppColors.protoHeading,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 이름 입력
          const Text('이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3C))),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: pet.name,
            decoration: InputDecoration(
              hintText: '예: 뽀삐, 나비',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D1D6))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) => pet.name = val,
          ),
          const SizedBox(height: 14),

          // 데려온 날 (입양일)
          const Text('데려온 날 (처음 만난 날)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3C))),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showHaruDatePicker(
                context,
                initialDate: pet.adoptionDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => pet.adoptionDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D1D6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(pet.adoptionDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF007AFF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 생일 설정
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('생일 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3C))),
              Row(
                children: [
                  Checkbox(
                    value: pet.isBirthUnknown,
                    onChanged: (val) {
                      setState(() => pet.isBirthUnknown = val ?? false);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text('생일 모름', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (pet.isBirthUnknown)
            TextFormField(
              initialValue: pet.approxAgeText,
              decoration: InputDecoration(
                hintText: '추정 나이 입력 (예: 2살, 6개월)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D1D6))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => pet.approxAgeText = val,
            )
          else
            InkWell(
              onTap: () async {
                final picked = await showHaruDatePicker(
                  context,
                  initialDate: pet.birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => pet.birthDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D1D6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pet.birthDate != null ? _formatDate(pet.birthDate!) : '생일 선택',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                    ),
                    const Icon(Icons.cake_rounded, size: 16, color: Color(0xFF007AFF)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
