import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/colors.dart';
import '../../military/models/military_rank.dart';
import '../../military/providers/military_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../data/kpop_artist_presets.dart';
import '../logic/repeat_rule.dart';
import '../models/category.dart';
import '../models/fandom_profile.dart';
import '../models/pet_profile.dart';
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
  late int _totalVacationDays;
  late int _usedVacationDays;

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    final service = ref.read(militaryServiceProvider);

    if (meta != null && meta['enlistDate'] != null) {
      _branch = MilitaryBranch.values.firstWhere(
        (b) => b.name == meta['branch'],
        orElse: () => MilitaryBranch.army,
      );
      _enlistDate = DateTime.parse(meta['enlistDate'] as String);
      _dischargeDate = meta['dischargeDate'] != null
          ? DateTime.parse(meta['dischargeDate'] as String)
          : defaultDischargeDate(_enlistDate, _branch);
      _totalVacationDays = meta['totalVacationDays'] as int? ?? service.totalVacationDays;
      _usedVacationDays = meta['usedVacationDays'] as int? ?? service.usedVacationDays;
      if (meta['nextLeaveDate'] != null) {
        _nextLeaveDate = DateTime.parse(meta['nextLeaveDate'] as String);
      }
    } else {
      _branch = service.branch;
      _enlistDate = service.enlistDate;
      _dischargeDate = service.dischargeDate;
      _nextLeaveDate = service.nextLeaveDate;
      _totalVacationDays = service.totalVacationDays;
      _usedVacationDays = service.usedVacationDays;
    }
  }

  void _onBranchSelected(MilitaryBranch branch) {
    setState(() {
      _branch = branch;
      _dischargeDate = defaultDischargeDate(_enlistDate, branch);
    });
  }

  DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    // 1. 군대 서비스 프로바이더 갱신
    ref.read(militaryServiceProvider.notifier).setService(
          enlistDate: _enlistDate,
          dischargeDate: _dischargeDate,
          branch: _branch,
          totalVacationDays: _totalVacationDays,
          usedVacationDays: _usedVacationDays,
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
        'totalVacationDays': _totalVacationDays,
        'usedVacationDays': _usedVacationDays,
        if (_nextLeaveDate != null) 'nextLeaveDate': _nextLeaveDate!.toIso8601String(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    // 3. 플랜 아이템 자동 추가/보정
    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    // [A] 입대일 (N일째 카운트업)
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

    // [B] 진급일 자동 산정 (일병: 2개월차, 상병: 8개월차, 병장: 14개월차)
    final pfcDate = _addMonths(_enlistDate, monthsToPrivateFirstClass);
    final corpDate = _addMonths(_enlistDate, monthsToCorporal);
    final sgtDate = _addMonths(_enlistDate, monthsToSergeant);

    if (!existingItems.any((i) => i.title.contains('일병 진급'))) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-pfc-${DateTime.now().microsecondsSinceEpoch}',
              title: '일병 진급',
              date: pfcDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.dday,
            ),
          );
    }

    if (!existingItems.any((i) => i.title.contains('상병 진급'))) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-corp-${DateTime.now().microsecondsSinceEpoch}',
              title: '상병 진급',
              date: corpDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.dday,
            ),
          );
    }

    if (!existingItems.any((i) => i.title.contains('병장 진급'))) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-sgt-${DateTime.now().microsecondsSinceEpoch}',
              title: '병장 진급',
              date: sgtDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.dday,
            ),
          );
    }

    // [C] 전역일 아이템 추가
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

    // [D] 휴가 등록
    if (_nextLeaveDate != null && !existingItems.any((i) => i.title.contains('휴가') && i.date == _nextLeaveDate)) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-leave-${DateTime.now().microsecondsSinceEpoch}',
              title: '휴가 (정기/포상)',
              date: _nextLeaveDate!,
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
    final remainingVacation = (_totalVacationDays - _usedVacationDays).clamp(0, 999);

    return Container(
      height: mediaQuery.size.height * 0.90,
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
                  '🎖️ 복무 & 휴가 정보 설정',
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
                // 복무율 & 휴가 요약 미리보기 카드
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
                            daysLeft > 0 ? '전역 D-$daysLeft' : (daysLeft == 0 ? '전역 D-Day' : 'D+${-daysLeft}'),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15803D), fontSize: 15),
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '남은 휴가: $remainingVacation일 (총 $_totalVacationDays일 중)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                          ),
                          if (_nextLeaveDate != null)
                            Text(
                              '휴가 ${_formatDate(_nextLeaveDate!)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                            ),
                        ],
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
                        selectedColor: const Color(0xFF16A34A),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF16A34A)),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. 휴가 관리 시스템 (총 휴가 일수 & 사용 휴가 일수)
                const Text('휴가 관리 시스템', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('총 부여 휴가 (일)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: _totalVacationDays.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '예: 24',
                              filled: true,
                              fillColor: const Color(0xFFF2F2F7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null) {
                                setState(() => _totalVacationDays = parsed);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('사용한 휴가 (일)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: _usedVacationDays.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '예: 6',
                              filled: true,
                              fillColor: const Color(0xFFF2F2F7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null) {
                                setState(() => _usedVacationDays = parsed);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. 다음 휴가일 (선택)
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
                            color: _nextLeaveDate != null ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.beach_access_rounded, size: 18, color: Color(0xFF16A34A)),
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
                backgroundColor: const Color(0xFF16A34A),
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
  late TextEditingController _fandomNameController;
  late TextEditingController _searchController;
  late DateTime _fandomStartDate;
  DateTime? _debutDate;
  KpopArtistPreset? _selectedPreset;
  bool _isManualMode = false;
  List<KpopArtistPreset> _filteredPresets = KpopArtistDatabase.presets;

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    _starNameController = TextEditingController(text: meta?['starName'] as String? ?? '');
    _fandomNameController = TextEditingController(text: meta?['fandomName'] as String? ?? '');
    _searchController = TextEditingController();
    _fandomStartDate = meta?['fandomStartDate'] != null
        ? DateTime.parse(meta!['fandomStartDate'] as String)
        : DateTime.now().subtract(const Duration(days: 100));
    if (meta?['debutDate'] != null) {
      _debutDate = DateTime.parse(meta!['debutDate'] as String);
    }
  }

  @override
  void dispose() {
    _starNameController.dispose();
    _fandomNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _onSelectPreset(KpopArtistPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _starNameController.text = preset.groupName;
      _fandomNameController.text = preset.fandomName;
      _debutDate = preset.debutDate;
    });
  }

  void _save() {
    final starName = _starNameController.text.trim().isEmpty
        ? (_selectedPreset?.groupName ?? '최애 ⭐')
        : _starNameController.text.trim();
    final fandomName = _fandomNameController.text.trim().isEmpty
        ? (_selectedPreset?.fandomName ?? '팬덤')
        : _fandomNameController.text.trim();

    List<FandomMember> memberList = [];
    if (_selectedPreset != null) {
      memberList = _selectedPreset!.members.asMap().entries.map((e) {
        final idx = e.key;
        final m = e.value;
        return FandomMember(
          id: 'member_${presetMemberId(m.name)}_${DateTime.now().microsecondsSinceEpoch + idx}',
          name: m.name,
          birthDate: m.birthDate,
          position: m.position,
          emoji: m.emoji,
          biasRank: idx == 0 ? BiasRank.first : (idx == 1 ? BiasRank.second : (idx == 2 ? BiasRank.third : BiasRank.member)),
        );
      }).toList();
    }

    final topkku = FandomTopkkuCard(
      customOverlayText: '$starName 입덕 1일째 ✨',
      musicTrack: FandomMusicTrack(
        title: '$starName의 대표곡',
        artist: starName,
      ),
    );

    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'starName': starName,
        'fandomName': fandomName,
        'fandomStartDate': _fandomStartDate.toIso8601String(),
        if (_debutDate != null) 'debutDate': _debutDate!.toIso8601String(),
        'members': memberList.map((m) => m.toJson()).toList(),
        'topkku': topkku.toJson(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    // 1. 입덕일 (N일째 카운트업)
    final hasFandom = existingItems.any((i) => i.title.contains('입덕'));
    if (!hasFandom) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-fandom-start-${DateTime.now().microsecondsSinceEpoch}',
              title: '$starName 입덕일',
              date: _fandomStartDate,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              displayMode: DdayDisplayMode.daysCount,
            ),
          );
    }

    // 2. 데뷔일 (매년 반복 D-Day)
    if (_debutDate != null && !existingItems.any((i) => i.title.contains('데뷔'))) {
      ref.read(planListProvider.notifier).addItem(
            PlanItem(
              id: 'plan-fandom-debut-${DateTime.now().microsecondsSinceEpoch}',
              title: '$starName 데뷔 기념일',
              date: _debutDate!,
              categoryKey: widget.category.categoryKey,
              isAllDay: true,
              repeatConfig: RepeatConfig.yearlyDefault,
              displayMode: DdayDisplayMode.dday,
            ),
          );
    }

    // 3. 멤버 생일 자동 등록
    for (final member in memberList) {
      final title = '${member.name} 생일';
      if (!existingItems.any((i) => i.title == title)) {
        ref.read(planListProvider.notifier).addItem(
              PlanItem(
                id: 'plan-fandom-bday-${member.id}-${DateTime.now().microsecondsSinceEpoch}',
                title: title,
                date: member.birthDate,
                categoryKey: widget.category.categoryKey,
                isAllDay: true,
                repeatConfig: RepeatConfig.yearlyDefault,
                displayMode: DdayDisplayMode.dday,
              ),
            );
      }
    }

    Navigator.of(context).pop(true);
  }

  String presetMemberId(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(_fandomStartDate.year, _fandomStartDate.month, _fandomStartDate.day);
    final days = today.difference(start).inDays + 1;

    return Container(
      height: mediaQuery.size.height * 0.90,
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
                const Row(
                  children: [
                    Text('💜', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      '덕질 / 아티스트 온보딩',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                    ),
                  ],
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
                // 프리셋 vs 직접 입력 모드 탭
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isManualMode = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !_isManualMode ? const Color(0xFFFAF5FF) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_isManualMode ? const Color(0xFF9333EA) : const Color(0xFFE5E7EB),
                              width: !_isManualMode ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '✨ K-POP 공식 DB 프리셋',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isManualMode ? FontWeight.bold : FontWeight.normal,
                              color: !_isManualMode ? const Color(0xFF9333EA) : AppColors.protoSubtitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isManualMode = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isManualMode ? const Color(0xFFFAF5FF) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isManualMode ? const Color(0xFF9333EA) : const Color(0xFFE5E7EB),
                              width: _isManualMode ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '✏️ 직접 입력 (배우/인디/버추얼)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isManualMode ? FontWeight.bold : FontWeight.normal,
                              color: _isManualMode ? const Color(0xFF9333EA) : AppColors.protoSubtitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!_isManualMode) ...[
                  // K-POP 아티스트 검색창
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '아티스트 / 팬덤명 검색 (예: 방탄, 뉴진스, IVE)',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9333EA)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (q) {
                      setState(() {
                        _filteredPresets = KpopArtistDatabase.search(q);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // K-POP 아티스트 리스트 (가로 스크롤 칩 및 카드)
                  const Text('주요 K-POP 아티스트 원터치 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.protoSubtitle)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, idx) {
                        final p = _filteredPresets[idx];
                        final isSel = _selectedPreset?.id == p.id;
                        return InkWell(
                          onTap: () => _onSelectPreset(p),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 130,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFFAF5FF) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel ? const Color(0xFF9333EA) : const Color(0xFFF3F4F6),
                                width: isSel ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  p.groupName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                    color: isSel ? const Color(0xFF9333EA) : AppColors.protoHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.fandomName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: AppColors.protoSubtitle),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 선택/입력 요약 프리뷰 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3E8FF)),
                  ),
                  child: Row(
                    children: [
                      Text(_selectedPreset?.emoji ?? '💜', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _starNameController.text.trim().isEmpty ? '최애 아티스트' : _starNameController.text.trim(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '팬덤: ${_fandomNameController.text.trim().isEmpty ? "팬덤" : _fandomNameController.text.trim()} · 함께한 지 ${days > 0 ? days : 1}일째',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9333EA), fontWeight: FontWeight.bold),
                            ),
                            if (_selectedPreset != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '멤버 ${_selectedPreset!.members.length}명 자동 등록 예정',
                                style: const TextStyle(fontSize: 11, color: AppColors.protoSubtitle),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 최애 이름 / 그룹명
                const Text('최애 이름 / 그룹명', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 6),
                TextField(
                  controller: _starNameController,
                  decoration: InputDecoration(
                    hintText: '예: 아이유, BTS, 뉴진스',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),

                // 팬덤명
                const Text('팬덤 이름 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 6),
                TextField(
                  controller: _fandomNameController,
                  decoration: InputDecoration(
                    hintText: '예: 아미, 버니즈, 다이브',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),

                // 입덕 날짜
                const Text('입덕 날짜 (처음 반한 날)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_fandomStartDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF9333EA)),
                        ),
                        const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFF9333EA)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 데뷔일 (선택)
                const Text('데뷔일 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _debutDate ?? DateTime(2020, 1, 1),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _debutDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _debutDate != null ? _formatDate(_debutDate!) : '데뷔일 설정 안 됨 (선택)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _debutDate != null ? const Color(0xFF9333EA) : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF9333EA)),
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
                backgroundColor: const Color(0xFF9333EA),
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

/// 4.5 직접 설정하기 (Custom) 온보딩 설정 바텀시트
Future<bool?> showCustomOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CustomOnboardingSheet(category: category),
  );
}

class _CustomOnboardingSheet extends ConsumerStatefulWidget {
  const _CustomOnboardingSheet({required this.category});

  final CategoryModel category;

  @override
  ConsumerState<_CustomOnboardingSheet> createState() => _CustomOnboardingSheetState();
}

class _CustomOnboardingSheetState extends ConsumerState<_CustomOnboardingSheet> {
  late TextEditingController _nameController;
  late String _selectedEmoji;
  late bool _showVisualCard;
  late DateTime _startDate;

  static const List<String> _emojiPresets = [
    '✨', '📌', '🚀', '💼', '🏡', '🏖️', '🎨', '🍿',
    '✈️', '🎮', '🏋️', '📚', '☕', '💎', '🍀', '💡',
  ];

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    _nameController = TextEditingController(text: widget.category.name == '직접 설정하기' ? '' : widget.category.name);
    _selectedEmoji = widget.category.icon.isNotEmpty ? widget.category.icon : '✨';
    _showVisualCard = meta?['showVisualCard'] as bool? ?? true;
    _startDate = meta?['startDate'] != null
        ? DateTime.parse(meta!['startDate'] as String)
        : DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final name = _nameController.text.trim().isEmpty ? '나만의 카테고리 ✨' : _nameController.text.trim();
    final updated = widget.category.copyWith(
      name: name,
      icon: _selectedEmoji,
      metadata: {
        'isInitialized': true,
        'showVisualCard': _showVisualCard,
        'startDate': _startDate.toIso8601String(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

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
                const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      '나만의 카테고리 직접 설정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                    ),
                  ],
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
                // 이모지 선택
                const Text('대표 이모지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _emojiPresets.map((emoji) {
                    final isSel = _selectedEmoji == emoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFEFCE8) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? const Color(0xFFFACC15) : const Color(0xFFE5E7EB),
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 카테고리 이름
                const Text('카테고리 이름', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '예: 우리 가족 기념일, 유럽 여행, 취미 생활',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // 상단 비주얼 카드(꾸미기 박스) ON / OFF 토글
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _showVisualCard,
                        activeColor: const Color(0xFFD97706),
                        onChanged: (val) {
                          setState(() => _showVisualCard = val ?? true);
                        },
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '상단 꾸미기 박스 (비주얼 카드) 사용하기',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '해제 시 190px 상단 박스 없이 심플한 노션 스타일 D-Day 리스트로 바로 표시됩니다.',
                              style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 기준 시작일
                const Text('기본 시작일 / 기준일 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                const SizedBox(height: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_startDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFFD97706)),
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
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: const Color(0xFF451A03),
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


/// 5. 반려동물 (Pet) 온보딩 설정 바텀시트 (다중 등록 및 세부 프로필 지원)
Future<bool?> showPetOnboardingSheet(
  BuildContext context, {
  required CategoryModel category,
  required WidgetRef ref,
  PetProfile? editPet,
  bool isAddingNewPet = false,
  String? targetPetId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PetOnboardingSheet(
      category: category,
      editPet: editPet,
      isAddingNewPet: isAddingNewPet,
      targetPetId: targetPetId,
    ),
  );
}

class _PetOnboardingSheet extends ConsumerStatefulWidget {
  const _PetOnboardingSheet({
    required this.category,
    this.editPet,
    this.isAddingNewPet = false,
    this.targetPetId,
  });

  final CategoryModel category;
  final PetProfile? editPet;
  final bool isAddingNewPet;
  final String? targetPetId;

  @override
  ConsumerState<_PetOnboardingSheet> createState() => _PetOnboardingSheetState();
}

class _PetOnboardingSheetState extends ConsumerState<_PetOnboardingSheet> {
  final List<PetProfile> _pets = [];
  final Map<String, String> _selectedCategoryByPetId = {};

  @override
  void initState() {
    super.initState();
    final meta = widget.category.metadata;
    final petListJson = meta?['pets'] as List<dynamic>?;

    if (petListJson != null && petListJson.isNotEmpty) {
      for (final item in petListJson) {
        final m = item as Map<String, dynamic>;
        final p = PetProfile.fromJson(m);
        _pets.add(p);
        _selectedCategoryByPetId[p.id] = _findCategoryNameForPet(p);
      }
    } else {
      final initialPet = PetProfile(
        id: 'pet_${DateTime.now().microsecondsSinceEpoch}',
        name: '댕댕이',
        species: '말티즈',
        icon: '🐶',
        personality: '간식 좋아하고 호기심 많은 친구 🐾',
        adoptionDate: DateTime.now().subtract(const Duration(days: 200)),
        birthDate: DateTime.now().subtract(const Duration(days: 365)),
      );
      _pets.add(initialPet);
      _selectedCategoryByPetId[initialPet.id] = '강아지';
    }

    if (widget.isAddingNewPet) {
      final newPet = PetProfile(
        id: 'pet_${DateTime.now().microsecondsSinceEpoch}',
        name: '새로운 친구',
        species: '말티즈',
        icon: '🐶',
        personality: '',
        adoptionDate: DateTime.now(),
      );
      _pets.add(newPet);
      _selectedCategoryByPetId[newPet.id] = '강아지';
    }
  }

  String _findCategoryNameForPet(PetProfile pet) {
    for (final cat in kPetCategories) {
      if (cat.breeds.contains(pet.species) || cat.icon == pet.icon) {
        return cat.categoryName;
      }
    }
    return kPetCategories.first.categoryName;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        setState(() {
          _pets[index] = _pets[index].copyWith(photoUrl: dataUrl);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerActionSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  '반려동물 프로필 사진 설정',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFD97706), size: 20),
                ),
                title: const Text('사진 보관함에서 선택', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(index, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD97706), size: 20),
                ),
                title: const Text('카메라로 촬영하기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(index, ImageSource.camera);
                },
              ),
              if (_pets[index].photoUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  title: const Text('기본 이모티콘으로 변경 (사진 삭제)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _pets[index] = _pets[index].copyWith(photoUrl: null);
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final updated = widget.category.copyWith(
      metadata: {
        'isInitialized': true,
        'pets': _pets.map((p) => p.toJson()).toList(),
      },
    );
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final existingItems = ref.read(planItemsByCategoryProvider(widget.category.categoryKey));

    for (final pet in _pets) {
      // 1. N일째 리스트 자동 등록 (데려온 날)
      final petAdoptTitle = '${pet.name} 만난 날';
      if (!existingItems.any((i) => i.title == petAdoptTitle || i.categoryInstanceId == pet.id && i.title.contains('만난 날'))) {
        ref.read(planListProvider.notifier).addItem(
              PlanItem(
                id: 'plan-pet-adopt-${pet.id}-${DateTime.now().microsecondsSinceEpoch}',
                title: petAdoptTitle,
                date: pet.adoptionDate,
                categoryKey: widget.category.categoryKey,
                categoryInstanceId: pet.id,
                photoUrl: pet.photoUrl ?? 'emoji:${pet.icon}',
                isAllDay: true,
                displayMode: DdayDisplayMode.daysCount,
              ),
            );
      }

      // 생일이 있는 경우: N일째 카운트업 & 매년 반복 롤링 D-Day 듀얼 등록
      if (!pet.isBirthUnknown && pet.birthDate != null) {
        // [A] N일째 리스트: '태어난 지 N일째' (출생일부터 누적 카운트업)
        final petBornTitle = '${pet.name} 태어난 날';
        if (!existingItems.any((i) => i.title == petBornTitle || i.categoryInstanceId == pet.id && i.title.contains('태어난 날'))) {
          ref.read(planListProvider.notifier).addItem(
                PlanItem(
                  id: 'plan-pet-born-${pet.id}-${DateTime.now().microsecondsSinceEpoch}',
                  title: petBornTitle,
                  date: pet.birthDate!,
                  categoryKey: widget.category.categoryKey,
                  categoryInstanceId: pet.id,
                  photoUrl: pet.photoUrl ?? 'emoji:${pet.icon}',
                  isAllDay: true,
                  displayMode: DdayDisplayMode.daysCount,
                ),
              );
        }

        // [B] 세부 D-Day 리스트: 생일 매년 반복 롤링 D-Day 등록
        final petBirthDDayTitle = '${pet.name} 생일';
        if (!existingItems.any((i) => i.title == petBirthDDayTitle || i.categoryInstanceId == pet.id && i.title.contains('생일'))) {
          ref.read(planListProvider.notifier).addItem(
                PlanItem(
                  id: 'plan-pet-birth-${pet.id}-${DateTime.now().microsecondsSinceEpoch}',
                  title: petBirthDDayTitle,
                  date: pet.birthDate!,
                  categoryKey: widget.category.categoryKey,
                  categoryInstanceId: pet.id,
                  photoUrl: pet.photoUrl ?? 'emoji:${pet.icon}',
                  isAllDay: true,
                  repeatConfig: RepeatConfig.yearlyDefault,
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
      height: mediaQuery.size.height * 0.90,
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
                const Row(
                  children: [
                    Text('🐾', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      '반려동물 패밀리 프로필 설정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                    ),
                  ],
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
                      final newP = PetProfile(
                        id: 'pet_${DateTime.now().microsecondsSinceEpoch}',
                        name: '새로운 친구',
                        species: '말티즈',
                        icon: '🐶',
                        personality: '',
                        adoptionDate: DateTime.now(),
                      );
                      _pets.add(newP);
                      _selectedCategoryByPetId[newP.id] = '강아지';
                    });
                  },
                  icon: const Icon(Icons.add, color: Color(0xFFD97706)),
                  label: const Text('+ 반려동물 추가 등록', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
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
    final selectedCatName = _selectedCategoryByPetId[pet.id] ?? _findCategoryNameForPet(pet);
    final currentCatOption = kPetCategories.firstWhere(
      (c) => c.categoryName == selectedCatName,
      orElse: () => kPetCategories.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E8D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Text(pet.icon, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${index + 1} ${pet.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.protoHeading),
                  ),
                ],
              ),
              if (_pets.length > 1)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  onPressed: () {
                    setState(() {
                      _selectedCategoryByPetId.remove(pet.id);
                      _pets.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. 프로필 아바타 (사진 보관함 / 카메라 촬영 / 이모티콘)
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _showImagePickerActionSheet(index),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                          ? Image(
                              image: getPetAvatarImageProvider(pet.photoUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(pet.icon, style: const TextStyle(fontSize: 40)),
                              ),
                            )
                          : Center(
                              child: Text(pet.icon, style: const TextStyle(fontSize: 42)),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _showImagePickerActionSheet(index),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '프로필 사진 터치 시 변경',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),

          // 2. 이름 입력
          const Text('이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('pet_name_${pet.id}'),
            initialValue: pet.name,
            decoration: InputDecoration(
              hintText: '예: 뽀삐, 나비, 토리',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              _pets[index] = pet.copyWith(name: val.trim());
            },
          ),
          const SizedBox(height: 16),

          // 3. 1단계: 동물 대분류 탭
          const Text('동물 종류 (대분류)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final cat in kPetCategories) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryByPetId[pet.id] = cat.categoryName;
                        _pets[index] = pet.copyWith(
                          icon: cat.icon,
                          species: cat.breeds.contains(pet.species) ? pet.species : cat.breeds.first,
                        );
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedCatName == cat.categoryName ? const Color(0xFFD97706) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedCatName == cat.categoryName ? const Color(0xFFD97706) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: selectedCatName == cat.categoryName
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 5),
                          Text(
                            cat.categoryName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: selectedCatName == cat.categoryName ? Colors.white : AppColors.protoHeading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. 2단계: 세부 품종 선택 칩 & 직접 입력
          Text(
            '$selectedCatName 세부 품종 / 종류',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final breed in currentCatOption.breeds) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _pets[index] = pet.copyWith(species: breed);
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: pet.species == breed ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: pet.species == breed ? const Color(0xFFD97706) : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          breed,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: pet.species == breed ? FontWeight.bold : FontWeight.normal,
                            color: pet.species == breed ? const Color(0xFFB45309) : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('pet_species_${pet.id}_$selectedCatName'),
            initialValue: pet.species,
            decoration: InputDecoration(
              hintText: '품종 직접 입력 또는 수정 (선택)',
              prefixIcon: const Icon(Icons.pets_rounded, size: 18, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              _pets[index] = pet.copyWith(species: val.trim());
            },
          ),
          const SizedBox(height: 16),

          // 5. 데려온 날 (처음 만난 날)
          const Text('데려온 날 (처음 만난 날)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
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
                setState(() {
                  _pets[index] = pet.copyWith(adoptionDate: picked);
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(pet.adoptionDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD97706)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. 생일 설정
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('생일 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
              Row(
                children: [
                  Checkbox(
                    value: pet.isBirthUnknown,
                    activeColor: const Color(0xFFD97706),
                    onChanged: (val) {
                      setState(() {
                        _pets[index] = pet.copyWith(isBirthUnknown: val ?? false);
                      });
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
              key: ValueKey('pet_approx_age_${pet.id}'),
              initialValue: pet.approxAgeText,
              decoration: InputDecoration(
                hintText: '추정 나이 입력 (예: 2살, 6개월)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) {
                _pets[index] = pet.copyWith(approxAgeText: val.trim());
              },
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
                  setState(() {
                    _pets[index] = pet.copyWith(birthDate: picked);
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pet.birthDate != null ? _formatDate(pet.birthDate!) : '생일 날짜 선택',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                    const Icon(Icons.cake_rounded, size: 16, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 7. 성격 및 특징 (메모/한줄소개)
          const Text('성격 및 특징 (한 줄 소개)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('pet_personality_${pet.id}'),
            initialValue: pet.personality,
            decoration: InputDecoration(
              hintText: '예: 간식 좋아하고 호기심 많은 개구쟁이 🐾',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              _pets[index] = pet.copyWith(personality: val.trim());
            },
          ),
        ],
      ),
    );
  }
}
