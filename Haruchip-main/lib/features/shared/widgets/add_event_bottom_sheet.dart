import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/providers/schedule_room_provider.dart';
import '../../categories/logic/repeat_rule.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../../services/calendar/external_calendar_push_service.dart';
import 'haru_calendar_picker.dart';

// iOS Style Color Tokens
const Color _kSheetBg = Color(0xFFF2F2F7);
const Color _kGroupBg = Colors.white;
const Color _kDivider = Color(0xFFE5E5EA);
const Color _kLabel = Color(0xFF1C1C1E);
const Color _kSubLabel = Color(0xFF8E8E93);
const Color _kBlue = Color(0xFF007AFF);
const Color _kChipBg = Color(0xFFE5E5EA);
const Color _kChipSelected = Color(0xFF007AFF);

const Map<String, List<String>> _kPresets = {
  'couple': ['데이트', '기념일', '여행', '처음 만난 날', '100일'],
  'baby': ['예방접종', '첫걸음마', '첫말하기', '병원 방문', '백일', '돌잔치'],
  'pet': ['병원', '미용', '사료 구매', '산책', '예방접종'],
  'exam': ['필기시험', '실기시험', '원서접수', '합격발표', '중간고사', '기말고사', '토익'],
  'birthday': ['생일', '선물 준비', '파티', '케이크 예약'],
  'plan': ['미팅', '마감', '약속', '기획안', '클라이언트'],
  'military': ['입대', '전역', '면회', '외박'],
  'solo': ['혼자 여행', '자기개발', '취미 생활', '힐링 데이'],
  'fandom': ['최애 생일', '컴백일', '콘서트', '팬미팅', '앨범 발매', '티켓팅'],
  'group': ['정기 모임', '동창회', '회비 정산', '번개 모임', '스터디'],
};

