import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../data/room_remote.dart';
import '../providers/schedule_room_provider.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/join_room_dialog.dart';
import '../widgets/room_card.dart';
import 'schedule_room_detail_screen.dart';

/// 일정 조율 & 정산 방 목록 (칩 모임 메인 로비) 화면
/// 컴팩트 정보 밀도 향상 적용
class ScheduleRoomListScreen extends ConsumerWidget {
  const ScheduleRoomListScreen({super.key, this.onCreateRoom});

  final VoidCallback? onCreateRoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 모임방 서버 동기화 실패(권한·네트워크)를 사용자에게 알린다.
    ref.listen<String?>(roomSyncErrorProvider, (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.read(roomSyncErrorProvider.notifier).state = null;
    });
    final rooms = ref.watch(scheduleRoomsProvider);
    final myCode = ref.watch(myUserCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.cleanCanvasBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & My Code Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '칩 모임',
                          style: AppTypography.heading1.copyWith(
                            color: const Color(0xFF0F172A),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '그룹 캘린더 조율 · 공지 · 스마트 N차 정산',
                          style: AppTypography.bodyMuted.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: myCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('내 프로필 코드 [$myCode]가 복사되었습니다.')),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF475569)),
                          const SizedBox(width: 3),
                          Text(
                            myCode,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.copy_rounded, size: 10.5, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons: [+ 새 모임 만들기] & [🔑 코드로 참가]
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (onCreateRoom != null) {
                          onCreateRoom!();
                        } else {
                          showCreateRoomDialog(context);
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        '새 모임 만들기',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        overlayColor: const Color(0xFFF7D779),
                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showJoinRoomDialog(context),
                      icon: const Icon(Icons.key_rounded, size: 16, color: Color(0xFF0F172A)),
                      label: const Text(
                        '코드로 참가',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '참여 중인 모임 (${rooms.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Room Cards List
              if (rooms.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 10),
                      const Text(
                        '참여 중인 모임이 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '새로운 모임을 만들거나 코드를 입력하여 참여해보세요!',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => showCreateRoomDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.chipYellowBg,
                          foregroundColor: AppColors.chipYellowText,
                          overlayColor: const Color(0xFFF7D779),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text(
                          '모임 개설하기',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final room in rooms) ...[
                  RoomCard(
                    room: room,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ScheduleRoomDetailScreen(roomId: room.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
