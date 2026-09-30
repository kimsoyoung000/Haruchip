import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../models/schedule_room.dart';
import '../providers/schedule_room_provider.dart';
import '../widgets/add_room_event_dialog.dart';
import '../widgets/add_room_notice_dialog.dart';
import '../widgets/add_room_vote_dialog.dart';
import '../widgets/member_color_picker_dialog.dart';
import '../widgets/room_availability_month_grid.dart';
import 'settlement_screen.dart';

/// 모임 상세 화면 (공유 캘린더 · 일정 조율 · 공지/투표 · 스마트 정산)
class ScheduleRoomDetailScreen extends ConsumerStatefulWidget {
  const ScheduleRoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ScheduleRoomDetailScreen> createState() =>
      _ScheduleRoomDetailScreenState();
}

class _ScheduleRoomDetailScreenState
    extends ConsumerState<ScheduleRoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _focusedMonth;
  late DateTime _selectedCalendarDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final today = DateTime.now();
    _focusedMonth = DateTime(today.year, today.month, 1);
    _selectedCalendarDate = DateTime(today.year, today.month, today.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _shortDateLabel(String yyyyMMdd) {
    final parts = yyyyMMdd.split('-');
    if (parts.length != 3) return yyyyMMdd;
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = days[date.weekday - 1];
    return '${date.month}/${date.day}($weekday)';
  }

  Future<void> _handleConfirmDate(BuildContext context, ScheduleRoom room, String dateStr) async {
    ref.read(scheduleRoomsProvider.notifier).confirmDate(widget.roomId, dateStr);

    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      // Create a shared plan item in main personal calendar as well
      final planItem = PlanItem(
        id: 'plan-room-${DateTime.now().microsecondsSinceEpoch}',
        categoryKey: 'plan',
        title: '[${room.name}] 확정 모임',
        date: date,
        roomLinks: [room.id],
      );
      ref.read(planListProvider.notifier).addItem(planItem);

      // Also add as a room shared event
      final event = RoomSharedEvent(
        id: 'room-ev-${DateTime.now().microsecondsSinceEpoch}',
        roomId: room.id,
        title: '[모임 확정] ${room.name}',
        authorUid: room.members.first.uid,
        date: date,
        isAllDay: true,
      );
      ref.read(scheduleRoomsProvider.notifier).addRoomEvent(room.id, event);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎉 $dateStr 날짜로 모임 일정이 확정되었습니다!')),
    );
  }

  void _editMyProfile(ScheduleRoom room, RoomMember myMember) async {
    final takenColors = room.members
        .where((m) => m.uid != myMember.uid)
        .map((m) => m.colorHex)
        .toList();

    final nameController = TextEditingController(text: myMember.name);
    String currentIcon = myMember.icon;
    String currentColor = myMember.colorHex;

    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎨 내 프로필 & 컬러 칩 수정',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('대표 이모티콘', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['👤', '😎', '🐶', '🐱', '🐰', '🐼', '🦊', '🐻', '🐥', '🦄'].map((emo) {
                      final isSelected = emo == currentIcon;
                      return GestureDetector(
                        onTap: () => setDlgState(() => currentIcon = emo),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(emo, style: const TextStyle(fontSize: 18)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('내 컬러 칩 (50색 파스텔)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final pickedHex = await showMemberColorPickerDialog(
                        context,
                        currentColorHex: currentColor,
                        takenColorHexList: takenColors,
                      );
                      if (pickedHex != null) {
                        setDlgState(() => currentColor = pickedHex);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _hexToColor(currentColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(currentColor, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          const Text('색상 변경 >', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          ref.read(scheduleRoomsProvider.notifier).updateMemberCustomization(
                                roomId: room.id,
                                uid: myMember.uid,
                                name: nameController.text.trim(),
                                icon: currentIcon,
                                colorHex: currentColor,
                              );
                          Navigator.of(dlgCtx).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('수정 저장'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(scheduleRoomsProvider);
    final room = rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => ScheduleRoom(
        id: widget.roomId,
        name: '모임',
        inviteCode: '-',
        members: const [],
        dates: const {},
      ),
    );

    final myUid = room.members.isNotEmpty ? room.members.first.uid : '';
    final myMember = room.members.firstWhere(
      (m) => m.uid == myUid,
      orElse: () => RoomMember(uid: myUid, name: '나', icon: '👤', colorHex: '#A7F3D0'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room.categoryTag,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    room.name,
                    style: AppTypography.cardLabel.copyWith(
                      color: const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '초대 코드 복사',
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: room.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('초대 코드 [${room.inviteCode}]가 복사되었습니다. 친구에게 공유하세요!'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '내 프로필/컬러 설정',
            icon: const Icon(Icons.palette_outlined, size: 20),
            onPressed: () => _editMyProfile(room, myMember),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0F172A),
              indicatorWeight: 2.5,
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: '📅 공유캘린더'),
                Tab(text: '🗳️ 일정조율'),
                Tab(text: '📌 공지/투표'),
                Tab(text: '💰 정산'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSharedCalendarTab(room, myMember),
          _buildAvailabilityTab(room, myUid),
          _buildNoticeAndVoteTab(room, myMember),
          _buildSettlementTab(room),
        ],
      ),
    );
  }

  // 1. 공유 캘린더 탭
  Widget _buildSharedCalendarTab(ScheduleRoom room, RoomMember myMember) {
    final eventsForSelectedDate = room.events
        .where((e) =>
            e.date.year == _selectedCalendarDate.year &&
            e.date.month == _selectedCalendarDate.month &&
            e.date.day == _selectedCalendarDate.day)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Members Bar
          _buildMembersHorizontalBar(room, myMember),
          const SizedBox(height: 16),

          // Mini Month Grid
          _buildSharedCalendarMonthGrid(room),
          const SizedBox(height: 18),

          // Events of Selected Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedCalendarDate.month}월 ${_selectedCalendarDate.day}일 일정 (${eventsForSelectedDate.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newEvent = await showAddRoomEventDialog(
                    context,
                    roomId: room.id,
                    authorUid: myMember.uid,
                    initialDate: _selectedCalendarDate,
                  );
                  if (newEvent != null) {
                    ref.read(scheduleRoomsProvider.notifier).addRoomEvent(room.id, newEvent);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('일정 등록', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (eventsForSelectedDate.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  '선택된 날짜에 등록된 모임 일정이 없습니다',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            for (final ev in eventsForSelectedDate)
              _buildEventTile(room, ev),
        ],
      ),
    );
  }

  Widget _buildMembersHorizontalBar(ScheduleRoom room, RoomMember myMember) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '참여 멤버 (${room.members.length}명)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              InkWell(
                onTap: () => _editMyProfile(room, myMember),
                child: const Text(
                  '내 칩 설정 🎨',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in room.members)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hexToColor(m.colorHex).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _hexToColor(m.colorHex)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _hexToColor(m.colorHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${m.icon} ${m.name}${m.uid == myMember.uid ? ' (나)' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharedCalendarMonthGrid(ScheduleRoom room) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 0=Sun

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '$year년 $month월',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weekday header
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: w == '일' ? Colors.redAccent : (w == '토' ? Colors.blueAccent : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - firstWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(year, month, dayNum);
              final isSelected = cellDate.year == _selectedCalendarDate.year &&
                  cellDate.month == _selectedCalendarDate.month &&
                  cellDate.day == _selectedCalendarDate.day;

              // Find events on this date
              final dateEvents = room.events
                  .where((e) =>
                      e.date.year == cellDate.year &&
                      e.date.month == cellDate.month &&
                      e.date.day == cellDate.day)
                  .toList();

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCalendarDate = cellDate);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: const Color(0xFF0F172A), width: 1.5) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (cellDate.weekday == 7 ? Colors.redAccent : (cellDate.weekday == 6 ? Colors.blueAccent : const Color(0xFF334155))),
                        ),
                      ),
                      if (dateEvents.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dateEvents.take(3).map((ev) {
                              final author = room.members.firstWhere(
                                (m) => m.uid == ev.authorUid,
                                orElse: () => RoomMember(uid: '', name: '', icon: '', colorHex: '#38BDF8'),
                              );
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : _hexToColor(author.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(ScheduleRoom room, RoomSharedEvent ev) {
    final author = room.members.firstWhere(
      (m) => m.uid == ev.authorUid,
      orElse: () => RoomMember(uid: '', name: '멤버', icon: '👤', colorHex: '#38BDF8'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _hexToColor(author.colorHex).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${author.icon} ${author.name}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ev.isAllDay ? '하루 종일' : (ev.time ?? ''),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey),
                onPressed: () {
                  ref.read(scheduleRoomsProvider.notifier).removeRoomEvent(room.id, ev.id);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ev.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          if (ev.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(ev.location!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
          if (ev.memo != null) ...[
            const SizedBox(height: 4),
            Text(ev.memo!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ],
      ),
    );
  }

  // 2. 일정 조율 탭
  Widget _buildAvailabilityTab(ScheduleRoom room, String myUid) {
    final best = bestDateFor(room);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Soft Blue
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 20, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '가능한 날짜를 터치하여 등록하세요. 멤버들의 참여 가능 현황이 실시간 집계됩니다.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          RoomAvailabilityMonthGrid(
            focusedMonth: _focusedMonth,
            room: room,
            myUid: myUid,
            onDateToggle: (date) => ref
                .read(scheduleRoomsProvider.notifier)
                .toggleAvailability(widget.roomId, date, myUid),
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
          ),
          const SizedBox(height: 10),

          // Legend
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.protoStepLabel,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '전원 가능',
                style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.protoRadioSelectedBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '내가 체크함',
                style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Best Day Banner & Confirmation
          if (best.date != null && best.count > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3), // Soft Yellow Gold
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFDE047)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '최다 인원 가능일: ${_shortDateLabel(best.date!)} (${best.count}/${room.members.length}명)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF854D0E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleConfirmDate(context, room, best.date!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '이 날짜로 모임 확정하기',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '아직 아무도 가능 날짜를 표시하지 않았어요',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 3. 공지/투표 탭
  Widget _buildNoticeAndVoteTab(ScheduleRoom room, RoomMember myMember) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notices Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📌 공지 / 메모',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newNotice = await showAddRoomNoticeDialog(
                    context,
                    authorName: myMember.name,
                    authorIcon: myMember.icon,
                  );
                  if (newNotice != null) {
                    ref.read(scheduleRoomsProvider.notifier).addRoomNotice(room.id, newNotice);
                  }
                },
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('공지 작성', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (room.notices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('등록된 공지가 없습니다.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            )
          else
            for (final notice in room.notices)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: notice.isPinned ? const Color(0xFFFFFBEB) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: notice.isPinned ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (notice.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.push_pin, size: 14, color: Color(0xFFD97706)),
                          ),
                        Text(
                          '${notice.authorIcon} ${notice.authorName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            notice.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 16,
                            color: notice.isPinned ? const Color(0xFFD97706) : Colors.grey,
                          ),
                          onPressed: () => ref
                              .read(scheduleRoomsProvider.notifier)
                              .togglePinNotice(room.id, notice.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey),
                          onPressed: () => ref
                              .read(scheduleRoomsProvider.notifier)
                              .deleteRoomNotice(room.id, notice.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notice.content,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),

          const SizedBox(height: 24),

          // Votes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🗳️ 모임 투표',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newVote = await showAddRoomVoteDialog(
                    context,
                    authorUid: myMember.uid,
                  );
                  if (newVote != null) {
                    ref.read(scheduleRoomsProvider.notifier).createRoomVote(room.id, newVote);
                  }
                },
                icon: const Icon(Icons.how_to_vote_rounded, size: 16),
                label: const Text('투표 만들기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (room.votes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('진행 중인 투표가 없습니다.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            )
          else
            for (final vote in room.votes)
              _buildVoteCard(room, vote, myMember),
        ],
      ),
    );
  }

  Widget _buildVoteCard(ScheduleRoom room, RoomVote vote, RoomMember myMember) {
    final totalVoters = vote.options.fold<int>(0, (sum, o) => sum + o.voterUids.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: vote.isClosed ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vote.isClosed ? '종료됨' : (vote.allowMultiple ? '복수 투표' : '단일 투표'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: vote.isClosed ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '총 $totalVoters표',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vote.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          if (vote.description != null) ...[
            const SizedBox(height: 4),
            Text(vote.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 12),

          // Options List with Bar Gauges
          for (final opt in vote.options) ...[
            () {
              final isVoted = opt.voterUids.contains(myMember.uid);
              final ratio = totalVoters == 0 ? 0.0 : (opt.voterUids.length / totalVoters);

              return GestureDetector(
                onTap: vote.isClosed
                    ? null
                    : () {
                        ref.read(scheduleRoomsProvider.notifier).castVote(
                              roomId: room.id,
                              voteId: vote.id,
                              optionId: opt.id,
                              voterUid: myMember.uid,
                            );
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isVoted ? const Color(0xFFF8FAFC) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVoted ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      width: isVoted ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isVoted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isVoted ? const Color(0xFF0F172A) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isVoted ? FontWeight.w800 : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            '${opt.voterUids.length}표 (${(ratio * 100).toInt()}%)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress Bar Gauge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isVoted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  // 4. 정산 탭
  Widget _buildSettlementTab(ScheduleRoom room) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF0F172A)),
                    SizedBox(width: 8),
                    Text(
                      '스마트 N차 차수별 정산',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1차, 2차... N차 차수별 정산과 술값/특정 항목 예외 공제를 지원합니다. 최소 송금 횟수로 깔끔하게 계산해 드려요.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettlementScreen(roomId: room.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('정산 관리 및 송금하기', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Multi-round brief preview
          if (room.rounds.isNotEmpty) ...[
            const Text('등록된 차수별 내역', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            for (final r in room.rounds)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('참여 ${r.attendeeUids.length}명 · 예외 항목 ${r.exceptions.length}건', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    Text('${r.totalAmount}원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
