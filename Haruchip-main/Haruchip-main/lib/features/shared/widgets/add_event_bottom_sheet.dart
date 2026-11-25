import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_picker.dart';
import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../calendar/models/calendar_event.dart';
import '../../calendar/providers/schedule_room_provider.dart';
import '../../calendar/widgets/themed_color_palette_sheet.dart';
import '../../categories/logic/repeat_rule.dart';
import '../../categories/models/category.dart';
import '../../categories/models/pet_profile.dart';
import '../../categories/providers/category_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../../services/calendar/external_calendar_push_service.dart';
import '../../../services/notification/local_push_notification_service.dart';
import 'common_date_time_picker.dart';

// iOS Style Color Tokens
const Color _kSheetBg = Color(0xFFF2F2F7);
const Color _kGroupBg = Colors.white;
const Color _kDivider = Color(0xFFE5E5EA);
const Color _kLabel = Color(0xFF1C1C1E);
const Color _kSubLabel = Color(0xFF8E8E93);
const Color _kBlue = Color(0xFF007AFF);
const Color _kChipBg = Color(0xFFE5E5EA);
const Color _kChipSelected = Color(0xFF007AFF);

const List<({RepeatType type, String label})> _kRepeatOptions = [
  (type: RepeatType.none, label: '반복 안 함'),
  (type: RepeatType.daily, label: '매일'),
  (type: RepeatType.weekly, label: '매주'),
  (type: RepeatType.monthly, label: '매월'),
  (type: RepeatType.yearly, label: '매년'),
];

/// 이벤트/일정 추가 폼에서 사용하는 등록 카테고리 레코드 타입 (null safe 통일)
typedef EventCategoryOption = ({
  String key,
  String name,
  String emoji,
  Color color,
  String id,
});

const List<String> _kWeekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

List<DateTime> _generateRecurringDates({
  required DateTime startDate,
  required RepeatConfig repeatConfig,
  DateTime? repeatEndDate,
}) {
  if (repeatConfig.type == RepeatType.none) return [startDate];

  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = repeatEndDate != null
      ? DateTime(repeatEndDate.year, repeatEndDate.month, repeatEndDate.day)
      : (repeatConfig.type == RepeatType.yearly
          ? DateTime(start.year + 5, start.month, start.day)
          : (repeatConfig.type == RepeatType.monthly
              ? DateTime(start.year + 2, start.month, start.day)
              : (repeatConfig.type == RepeatType.daily
                  ? DateTime(start.year, start.month + 3, start.day)
                  : DateTime(start.year + 1, start.month, start.day))));

  final results = <DateTime>[];

  switch (repeatConfig.type) {
    case RepeatType.none:
      results.add(start);
      break;

    case RepeatType.daily:
      var cur = start;
      while (!cur.isAfter(end)) {
        results.add(cur);
        cur = cur.add(const Duration(days: 1));
      }
      break;

    case RepeatType.weekly:
      final days = repeatConfig.weekdays.isEmpty ? [start.weekday] : repeatConfig.weekdays;
      var cur = start;
      while (!cur.isAfter(end)) {
        if (days.contains(cur.weekday)) {
          results.add(cur);
        }
        cur = cur.add(const Duration(days: 1));
      }
      break;

    case RepeatType.monthly:
      final targetDays = repeatConfig.daysOfMonth.isEmpty ? [start.day] : repeatConfig.daysOfMonth;
      var y = start.year;
      var m = start.month;
      while (true) {
        final lastDayOfMonth = DateTime(y, m + 1, 0).day;
        for (final d in targetDays) {
          if (d <= lastDayOfMonth) {
            final date = DateTime(y, m, d);
            if (!date.isBefore(start) && !date.isAfter(end)) {
              results.add(date);
            }
          }
        }
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
        if (DateTime(y, m, 1).isAfter(end)) break;
      }
      break;

    case RepeatType.yearly:
      if (repeatConfig.daysOfYear.isEmpty) {
        var cur = start;
        while (!cur.isAfter(end)) {
          results.add(cur);
          cur = DateTime(cur.year + 1, cur.month, cur.day);
        }
      } else {
        for (var y = start.year; y <= end.year; y++) {
          for (final doy in repeatConfig.daysOfYear) {
            final parts = doy.split('-');
            if (parts.length == 2) {
              final m = int.tryParse(parts[0]) ?? 1;
              final d = int.tryParse(parts[1]) ?? 1;
              final date = DateTime(y, m, d);
              if (!date.isBefore(start) && !date.isAfter(end)) {
                results.add(date);
              }
            }
          }
        }
      }
      break;
  }

  results.sort((a, b) => a.compareTo(b));
  return results.isNotEmpty ? results : [start];
}

