import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../trash/models/trash_item.dart';
import '../../trash/providers/trash_provider.dart';
import '../data/calendar_mock_data.dart';
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
  Timer? _countdownTimer;
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _expandedSettlementAccordions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final today = DateTime.now();
    _focusedMonth = DateTime(today.year, today.month, 1);
    _selectedCalendarDate = DateTime(today.year, today.month, today.day);

    // 1초 주기로 투표 마감 카운트다운 갱신
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.dispose();
    for (final c in _commentControllers.values) {
      c.dispose();
    }
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
        .map((m) => m.colorHex.toUpperCase())
        .toList();

    final pickedHex = await showMemberColorPickerDialog(
      context,
      currentColorHex: myMember.colorHex,
      takenColorHexList: takenColors,
    );

    if (pickedHex != null) {
      ref.read(scheduleRoomsProvider.notifier).updateMemberCustomization(
            roomId: room.id,
            uid: myMember.uid,
            colorHex: pickedHex,
          );
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 모임 초대코드 [$code] 복사 완료!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSend(BuildContext context, String provider, String toName, int amount) {
    final label = provider == 'kakao' ? '카카오페이' : '토스';
    Clipboard.setData(ClipboardData(text: '$toName $amount원'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('💸 $label 송금 정보 복사 완료 — $toName에게 $amount원')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(scheduleRoomsProvider);
    final room = rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => mockScheduleRooms.first,
    );

    final myProfile = ref.watch(currentUserProfileProvider);
    final myMember = room.members.firstWhere(
      (m) => m.uid == myProfile.uid || m.name == myProfile.name,
      orElse: () => room.members.isNotEmpty
          ? room.members.first
          : RoomMember(uid: myProfile.uid, name: myProfile.name, icon: myProfile.icon),
    );

    final pinnedNotices = room.notices.where((n) => n.isPinned).toList();

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.protoHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room.categoryTag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _copyInviteCode(room.inviteCode),
              child: Row(
                children: [
                  Text(
                    '코드: ${room.inviteCode}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0F172A)),
            tooltip: '내 컬러 및 이모지 변경',
            onPressed: () => _editMyProfile(room, myMember),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF0F172A),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '공유 캘린더'),
            Tab(text: '일정 조율'),
            Tab(text: '공지 / 투표'),
            Tab(text: '정산 장부'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 상단 고정(Pin) 공지 배너
          if (pinnedNotices.isNotEmpty) _buildPinnedNoticesBanner(room, pinnedNotices),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSharedCalendarTab(room, myMember),
                _buildAvailabilityTab(room, myMember.uid),
                _buildNoticeAndVoteTab(room, myMember),
                _buildSettlementTab(room, myMember),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 0. 상단 고정(Pin) 공지사항 배너
  Widget _buildPinnedNoticesBanner(ScheduleRoom room, List<RoomNotice> pinnedNotices) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      '📌 고정 공지',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                    if (pinnedNotices.length > 1)
                      Text(
                        ' (외 ${pinnedNotices.length - 1}건)',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF92400E)),
                      ),
                  ],
                ),
                Text(
                  pinnedNotices.first.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD97706)),
            onPressed: () {
              _tabController.animateTo(2); // 공지 탭으로 이동
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // 1. 공유 캘린더 탭
  Widget _buildSharedCalendarTab(ScheduleRoom room, RoomMember myMember) {
    final selectedEvents = room.events.where((e) {
      return e.date.year == _selectedCalendarDate.year &&
          e.date.month == _selectedCalendarDate.month &&
          e.date.day == _selectedCalendarDate.day;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member avatars row
          _buildMembersHorizontalList(room),
          const SizedBox(height: 16),

          // Shared Month Calendar Grid
          _buildSharedCalendarMonthGrid(room),
          const SizedBox(height: 16),

          // Events on selected date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedCalendarDate.month}월 ${_selectedCalendarDate.day}일 공유 일정',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              TextButton.icon(
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
                icon: const Icon(Icons.add, size: 16),
                label: const Text('일정 등록', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (selectedEvents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('이 날짜에는 등록된 일정이 없습니다.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            )
          else
            for (final ev in selectedEvents) _buildEventTile(room, ev),
        ],
      ),
    );
  }

  Widget _buildMembersHorizontalList(ScheduleRoom room) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              InkWell(
                onTap: () => _copyInviteCode(room.inviteCode),
                child: const Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text('친구 초대', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: room.members.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _hexToColor(m.colorHex).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _hexToColor(m.colorHex)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      m.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    if (m.isHost) ...[
                      const SizedBox(width: 4),
                      const Text('👑', style: TextStyle(fontSize: 10)),
                    ],
                  ],
                ),
              );
            }).toList(),
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
                                orElse: () => const RoomMember(uid: '', name: '', icon: '', colorHex: '#38BDF8'),
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
      orElse: () => const RoomMember(uid: '', name: '멤버', icon: '👤', colorHex: '#38BDF8'),
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
                  ref.read(trashBinProvider.notifier).moveToTrash(
                        TrashItem(
                          id: 'trash-ev-${ev.id}',
                          entityType: TrashEntityType.event,
                          originalTitle: ev.title,
                          deletedAt: DateTime.now(),
                          originalData: ev.toJson(),
                          roomId: room.id,
                        ),
                      );
                  ref.read(scheduleRoomsProvider.notifier).removeRoomEvent(room.id, ev.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('일정이 휴지통으로 이동되었습니다 (30일 보존)')),
                  );
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
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Availability Matrix Grid
          RoomAvailabilityMonthGrid(
            room: room,
            focusedMonth: _focusedMonth,
            myUid: myUid,
            onDateToggle: (dateStr) {
              ref.read(scheduleRoomsProvider.notifier).toggleAvailability(room.id, dateStr, myUid);
            },
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
          ),
          const SizedBox(height: 20),

          // Best Day Banner & Confirmation
          if (best.date != null && best.count > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
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
                    authorUid: myMember.uid,
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
              _buildNoticeCard(room, notice, myMember),

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

  // 공지사항 카드 (핀 고정, 읽음 확인, 댓글)
  Widget _buildNoticeCard(ScheduleRoom room, RoomNotice notice, RoomMember myMember) {
    final hasRead = notice.confirmedMemberUids.contains(myMember.uid);
    final confirmedMembers = room.members
        .where((m) => notice.confirmedMemberUids.contains(m.uid))
        .toList();

    _commentControllers.putIfAbsent(notice.id, () => TextEditingController());
    final commentCtrl = _commentControllers[notice.id]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notice.isPinned ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notice.isPinned ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: notice.isPinned ? 1.5 : 1,
        ),
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                onSelected: (val) async {
                  if (val == 'pin') {
                    ref.read(scheduleRoomsProvider.notifier).togglePinNotice(room.id, notice.id);
                  } else if (val == 'edit') {
                    final updated = await showAddRoomNoticeDialog(
                      context,
                      authorName: notice.authorName,
                      authorIcon: notice.authorIcon,
                      authorUid: notice.authorUid,
                      existingNotice: notice,
                    );
                    if (updated != null) {
                      ref.read(scheduleRoomsProvider.notifier).updateRoomNotice(room.id, updated);
                    }
                  } else if (val == 'delete') {
                    ref.read(trashBinProvider.notifier).moveToTrash(
                          TrashItem(
                            id: 'trash-notice-${notice.id}',
                            entityType: TrashEntityType.notice,
                            originalTitle: notice.content,
                            deletedAt: DateTime.now(),
                            originalData: notice.toJson(),
                            roomId: room.id,
                            authorName: notice.authorName,
                          ),
                        );
                    ref.read(scheduleRoomsProvider.notifier).deleteRoomNotice(room.id, notice.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공지가 휴지통으로 이동되었습니다 (30일 보존)')),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(notice.isPinned ? '📌 핀 고정 해제' : '📌 상단 핀 고정'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('✏️ 공지 수정'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('🗑️ 삭제 (휴지통)'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notice.content,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.4),
          ),
          const SizedBox(height: 12),

          // 읽음 / 확인 완료 버튼 & 확인한 멤버 프로필 목록
          Row(
            children: [
              InkWell(
                onTap: () {
                  ref.read(scheduleRoomsProvider.notifier).toggleNoticeRead(room.id, notice.id, myMember.uid);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasRead ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasRead ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRead ? Icons.check_circle_rounded : Icons.thumb_up_alt_outlined,
                        size: 14,
                        color: hasRead ? const Color(0xFF16A34A) : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasRead ? '확인 완료' : '확인했습니다',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasRead ? const Color(0xFF16A34A) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (confirmedMembers.isNotEmpty)
                Expanded(
                  child: Text(
                    '${confirmedMembers.length}명 확인 (${confirmedMembers.map((m) => '${m.icon} ${m.name}').join(', ')})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),

          // 댓글 피드
          if (notice.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            for (final c in notice.comments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.authorIcon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                          children: [
                            TextSpan(text: '${c.authorName}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: c.content),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // 댓글 작성 필드
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentCtrl,
                  decoration: InputDecoration(
                    hintText: '공지에 댓글 달기...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF0F172A)),
                onPressed: () {
                  final text = commentCtrl.text.trim();
                  if (text.isNotEmpty) {
                    ref.read(scheduleRoomsProvider.notifier).addNoticeComment(
                          room.id,
                          notice.id,
                          NoticeComment(
                            id: 'cmt-${DateTime.now().microsecondsSinceEpoch}',
                            authorUid: myMember.uid,
                            authorName: myMember.name,
                            authorIcon: myMember.icon,
                            content: text,
                            createdAt: DateTime.now(),
                          ),
                        );
                    commentCtrl.clear();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 투표 카드 (실시간 카운트다운 타이머, 복수/익명 투표, 재투표, 수정/마감/삭제)
  Widget _buildVoteCard(ScheduleRoom room, RoomVote vote, RoomMember myMember) {
    final totalVoters = vote.options.fold<int>(0, (sum, o) => sum + o.voterUids.length);
    final isClosed = vote.isExpiredOrClosed;
    final isCreator = vote.authorUid == myMember.uid || room.members.first.uid == myMember.uid;
    final myVotedCount = vote.options.where((o) => o.voterUids.contains(myMember.uid)).length;

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
          // Header badges & Countdown Timer
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isClosed ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isClosed ? '종료됨' : (vote.allowMultiple ? '복수 투표' : '단일 투표'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isClosed ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                  ),
                ),
              ),
              if (vote.isAnonymous) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '익명',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
                  ),
                ),
              ],
              const Spacer(),
              // Realtime Countdown Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isClosed ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: isClosed ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vote.remainingTimeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isClosed ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCreator) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      final updated = await showAddRoomVoteDialog(
                        context,
                        authorUid: myMember.uid,
                        existingVote: vote,
                      );
                      if (updated != null) {
                        ref.read(scheduleRoomsProvider.notifier).updateRoomVote(room.id, updated);
                      }
                    } else if (val == 'close') {
                      ref.read(scheduleRoomsProvider.notifier).closeRoomVote(room.id, vote.id);
                    } else if (val == 'delete') {
                      ref.read(trashBinProvider.notifier).moveToTrash(
                            TrashItem(
                              id: 'trash-vote-${vote.id}',
                              entityType: TrashEntityType.vote,
                              originalTitle: vote.title,
                              deletedAt: DateTime.now(),
                              originalData: vote.toJson(),
                              roomId: room.id,
                            ),
                          );
                      ref.read(scheduleRoomsProvider.notifier).deleteRoomVote(room.id, vote.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('투표가 휴지통으로 이동되었습니다 (30일 보존)')),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!isClosed)
                      const PopupMenuItem(value: 'close', child: Text('🔒 조기 마감하기')),
                    const PopupMenuItem(value: 'edit', child: Text('✏️ 투표 수정')),
                    const PopupMenuItem(value: 'delete', child: Text('🗑️ 삭제 (휴지통)')),
                  ],
                ),
              ],
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
              final voterMembers = room.members
                  .where((m) => opt.voterUids.contains(m.uid))
                  .toList();

              return GestureDetector(
                onTap: isClosed
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
                      // 익명이 아닐 경우 투표자 프로필 뱃지 노출
                      if (!vote.isAnonymous && voterMembers.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: voterMembers.map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _hexToColor(m.colorHex).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${m.icon} ${m.name}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }(),
          ],

          // 다시 투표하기 버튼
          if (!isClosed && myVotedCount > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(scheduleRoomsProvider.notifier).reVote(room.id, vote.id, myMember.uid);
                },
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('다시 투표하기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  // 4. 정산 장부 탭 (누적 히스토리 피드, 송금 상태 토글, 프로그레스 바)
  Widget _buildSettlementTab(ScheduleRoom room, RoomMember myMember) {
    final history = room.settlementHistory;

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
                      '스마트 N차 정산 및 송금 장부',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1차, 2차... N차 차수별 정산과 술값/특정 항목 예외 공제를 영수증 카드로 기록하고, 멤버별 송금 여부를 실시간 추적하세요.',
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
                    label: const Text('+ 새 정산 계산 및 영수증 발행', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 20),

          // Cumulative Settlement History Feed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🧾 정산 영수증 히스토리',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Text(
                '총 ${history.length}건',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('발행된 정산 영수증이 없습니다.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            )
          else
            for (final record in history)
              _buildSettlementRecordCard(room, record, myMember),
        ],
      ),
    );
  }

  // 정산 영수증 카드 (송금 상태 토글, 프로그레스 바, 차수별 상세 아코디언)
  Widget _buildSettlementRecordCard(ScheduleRoom room, SettlementRecord record, RoomMember myMember) {
    final isExpanded = _expandedSettlementAccordions.contains(record.id);

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
          // Card Header: Date & Title & Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.date.year}.${record.date.month.toString().padLeft(2, '0')}.${record.date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${record.totalAmount}원',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'delete') {
                        ref.read(trashBinProvider.notifier).moveToTrash(
                              TrashItem(
                                id: 'trash-settle-${record.id}',
                                entityType: TrashEntityType.settlement,
                                originalTitle: record.title,
                                deletedAt: DateTime.now(),
                                originalData: record.toJson(),
                                roomId: room.id,
                              ),
                            );
                        ref.read(scheduleRoomsProvider.notifier).deleteSettlementRecord(room.id, record.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('정산 내역이 휴지통으로 이동되었습니다 (30일 보존)')),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('🗑️ 삭제 (휴지통)')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 송금 완료 현황 프로그레스 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '송금 완료 현황 (${record.completedTransfersCount}/${record.totalTransferTargetCount}명)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              Text(
                '${(record.transferProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: record.transferProgress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // 멤버별 송금 상태 칩 목록
          const Text('멤버별 송금 상태 (터치하여 토글)', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.transferStatus.entries.map((entry) {
              final memberUid = entry.key;
              final isTransferred = entry.value;
              final member = room.members.firstWhere(
                (m) => m.uid == memberUid,
                orElse: () => RoomMember(uid: memberUid, name: memberUid, icon: '👤'),
              );
              final owedAmount = record.perMemberAmounts[memberUid] ?? 0;

              return InkWell(
                onTap: () {
                  ref.read(scheduleRoomsProvider.notifier).toggleTransferStatus(room.id, record.id, memberUid);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTransferred ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTransferred ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(member.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        member.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 6),
                      if (owedAmount > 0)
                        Text(
                          '$owedAmount원 ',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      Icon(
                        isTransferred ? Icons.check_circle_rounded : Icons.pending_outlined,
                        size: 14,
                        color: isTransferred ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isTransferred ? '완료' : '미입금',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isTransferred ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // 아코디언 토글 (1차, 2차 내역, 예외 차감 내역)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSettlementAccordions.remove(record.id);
                } else {
                  _expandedSettlementAccordions.add(record.id);
                }
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExpanded ? '차수별 상세 내역 접기' : '차수별 상세 내역 보기 (${record.rounds.length}개 차수)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            const SizedBox(height: 10),
            for (final r in record.rounds)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${r.roundNumber}차: ${r.title}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${r.totalAmount}원',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '결제자: ${r.payerUid} | 참여자: ${r.attendeeUids.join(', ')}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    if (r.exceptions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (final exp in r.exceptions)
                        Text(
                          '└ 예외: ${exp.name} ${exp.amount}원 (${exp.exemptMemberUids.join(', ')} 제외)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                        ),
                    ],
                  ],
                ),
              ),
          ],

          const SizedBox(height: 8),
          // 송금 링크 복사 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleSend(context, 'kakao', record.title, record.totalAmount),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('카카오페이 복사', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleSend(context, 'toss', record.title, record.totalAmount),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('토스 복사', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