const List<({RepeatType type, String label})> _kRepeatOptions = [
  (type: RepeatType.none, label: '반복 안 함'),
  (type: RepeatType.weekly, label: '매주'),
  (type: RepeatType.monthly, label: '매월'),
  (type: RepeatType.yearly, label: '매년'),
];

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
              : DateTime(start.year + 1, start.month, start.day)));

  final results = <DateTime>[];

  switch (repeatConfig.type) {
    case RepeatType.none:
      results.add(start);
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
    this.existingItem,
  });

  final String categoryKey;
  final String? categoryInstanceId;
  final String? initialRoomId;
  final DateTime? initialDate;
  final PlanItem? existingItem;

  @override
  ConsumerState<AddEventBottomSheet> createState() => _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends ConsumerState<AddEventBottomSheet> {
  int _tabIndex = 0; // 0: 이벤트, 1: 미리 알림
  late String _selectedCategoryKey;
  final _titleCtrl = TextEditingController();
  final List<String> _customTags = [];

  // Display Mode
  DdayDisplayMode _displayMode = DdayDisplayMode.dday;

  // Date & Time
  bool _isAllDay = false;
  late DateTime _startDate;
  TimeOfDay? _startTime;
  bool _hasEndDate = false;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // Repeat
  RepeatType _repeatType = RepeatType.none;
  final List<int> _selectedWeekdays = [];
  final List<int> _selectedDaysOfMonth = [];
  final List<String> _selectedDaysOfYear = [];
  DateTime? _repeatEndDate;

  // Calendar Sync
  bool _syncGoogle = false;
  bool _syncNaver = false;
  String _selectedGoogleCalendarId = 'primary';
  String _selectedNaverCalendarId = 'default';

  // Room Links
  final List<String> _selectedRoomIds = [];

  // Expanded Calendar Accordion ('start' | 'end' | 'repeatEnd' | null)
  String? _expandedCalendar;

  @override
  void initState() {
    super.initState();
    _selectedCategoryKey = widget.categoryKey.isEmpty ? 'plan' : widget.categoryKey;
    final now = DateTime.now();
    _startDate = widget.initialDate ?? DateTime(now.year, now.month, now.day);

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _selectedCategoryKey = item.categoryKey;
      _titleCtrl.text = item.title;
      _startDate = item.date;
      _displayMode = item.displayMode;
      _isAllDay = item.isAllDay;
      _startTime = item.deadlineTime;
      _hasEndDate = item.endDate != null;
      _endDate = item.endDate;
      _endTime = item.endDeadlineTime;
      _repeatType = item.repeatConfig.type;
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
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String get _headerTitle {
    final isEdit = widget.existingItem != null;
    final prefix = switch (_selectedCategoryKey) {
      'couple' => '커플',
      'baby' => '아기',
      'pet' => '반려동물',
      'exam' => '시험',
      'birthday' => '생일',
      'plan' => '내 일정',
      'military' => '군대',
      'solo' => '솔로',
      'fandom' => '덕질',
      'group' => '모임',
      _ => '일정',
    };
    return isEdit ? '$prefix 일정 수정' : '$prefix 일정 추가';
  }

  void _onTagPressed(String tag) {
    final cur = _titleCtrl.text.trim();
    if (cur.isEmpty) {
      _titleCtrl.text = tag;
    } else {
      _titleCtrl.text = '$tag $cur';
    }

    // Preset auto-behaviors
    if (tag == '데이트' || tag == '여행') {
      _displayMode = DdayDisplayMode.dday;
    } else if (tag == '기념일') {
      _displayMode = DdayDisplayMode.dday;
      _repeatType = RepeatType.yearly;
    }
    setState(() {});
  }

  Future<void> _showAddCustomTagDialog() async {
    final tagCtrl = TextEditingController();
    final newTag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('태그 직접 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '새 태그 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white),
            onPressed: () {
              final text = tagCtrl.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (newTag != null && newTag.isNotEmpty) {
      setState(() {
        if (!_customTags.contains(newTag)) {
          _customTags.add(newTag);
        }
      });
      _onTagPressed(newTag);
    }
  }

  void _handleSave() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final config = RepeatConfig(
      type: _repeatType,
      weekdays: _repeatType == RepeatType.weekly ? _selectedWeekdays : [],
      daysOfMonth: _repeatType == RepeatType.monthly ? _selectedDaysOfMonth : [],
      daysOfYear: _repeatType == RepeatType.yearly ? _selectedDaysOfYear : [],
    );

    if (widget.existingItem != null) {
      // Edit mode: update single or base item
      final item = widget.existingItem!.copyWith(
        title: title,
        date: _startDate,
        categoryKey: _selectedCategoryKey,
        categoryInstanceId: widget.categoryInstanceId,
        displayMode: _displayMode,
        repeatConfig: config,
        calendarSync: CalendarSyncFlags(google: _syncGoogle, naver: _syncNaver, haruchip: true),
        deadlineTime: _startTime,
        endDate: _hasEndDate ? _endDate : null,
        endDeadlineTime: _hasEndDate ? _endTime : null,
        isAllDay: _isAllDay,
        roomLinks: _selectedRoomIds,
      );
      ref.read(planListProvider.notifier).updateItem(item);

      // External calendar push
      ExternalCalendarPushService.instance.pushPlanItem(
        item: item,
        googleCalendarId: _selectedGoogleCalendarId,
        naverCalendarId: _selectedNaverCalendarId,
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
            categoryInstanceId: widget.categoryInstanceId,
            title: title,
            date: dates[i],
            displayMode: _displayMode,
            repeatConfig: config,
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

        if (items.isNotEmpty) {
          ExternalCalendarPushService.instance.pushPlanItem(
            item: items.first,
            googleCalendarId: _selectedGoogleCalendarId,
            naverCalendarId: _selectedNaverCalendarId,
          );
        }
      } else {
        final item = PlanItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          categoryKey: _selectedCategoryKey,
          categoryInstanceId: widget.categoryInstanceId,
          title: title,
          date: _startDate,
          displayMode: _displayMode,
          repeatConfig: config,
          calendarSync: CalendarSyncFlags(google: _syncGoogle, naver: _syncNaver, haruchip: true),
          deadlineTime: _startTime,
          endDate: _hasEndDate ? _endDate : null,
          endDeadlineTime: _hasEndDate ? _endTime : null,
          isAllDay: _isAllDay,
          roomLinks: _selectedRoomIds,
        );
        ref.read(planListProvider.notifier).addItem(item);

        ExternalCalendarPushService.instance.pushPlanItem(
          item: item,
          googleCalendarId: _selectedGoogleCalendarId,
          naverCalendarId: _selectedNaverCalendarId,
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

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
                Text(
                  _headerTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kLabel),
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
          // Segment Control Tab: [이벤트] / [미리 알림]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  _buildSegmentTabItem('이벤트', 0),
                  _buildSegmentTabItem('미리 알림', 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Form Scroll View
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, mediaQuery.viewInsets.bottom + 32),
              children: [
                // 0. Category Target Selector (내 일정 / 커플 / 솔로 / 덕질 / 모임 등)
                _buildCategoryTargetSection(),
                const SizedBox(height: 14),

                // 1. Title & Quick Tags
                _buildTitleSection(),
                const SizedBox(height: 14),

                // 2. Display Mode Segment (D-Day | N일째 | 개월수)
                _buildDisplayModeSection(),
                const SizedBox(height: 14),

                // 3. Date & Time Section (All Day, Start Date/Time, End Date/Time)
                _buildDateTimeSection(),
                const SizedBox(height: 14),

                // 4. Repeat Settings
                _buildRepeatSection(),
                const SizedBox(height: 14),

                // 5. Calendar Sync (Google / Naver One-way Outbound Push)
                _buildCalendarSyncSection(),
                const SizedBox(height: 14),

                // 6. Room Links
                _buildRoomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTabItem(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? _kLabel : _kSubLabel,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTargetSection() {
    const categoryOptions = [
      (key: 'plan', label: '내 일정', emoji: '📝', color: Color(0xFF007AFF)),
      (key: 'couple', label: '커플', emoji: '❤️', color: Color(0xFFFF2D55)),
      (key: 'solo', label: '솔로', emoji: '🌟', color: Color(0xFF9333EA)),
      (key: 'fandom', label: '덕질', emoji: '⭐', color: Color(0xFFF59E0B)),
      (key: 'group', label: '모임', emoji: '👥', color: Color(0xFF10B981)),
      (key: 'exam', label: '시험', emoji: '📚', color: Color(0xFF4F46E5)),
      (key: 'birthday', label: '생일', emoji: '🎂', color: Color(0xFFEC4899)),
      (key: 'baby', label: '아기', emoji: '👶', color: Color(0xFFF59E0B)),
      (key: 'pet', label: '반려동물', emoji: '🐾', color: Color(0xFFD97706)),
      (key: 'military', label: '군대', emoji: '🎖️', color: Color(0xFF556B2F)),
    ];

    return _buildGroupCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: _kLabel),
                SizedBox(width: 6),
                Text(
                  '등록 카테고리 (D-Day 자동 연동)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kLabel),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in categoryOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryKey = cat.key;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedCategoryKey == cat.key
                                ? cat.color.withValues(alpha: 0.15)
                                : _kChipBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedCategoryKey == cat.key
                                  ? cat.color
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedCategoryKey == cat.key ? FontWeight.bold : FontWeight.w500,
                                  color: _selectedCategoryKey == cat.key ? cat.color : _kLabel,
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
    );
  }

  Widget _buildTitleSection() {
    final defaultPresets = _kPresets[_selectedCategoryKey] ?? ['기념일', '일정', '약속'];
    final allTags = [...defaultPresets, ..._customTags];
    final placeholder = switch (_selectedCategoryKey) {
      'couple' => '예: 우리 100일, 여행 기념일',
      'solo' => '예: 혼자만의 힐링 여행, 취미 시작',
      'fandom' => '예: 최애 컴백일, 콘서트 티켓팅, 팬미팅',
      'group' => '예: 동창회, 정기 모임, 스터디',
      'exam' => '예: 정보처리기사 필기, 토익',
      'birthday' => '예: 엄마 생신, ○○이 생일',
      'baby' => '예: 첫 뒤집기, 백일 사진',
      'pet' => '예: 병원 예약, 산책',
      'military' => '예: 전역까지, 첫 휴가',
      _ => '제목 입력 (예: 기획안 마감, 클라이언트 미팅)',
    };

    return _buildGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 16, color: _kLabel),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: _kSubLabel, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in allTags)
                  InkWell(
                    onTap: () => _onTagPressed(tag),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kChipBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kLabel),
                      ),
                    ),
                  ),
                InkWell(
                  onTap: _showAddCustomTagDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFC7C7CC)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '+ 직접 추가',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Row(
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
    return _buildGroupCard(
      child: Column(
        children: [
          // 하루 종일 Switch
          SwitchListTile.adaptive(
            title: const Text('하루 종일', style: TextStyle(fontSize: 15, color: _kLabel)),
            value: _isAllDay,
            activeTrackColor: _kBlue,
            onChanged: (v) => setState(() => _isAllDay = v),
          ),
          const Divider(height: 1, color: _kDivider),

          // 시작일
          ListTile(
            title: const Text('시작일', style: TextStyle(fontSize: 15, color: _kLabel)),
            trailing: Text(
              '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 15, color: _kBlue, fontWeight: FontWeight.bold),
            ),
            onTap: () => setState(() {
              _expandedCalendar = _expandedCalendar == 'start' ? null : 'start';
            }),
          ),
          if (_expandedCalendar == 'start')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: HaruCalendarPicker(
                initialDate: _startDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                onDateChanged: (d) => setState(() {
                  _startDate = d;
                  _expandedCalendar = null;
                }),
              ),
            ),

          // 시작 시간 (하루 종일이 꺼져 있을 때)
          if (!_isAllDay) ...[
            const Divider(height: 1, color: _kDivider),
            ListTile(
              title: const Text('시작 시간', style: TextStyle(fontSize: 15, color: _kLabel)),
              trailing: Text(
                _startTime != null ? _startTime!.format(context) : '시간 설정',
                style: TextStyle(fontSize: 15, color: _startTime != null ? _kBlue : _kSubLabel),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? TimeOfDay.now(),
                );
                if (time != null) setState(() => _startTime = time);
              },
            ),
          ],

          const Divider(height: 1, color: _kDivider),

          // 종료일 설정 Switch
          SwitchListTile.adaptive(
            title: const Text('종료일 설정', style: TextStyle(fontSize: 15, color: _kLabel)),
            value: _hasEndDate,
            activeTrackColor: _kBlue,
            onChanged: (v) => setState(() {
              _hasEndDate = v;
              if (v && _endDate == null) _endDate = _startDate;
            }),
          ),

          if (_hasEndDate) ...[
            const Divider(height: 1, color: _kDivider),
            ListTile(
              title: const Text('종료일', style: TextStyle(fontSize: 15, color: _kLabel)),
              trailing: Text(
                _endDate != null
                    ? '${_endDate!.year}.${_endDate!.month.toString().padLeft(2, '0')}.${_endDate!.day.toString().padLeft(2, '0')}'
                    : '종료일 선택',
                style: const TextStyle(fontSize: 15, color: _kBlue, fontWeight: FontWeight.bold),
              ),
              onTap: () => setState(() {
                _expandedCalendar = _expandedCalendar == 'end' ? null : 'end';
              }),
            ),
            if (_expandedCalendar == 'end')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: HaruCalendarPicker(
                  initialDate: _endDate ?? _startDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  onDateChanged: (d) => setState(() {
                    _endDate = d;
                    _expandedCalendar = null;
                  }),
                ),
              ),
            // 종료 시간 (하루 종일이 꺼져 있을 때)
            if (!_isAllDay) ...[
              const Divider(height: 1, color: _kDivider),
              ListTile(
                title: const Text('종료 시간', style: TextStyle(fontSize: 15, color: _kLabel)),
                trailing: Text(
                  _endTime != null ? _endTime!.format(context) : '시간 설정',
                  style: TextStyle(fontSize: 15, color: _endTime != null ? _kBlue : _kSubLabel),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _endTime = time);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRepeatSection() {
    final repeatLabel = _kRepeatOptions.firstWhere((o) => o.type == _repeatType).label;

    return _buildGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text('반복', style: TextStyle(fontSize: 15, color: _kLabel)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  repeatLabel,
                  style: const TextStyle(fontSize: 15, color: _kBlue, fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.chevron_right, size: 20, color: _kSubLabel),
              ],
            ),
            onTap: () async {
              final val = await showMenu<RepeatType>(
                context: context,
                position: const RelativeRect.fromLTRB(100, 300, 16, 0),
                items: _kRepeatOptions.map((o) => PopupMenuItem(value: o.type, child: Text(o.label))).toList(),
              );
              if (val != null) setState(() => _repeatType = val);
            },
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
              onTap: () => setState(() {
                _expandedCalendar = _expandedCalendar == 'repeatEnd' ? null : 'repeatEnd';
              }),
            ),
            if (_expandedCalendar == 'repeatEnd')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: HaruCalendarPicker(
                  initialDate: _repeatEndDate ?? _startDate.add(const Duration(days: 365)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  onDateChanged: (d) => setState(() {
                    _repeatEndDate = d;
                    _expandedCalendar = null;
                  }),
                ),
              ),
          ],
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
                Text('구글 캘린더 연동 (단방향 Push)', style: TextStyle(fontSize: 15, color: _kLabel)),
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
                Text('네이버 캘린더 연동 (단방향 Push)', style: TextStyle(fontSize: 15, color: _kLabel)),
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
    return Container(
      decoration: BoxDecoration(
        color: _kGroupBg,
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
    );
  }
}