Future<void> showAddEventBottomSheet(
  BuildContext context, {
  required String categoryKey,
  String? categoryInstanceId,
  String? initialRoomId,
  DateTime? initialDate,
  String? initialTitle,
  PlanItem? existingItem,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddEventBottomSheet(
      categoryKey: categoryKey,
      categoryInstanceId: categoryInstanceId,
      initialRoomId: initialRoomId,
      initialDate: initialDate,
      initialTitle: initialTitle,
      existingItem: existingItem,
    ),
  );
}

class AddEventBottomSheet extends ConsumerStatefulWidget {
  const AddEventBottomSheet({
    super.key,
    required this.categoryKey,
    this.categoryInstanceId,
    this.initialRoomId,
    this.initialDate,
    this.initialTitle,
    this.existingItem,
  });

  final String categoryKey;
  final String? categoryInstanceId;
  final String? initialRoomId;
  final DateTime? initialDate;
  final String? initialTitle;
  final PlanItem? existingItem;

  @override
  ConsumerState<AddEventBottomSheet> createState() => _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends ConsumerState<AddEventBottomSheet> {
  late String _selectedCategoryKey;
  final _titleCtrl = TextEditingController();
  bool _titleError = false;

  // Pet Target Selection
  String? _selectedPetId;
  String? _selectedPetIcon;
  String? _selectedPetPhotoUrl;

  // Display Mode
  DdayDisplayMode _displayMode = DdayDisplayMode.dday;

  // Date & Time
  bool _isAllDay = false;
  late DateTime _startDate;
  TimeOfDay? _startTime;
  bool _hasEndDate = true;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _selectedTimeZone = '서울';

  // Repeat
  RepeatType _repeatType = RepeatType.none;
  final List<int> _selectedWeekdays = [];
  final List<int> _selectedDaysOfMonth = [];
  final List<String> _selectedDaysOfYear = [];
  DateTime? _repeatEndDate;

  // Pre-event Reminder
  EventReminder _reminder = EventReminder.none;

  // Calendar Sync
  bool _syncGoogle = false;
  bool _syncNaver = false;
  String _selectedGoogleCalendarId = 'primary';
  String _selectedNaverCalendarId = 'default';

  // Room Links
  final List<String> _selectedRoomIds = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryKey = widget.categoryKey.isEmpty ? 'plan' : widget.categoryKey;
    final now = DateTime.now();
    _startDate = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _endDate = _startDate;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
    _hasEndDate = true;

    if (widget.initialTitle != null) {
      _titleCtrl.text = widget.initialTitle!;
    }
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _selectedCategoryKey = item.categoryKey;
      _selectedPetId = item.categoryInstanceId;
      _selectedPetPhotoUrl = item.photoUrl;
      _titleCtrl.text = item.title;
      _startDate = item.date;
      _displayMode = item.displayMode;
      _isAllDay = item.isAllDay;
      _startTime = item.deadlineTime ?? const TimeOfDay(hour: 9, minute: 0);
      _hasEndDate = true;
      _endDate = item.endDate ?? item.date;
      _endTime = item.endDeadlineTime ??
          (_startTime != null
              ? TimeOfDay(hour: (_startTime!.hour + 1) % 24, minute: _startTime!.minute)
              : const TimeOfDay(hour: 10, minute: 0));
      _repeatType = item.repeatConfig.type;
      _reminder = item.reminder;
      _selectedWeekdays.addAll(item.repeatConfig.weekdays);
      _selectedDaysOfMonth.addAll(item.repeatConfig.daysOfMonth);
      _selectedDaysOfYear.addAll(item.repeatConfig.daysOfYear);
      _syncGoogle = item.calendarSync.google;
      _syncNaver = item.calendarSync.naver;
      _selectedRoomIds.addAll(item.roomLinks);
    } else {
      if (widget.initialRoomId != null) {
        _selectedRoomIds.add(widget.initialRoomId!);
      }
      if (widget.categoryInstanceId != null) {
        _selectedPetId = widget.categoryInstanceId;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    final config = RepeatConfig(
      type: _repeatType,
      weekdays: _repeatType == RepeatType.weekly ? _selectedWeekdays : [],
      daysOfMonth: _repeatType == RepeatType.monthly ? _selectedDaysOfMonth : [],
      daysOfYear: _repeatType == RepeatType.yearly ? _selectedDaysOfYear : [],
    );

    final effectiveInstanceId = _selectedCategoryKey == 'pet'
        ? (_selectedPetId ?? widget.categoryInstanceId)
        : widget.categoryInstanceId;

    final effectivePhotoUrl = _selectedCategoryKey == 'pet'
        ? (_selectedPetPhotoUrl ?? (_selectedPetIcon != null ? 'emoji:$_selectedPetIcon' : null))
        : widget.existingItem?.photoUrl;

    final categories = ref.read(categoryListProvider);
    final catMatch = categories.where((c) => c.categoryKey == _selectedCategoryKey || c.id == _selectedCategoryKey);
    final selectedCatColorHex = catMatch.isNotEmpty ? catMatch.first.colorHex : null;

    if (widget.existingItem != null) {
      // Edit mode: update single or base item
      final item = widget.existingItem!.copyWith(
        title: title,
        date: _startDate,
        categoryKey: _selectedCategoryKey,
        categoryInstanceId: effectiveInstanceId,
        photoUrl: effectivePhotoUrl,
        displayMode: _displayMode,
        repeatConfig: config,
        reminder: _reminder,
        calendarSync: CalendarSyncFlags(google: _syncGoogle, naver: _syncNaver, haruchip: true),
        deadlineTime: _startTime,
        endDate: _hasEndDate ? _endDate : null,
        endDeadlineTime: _hasEndDate ? _endTime : null,
        isAllDay: _isAllDay,
        roomLinks: _selectedRoomIds,
      );
      ref.read(planListProvider.notifier).updateItem(item);
      LocalPushNotificationService.instance.schedulePlanReminder(item);

      // External calendar push
      ExternalCalendarPushService.instance.pushPlanItem(
        item: item,
        googleCalendarId: _selectedGoogleCalendarId,
        naverCalendarId: _selectedNaverCalendarId,
        categoryColorHex: selectedCatColorHex,
      );
    } else {
      // Add mode: if repeat is configured, generate all recurring instances up to repeatEndDate!
      if (_repeatType != RepeatType.none) {
        final dates = _generateRecurringDates(
          startDate: _startDate,
          repeatConfig: config,
          repeatEndDate: _repeatEndDate,
        );

        final items = <PlanItem>[];
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < dates.length; i++) {
          final it = PlanItem(
            id: '${nowMs}_$i',
            categoryKey: _selectedCategoryKey,
            categoryInstanceId: effectiveInstanceId,
            photoUrl: effectivePhotoUrl,
            title: title,
            date: dates[i],
            displayMode: _displayMode,
            repeatConfig: config,
            reminder: _reminder,
            calendarSync: CalendarSyncFlags(google: _syncGoogle, naver: _syncNaver, haruchip: true),
            deadlineTime: _startTime,
            endDate: _hasEndDate ? _endDate : null,
            endDeadlineTime: _hasEndDate ? _endTime : null,
            isAllDay: _isAllDay,
            roomLinks: _selectedRoomIds,
          );
          items.add(it);
        }
        ref.read(planListProvider.notifier).addItems(items);
        for (final it in items) {
          LocalPushNotificationService.instance.schedulePlanReminder(it);
        }

        if (items.isNotEmpty) {
          ExternalCalendarPushService.instance.pushPlanItem(
            item: items.first,
            googleCalendarId: _selectedGoogleCalendarId,
            naverCalendarId: _selectedNaverCalendarId,
            categoryColorHex: selectedCatColorHex,
          );
        }
      } else {
        final item = PlanItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          categoryKey: _selectedCategoryKey,
          categoryInstanceId: effectiveInstanceId,
          photoUrl: effectivePhotoUrl,
          title: title,
          date: _startDate,
          displayMode: _displayMode,
          repeatConfig: config,
          reminder: _reminder,
          calendarSync: CalendarSyncFlags(google: _syncGoogle, naver: _syncNaver, haruchip: true),
          deadlineTime: _startTime,
          endDate: _hasEndDate ? _endDate : null,
          endDeadlineTime: _hasEndDate ? _endTime : null,
          isAllDay: _isAllDay,
          roomLinks: _selectedRoomIds,
        );
        ref.read(planListProvider.notifier).addItem(item);
        LocalPushNotificationService.instance.schedulePlanReminder(item);

        ExternalCalendarPushService.instance.pushPlanItem(
          item: item,
          googleCalendarId: _selectedGoogleCalendarId,
          naverCalendarId: _selectedNaverCalendarId,
          categoryColorHex: selectedCatColorHex,
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final categoriesState = ref
        .watch(categoryListProvider)
        .where((c) => !kRemovedDdayCategoryKeys.contains(c.categoryKey))
        .toList();
    final List<EventCategoryOption> categories = categoriesState.isNotEmpty
        ? categoriesState
            .map((c) => (
                  key: c.categoryKey,
                  name: c.name,
                  emoji: c.emoji,
                  color: colorFromHex(c.colorHex),
                  id: c.id.isNotEmpty ? c.id : c.categoryKey,
                ))
            .toList()
        : const [
            (key: 'plan', name: '내 일정', emoji: '📝', color: Color(0xFF60A5FA), id: 'plan'),
            (key: 'couple', name: '커플', emoji: '❤️', color: Color(0xFFFF8DA1), id: 'couple'),
            (key: 'fandom', name: '덕질', emoji: '⭐', color: Color(0xFFFBBF24), id: 'fandom'),
            (key: 'exam', name: '시험', emoji: '📚', color: Color(0xFF818CF8), id: 'exam'),
            (key: 'birthday', name: '생일', emoji: '🎂', color: Color(0xFFF472B6), id: 'birthday'),
            (key: 'baby', name: '아기', emoji: '👶', color: Color(0xFFFDE047), id: 'baby'),
            (key: 'pet', name: '반려동물', emoji: '🐾', color: Color(0xFFFB923C), id: 'pet'),
            (key: 'military', name: '군대', emoji: '🎖️', color: Color(0xFFA3E635), id: 'military'),
            (key: 'wedding', name: '결혼', emoji: '💍', color: Color(0xFFFDA4AF), id: 'wedding'),
            (key: 'travel', name: '여행', emoji: '✈️', color: Color(0xFF38BDF8), id: 'travel'),
            (key: 'hobby', name: '취미', emoji: '🎨', color: Color(0xFF6EE7B7), id: 'hobby'),
          ];

    final currentCategory = categories.firstWhere(
      (c) => c.key == _selectedCategoryKey,
      orElse: () => categories.first,
    );

    final isEdit = widget.existingItem != null;
    final headerTitle = isEdit ? '${currentCategory.name} 일정 수정' : '${currentCategory.name} 일정 추가';

    return Container(
      height: mediaQuery.size.height * 0.92,
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: _kLabel, fontSize: 16)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      headerTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _handleSave,
                  child: Text(
                    widget.existingItem != null ? '완료' : '추가',
                    style: const TextStyle(color: _kBlue, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Form Scroll View
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, mediaQuery.viewInsets.bottom + 32),
              children: [
                // 0-1. Pet Target Selector (반려동물 카테고리 선택 시 노출)
                _buildPetTargetSection(),

                // 1. Title Input (단일 깔끔한 텍스트 필드)
                _buildTitleSection(),
                const SizedBox(height: 14),

                // 2. Display Mode Segment (D-Day | N일째 | 개월수)
                _buildDisplayModeSection(),
                const SizedBox(height: 14),

                // 3. Date & Time Section (All Day, Start Date/Time, End Date/Time)
                _buildDateTimeSection(),
                const SizedBox(height: 14),

                // 4. White Cards: 반복 & 카테고리
                _buildRepeatAndCalendarCards(currentCategory, categories),
                const SizedBox(height: 14),

                // 5. Pre-event Reminder
                _buildReminderSection(),
                const SizedBox(height: 14),

                // 6. Calendar Sync (Google / Naver One-way Outbound Push)
                _buildCalendarSyncSection(),
                const SizedBox(height: 14),

                // 7. Room Links
                _buildRoomSection(),

                // 8. Edit Mode: 일정 삭제 버튼
                if (isEdit) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: const Text(
                              '일정 삭제',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: _kLabel,
                              ),
                            ),
                            content: Text(
                              '\'${widget.existingItem!.title}\' 일정을 삭제할까요?',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(color: _kSubLabel),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: const Text(
                                  '삭제',
                                  style: TextStyle(
                                    color: Color(0xFFE11D48),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          ref
                              .read(planListProvider.notifier)
                              .removeItem(widget.existingItem!.id);
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFE11D48),
                      ),
                      label: const Text(
                        '이 일정 삭제',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetTargetSection() {
    if (_selectedCategoryKey != 'pet') return const SizedBox.shrink();

    final categories = ref.watch(categoryListProvider);
    final petCategories = categories.where((c) => c.categoryKey == 'pet').toList();
    List<PetProfile> pets = [];
    if (petCategories.isNotEmpty) {
      final petListJson = petCategories.first.metadata?['pets'] as List<dynamic>?;
      if (petListJson != null) {
        pets = petListJson.map((e) => PetProfile.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    if (pets.isEmpty) return const SizedBox.shrink();

    if (_selectedPetId == null && pets.isNotEmpty) {
      _selectedPetId = pets.first.id;
      _selectedPetIcon = pets.first.icon;
      _selectedPetPhotoUrl = pets.first.photoUrl;
    }

    return Column(
      children: [
        _buildGroupCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pets_rounded, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text(
                      '대상 반려동물 선택',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final pet in pets)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPetId = pet.id;
                                _selectedPetIcon = pet.icon;
                                _selectedPetPhotoUrl = pet.photoUrl;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedPetId == pet.id
                                    ? const Color(0xFFFEF3C7)
                                    : _kChipBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedPetId == pet.id
                                      ? const Color(0xFFD97706)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (pet.photoUrl != null && pet.photoUrl!.isNotEmpty)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image(
                                          image: getPetAvatarImageProvider(pet.photoUrl)!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(pet.icon, style: const TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Text(pet.icon, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    pet.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedPetId == pet.id ? FontWeight.bold : FontWeight.w600,
                                      color: _selectedPetId == pet.id ? const Color(0xFFB45309) : _kLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildTitleSection() {
    return _buildGroupCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontSize: 16, color: _kLabel, fontWeight: FontWeight.w500),
          onChanged: (v) => setState(() {
            if (v.trim().isNotEmpty) _titleError = false;
          }),
          decoration: InputDecoration(
            hintText: '일정 제목을 입력하세요',
            hintStyle: const TextStyle(color: _kSubLabel, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            errorText: _titleError ? '내용을 입력해주세요' : null,
            errorStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFF04452)),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayModeSection() {
    return _buildGroupCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '표시 방식',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kLabel),
            ),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 8,
              children: [
                for (final opt in [
                  (DdayDisplayMode.dday, 'D-Day'),
                  (DdayDisplayMode.daysCount, 'N일째'),
                  (DdayDisplayMode.monthsCount, '개월수'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _displayMode = opt.$1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _displayMode == opt.$1 ? _kChipSelected : _kChipBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _displayMode == opt.$1 ? Colors.white : _kLabel,
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime?.hour ?? 9,
      _startTime?.minute ?? 0,
    );
    final effectiveEndDate = _endDate ?? _startDate;
    final endDateTime = DateTime(
      effectiveEndDate.year,
      effectiveEndDate.month,
      effectiveEndDate.day,
      _endTime?.hour ?? 10,
      _endTime?.minute ?? 0,
    );

    return CommonDateTimePicker(
      initialStartDate: startDateTime,
      initialEndDate: endDateTime,
      isAllDay: _isAllDay,
      showAllDayToggle: true,
      hasEndDate: true,
      timeZone: _selectedTimeZone,
      onTimeZoneChanged: (tz) {
        setState(() => _selectedTimeZone = tz);
      },
      onDateTimeChanged: (start, end, isAllDay) {
        setState(() {
          _startDate = DateTime(start.year, start.month, start.day);
          _startTime = isAllDay ? null : TimeOfDay(hour: start.hour, minute: start.minute);
          _isAllDay = isAllDay;
          _hasEndDate = true;
          if (end != null) {
            _endDate = DateTime(end.year, end.month, end.day);
            _endTime = isAllDay ? null : TimeOfDay(hour: end.hour, minute: end.minute);
          } else {
            _endDate = _isAllDay ? _startDate : _startDate.add(const Duration(hours: 1));
            _endTime = _isAllDay ? null : TimeOfDay(hour: (_startTime?.hour ?? 9) + 1, minute: _startTime?.minute ?? 0);
          }
        });
      },
    );
  }

  Widget _buildRepeatAndCalendarCards(
    EventCategoryOption currentCategory,
    List<EventCategoryOption> categories,
  ) {
    final repeatLabel = _kRepeatOptions.firstWhere((o) => o.type == _repeatType).label;

    return Column(
      children: [
        // Card 1: 반복
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              InkWell(
                onTap: _showRepeatPickerModal,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      const Text(
                        '반복',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kLabel,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _repeatType == RepeatType.none ? '안 함' : repeatLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _repeatType == RepeatType.none
                              ? const Color(0xFF6B7280)
                              : _kBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),

              // Weekly multi-day selector
              if (_repeatType == RepeatType.weekly) ...[
                const Divider(height: 1, color: _kDivider),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('반복 요일 선택', style: TextStyle(fontSize: 13, color: _kSubLabel, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final weekdayNum = i == 0 ? 7 : i;
                          final isSelected = _selectedWeekdays.contains(weekdayNum);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedWeekdays.remove(weekdayNum);
                                } else {
                                  _selectedWeekdays.add(weekdayNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? _kBlue : _kChipBg,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _kWeekdayLabels[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : _kLabel,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              // Monthly day of month selector
              if (_repeatType == RepeatType.monthly) ...[
                const Divider(height: 1, color: _kDivider),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('반복 날짜 선택 (매월)', style: TextStyle(fontSize: 13, color: _kSubLabel, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(31, (index) {
                          final day = index + 1;
                          final isSelected = _selectedDaysOfMonth.contains(day);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDaysOfMonth.remove(day);
                                } else {
                                  _selectedDaysOfMonth.add(day);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 38,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? _kBlue : _kChipBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$day일',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : _kLabel,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              // Repeat End Date
              if (_repeatType != RepeatType.none) ...[
                const Divider(height: 1, color: _kDivider),
                ListTile(
                  title: const Text('반복 종료일', style: TextStyle(fontSize: 15, color: _kLabel)),
                  trailing: Text(
                    _repeatEndDate != null
                        ? '${_repeatEndDate!.year}.${_repeatEndDate!.month.toString().padLeft(2, '0')}.${_repeatEndDate!.day.toString().padLeft(2, '0')}'
                        : '계속 반복 (없음)',
                    style: const TextStyle(fontSize: 15, color: _kBlue, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final picked = await showCommonDatePickerModal(
                      context,
                      initialDate: _repeatEndDate ?? _startDate.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _repeatEndDate = picked);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Card 2: 카테고리
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showCategoryPickerModal(categories),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  const Text(
                    '카테고리',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kLabel,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentCategory.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentCategory.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kLabel,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRepeatPickerModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    '반복',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kLabel),
                  ),
                ),
                const Divider(height: 1, color: _kDivider),
                for (final opt in _kRepeatOptions)
                  ListTile(
                    leading: opt.type == _repeatType
                        ? const Icon(Icons.check, size: 20, color: _kBlue)
                        : const SizedBox(width: 20),
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: opt.type == _repeatType ? FontWeight.bold : FontWeight.normal,
                        color: opt.type == _repeatType ? _kBlue : _kLabel,
                      ),
                    ),
                    onTap: () {
                      setState(() => _repeatType = opt.type);
                      Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPickerModal(
    List<EventCategoryOption> initialCategories,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, modalRef, _) {
            final liveCats = modalRef.watch(categoryListProvider);
            final categories = initialCategories.map((opt) {
              final match = liveCats.where(
                (c) => c.id == opt.id || c.categoryKey == opt.key,
              );
              if (match.isNotEmpty) {
                return (
                  key: opt.key,
                  name: match.first.name,
                  emoji: match.first.emoji,
                  color: colorFromHex(match.first.colorHex),
                  id: match.first.id,
                );
              }
              return opt;
            }).toList();

            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.68,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D1D6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '카테고리 선택',
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: _kLabel),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            '카테고리명 탭: 선택  •  우측 컬러 도트 탭: 색상 변경',
                            style: TextStyle(fontSize: 11, color: _kSubLabel),
                          ),
                        ),
                        const Divider(height: 1, color: _kDivider),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                            itemBuilder: (context, index) {
                              final item = categories[index];
                              final isSelected = item.key == _selectedCategoryKey;
                              final r = (item.color.r * 255).round().toRadixString(16).padLeft(2, '0');
                              final g = (item.color.g * 255).round().toRadixString(16).padLeft(2, '0');
                              final b = (item.color.b * 255).round().toRadixString(16).padLeft(2, '0');
                              final itemHex = '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';

                              return Row(
                                children: [
                                  // [좌측 영역]: 아이콘 + 카테고리명 -> 터치 시 즉시 선택 후 바텀시트 닫기
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryKey = item.key;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 22,
                                              child: isSelected
                                                  ? const Icon(Icons.check, size: 19, color: _kBlue)
                                                  : null,
                                            ),
                                            const SizedBox(width: 6),
                                            HaruChipIconViewer(
                                              iconKey: item.emoji,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: _kLabel,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // [우측 영역]: 컬러 도트 -> 터치 시 테마별 팔레트 색상 변경 모달 호출
                                  InkWell(
                                    key: Key('category_color_dot_${item.key}'),
                                    onTap: () async {
                                      final matchedCat = liveCats.where(
                                        (c) =>
                                            (item.id.isNotEmpty && c.id == item.id) ||
                                            c.categoryKey == item.key,
                                      );
                                      bool currentFillBg = matchedCat.isNotEmpty
                                          ? matchedCat.first.fillCalendarLabelBg
                                          : false;
                                      final pickedHex = await showThemedColorPickerSheet(
                                        context,
                                        title: '${item.name} 색상 변경',
                                        iconKey: item.emoji,
                                        currentHex: itemHex,
                                        initialFillLabelBg: currentFillBg,
                                        onFillLabelBgChanged: (v) {
                                          currentFillBg = v;
                                          modalRef
                                              .read(categoryListProvider.notifier)
                                              .updateCategoryColor(
                                                categoryKey: item.key,
                                                id: item.id,
                                                name: item.name,
                                                emoji: item.emoji,
                                                colorHex: itemHex,
                                                fillCalendarLabelBg: v,
                                              );
                                        },
                                      );
                                      if (pickedHex != null) {
                                        modalRef
                                            .read(categoryListProvider.notifier)
                                            .updateCategoryColor(
                                              categoryKey: item.key,
                                              id: item.id,
                                              name: item.name,
                                              emoji: item.emoji,
                                              colorHex: pickedHex,
                                              fillCalendarLabelBg: currentFillBg,
                                            );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: item.color.withValues(alpha: 0.45),
                                            width: 1.4,
                                          ),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: item.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1, color: _kDivider),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 19, color: _kBlue),
                              label: const Text(
                                '+ 새 카테고리 추가',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: _kBlue),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _kBlue, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showAddNewCategoryDialog();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNewCategoryDialog() {
    final nameCtrl = TextEditingController();
    String selectedHex = kThemedColorPaletteGroups.first.hexColors.first;
    String selectedIcon = 'simple_star';
    bool fillCalendarLabelBg = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentColor = colorFromHex(selectedHex);
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.86,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 드래그 핸들
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D1D6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // 헤더
                        Row(
                          children: [
                            const Text(
                              '새 카테고리 추가',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _kLabel,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 22,
                                color: _kSubLabel,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => Navigator.pop(sheetCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 좌측 아이콘 버튼(HaruChipIconPicker 연동) + 카테고리명 입력
                        Row(
                          children: [
                            InkWell(
                              onTap: () async {
                                final picked = await showHaruChipIconPicker(
                                  context,
                                  initialIconKey: selectedIcon,
                                  title: '카테고리 아이콘 선택',
                                );
                                if (picked != null) {
                                  setSheetState(() => selectedIcon = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: HaruChipIconViewer(
                                  iconKey: selectedIcon,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: nameCtrl,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: '카테고리 이름 입력',
                                  hintStyle: const TextStyle(
                                    color: _kSubLabel,
                                    fontSize: 14,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _kBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 캘린더 라벨 배경 채우기 토글
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '캘린더 라벨 배경 채우기',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _kLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: fillCalendarLabelBg
                                            ? resolveCalendarLabelPastelBg(
                                                currentColor)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 2.5,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: currentColor,
                                              borderRadius:
                                                  BorderRadius.circular(1.5),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            fillCalendarLabelBg
                                                ? '파스텔 배경 채움 스타일'
                                                : '투명 + 세로 컬러 바 스타일',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: kCalendarLabelDarkText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: fillCalendarLabelBg,
                                activeTrackColor: _kBlue,
                                onChanged: (v) => setSheetState(
                                  () => fillCalendarLabelBg = v,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            const Text(
                              '라벨 색상',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: _kLabel,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentColor,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ThemedColorPaletteGrid(
                          selectedHex: selectedHex,
                          compact: true,
                          onColorSelected: (hex) =>
                              setSheetState(() => selectedHex = hex),
                        ),
                        const SizedBox(height: 16),

                        // 하단 버튼
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetCtx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kSubLabel,
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) return;

                                  final newCat = ref
                                      .read(categoryListProvider.notifier)
                                      .addCategory(
                                        categoryKey:
                                            'custom_${DateTime.now().millisecondsSinceEpoch}',
                                        name: name,
                                        emoji: selectedIcon,
                                        colorHex: selectedHex,
                                        fillCalendarLabelBg:
                                            fillCalendarLabelBg,
                                      );

                                  setState(() {
                                    _selectedCategoryKey = newCat.categoryKey;
                                  });
                                  Navigator.pop(sheetCtx);
                                },
                                child: const Text(
                                  '추가',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReminderSection() {
    return _buildGroupCard(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined, size: 20, color: _kBlue),
            title: const Text('미리알림 (사전 알림)', style: TextStyle(fontSize: 15, color: _kLabel, fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _reminder != EventReminder.none ? _kChipSelected : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _reminder.labelKo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _reminder != EventReminder.none ? Colors.white : _kLabel,
                ),
              ),
            ),
            onTap: () async {
              final selected = await showModalBottomSheet<EventReminder>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => SafeArea(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🔔 미리알림 시간 선택',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kLabel),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: EventReminder.values.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final opt = EventReminder.values[index];
                              final isCurrent = _reminder == opt;
                              return ListTile(
                                title: Text(
                                  opt.labelKo,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrent ? _kBlue : _kLabel,
                                  ),
                                ),
                                trailing: isCurrent
                                    ? const Icon(Icons.check, color: _kBlue, size: 20)
                                    : null,
                                onTap: () {
                                  Navigator.pop(ctx, opt);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (selected != null) {
                setState(() => _reminder = selected);
                if (!mounted) return;
                if (selected != EventReminder.none) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔔 [${selected.labelKo}]에 사전 리마인더가 발송됩니다.'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSyncSection() {
    final googleList = ExternalCalendarPushService.instance.googleCalendars;
    final naverList = ExternalCalendarPushService.instance.naverCalendars;
    final googleColorId = ExternalCalendarPushService.instance.mapCategoryToGoogleColorId(_selectedCategoryKey);

    return _buildGroupCard(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: const Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Color(0xFF4285F4)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '구글 캘린더 연동 (단방향 Push)',
                    style: TextStyle(fontSize: 15, color: _kLabel),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            value: _syncGoogle,
            activeTrackColor: _kBlue,
            onChanged: (v) => setState(() => _syncGoogle = v),
          ),
          if (_syncGoogle) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedGoogleCalendarId,
                        items: googleList.map((target) {
                          return DropdownMenuItem<String>(
                            value: target.id,
                            child: Text(
                              '📅 ${target.name}',
                              style: const TextStyle(fontSize: 14, color: _kLabel),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGoogleCalendarId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, size: 13, color: Color(0xFF4285F4)),
                      const SizedBox(width: 4),
                      Text(
                        '카테고리 테마 색상 연동 (Google Color ID: $googleColorId 자동 매칭)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4285F4), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: _kDivider),
          SwitchListTile.adaptive(
            title: const Row(
              children: [
                Icon(Icons.calendar_month, size: 18, color: Color(0xFF03C75A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '네이버 캘린더 연동 (단방향 Push)',
                    style: TextStyle(fontSize: 15, color: _kLabel),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            value: _syncNaver,
            activeTrackColor: _kBlue,
            onChanged: (v) => setState(() => _syncNaver = v),
          ),
          if (_syncNaver) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedNaverCalendarId,
                    items: naverList.map((target) {
                      return DropdownMenuItem<String>(
                        value: target.id,
                        child: Text(
                          '📅 ${target.name}',
                          style: const TextStyle(fontSize: 14, color: _kLabel),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedNaverCalendarId = val);
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomSection() {
    final rooms = ref.watch(scheduleRoomsProvider);

    return _buildGroupCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.group_outlined, size: 18, color: _kLabel),
                SizedBox(width: 6),
                Text('모임 방 연동', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kLabel)),
              ],
            ),
            const SizedBox(height: 12),
            if (rooms.isEmpty)
              const Text('생성된 모임 방이 없습니다.', style: TextStyle(fontSize: 13, color: _kSubLabel))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final room in rooms)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedRoomIds.contains(room.id)) {
                            _selectedRoomIds.remove(room.id);
                          } else {
                            _selectedRoomIds.add(room.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedRoomIds.contains(room.id) ? _kBlue : _kChipBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedRoomIds.contains(room.id) ? Colors.white : _kLabel,
                              ),
                            ),
                            if (_selectedRoomIds.contains(room.id)) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.close, size: 14, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard({required Widget child}) {
    return Material(
      color: _kGroupBg,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
