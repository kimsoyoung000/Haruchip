import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../friends/providers/friend_system_provider.dart';
import '../data/room_remote.dart';
import '../models/schedule_room.dart';
import '../providers/schedule_room_provider.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/room_card.dart';
import 'schedule_room_detail_screen.dart';

/// 일정 조율 & 정산 방 목록 (칩 모임 메인 로비) 화면
///
/// - 텍스트 난수 초대 코드 및 [코드로 참가] UI 영구 제거
/// - 100% 친구 초대 수락([받은 모임 초대]) 및 [새 모임 만들기] 방식으로 전환
class ScheduleRoomListScreen extends ConsumerWidget {
  const ScheduleRoomListScreen({super.key, this.onCreateRoom});

  final VoidCallback? onCreateRoom;

  void _showPendingInvitationsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final invites = ref.watch(pendingRoomInvitationsProvider);
          final myBattle = ref.watch(friendSystemProvider).myProfile;
          final myRoomProfile = ref.watch(currentUserProfileProvider);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '받은 모임 초대 (${invites.length})',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Color(0xFF9CA3AF)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (invites.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cleanCanvasBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '받은 모임 초대가 아직 없어요.\n친구가 모임에서 초대하면 여기에 바로 표시됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    for (final inv in invites)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cleanCanvasBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.roomName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.protoHeading,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${inv.inviterName}님의 초대 · ${inv.categoryTag}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(
                                        pendingRoomInvitationsProvider.notifier)
                                    .state = invites
                                    .where((i) => i.id != inv.id)
                                    .toList();
                              },
                              child: const Text(
                                '거절',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(scheduleRoomsProvider.notifier)
                                    .acceptRoomInvitation(
                                      inv,
                                      RoomMember(
                                        uid: myRoomProfile.uid,
                                        name: myBattle.nickname,
                                        icon: myBattle.avatarIcon,
                                        colorHex: myRoomProfile.colorHex,
                                      ),
                                    );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('[${inv.roomName}] 모임에 참여했습니다!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.chipYellowBg,
                                foregroundColor: AppColors.chipYellowText,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text(
                                '수락',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(roomSyncErrorProvider, (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.read(roomSyncErrorProvider.notifier).state = null;
    });
    final rooms = ref.watch(scheduleRoomsProvider);
    final pendingInvites = ref.watch(pendingRoomInvitationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cleanCanvasBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 타이틀 (난수 코드 뱃지 영구 제거)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                ],
              ),
              const SizedBox(height: 12),

              // 상단 액션: [+ 새 모임 만들기] & [받은 모임 초대] (코드로 참가 영구 삭제)
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      key: const Key('create_room_cta_button'),
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
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        overlayColor: const Color(0xFFF7D779),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      key: const Key('received_room_invites_button'),
                      onPressed: () =>
                          _showPendingInvitationsSheet(context, ref),
                      icon: const Icon(Icons.mail_outline_rounded, size: 16),
                      label: Text(
                        pendingInvites.isEmpty
                            ? '받은 모임 초대'
                            : '받은 초대 (${pendingInvites.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.protoHeading,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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

              // 섹션 헤더
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

              // 모임 카드 목록
              if (rooms.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined,
                          size: 40, color: Color(0xFF94A3B8)),
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
                        '새 모임을 만들거나 친구의 모임 초대를 수락해 참여해보세요!',
                        style:
                            TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text(
                          '모임 개설하기',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
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
                          builder: (_) =>
                              ScheduleRoomDetailScreen(roomId: room.id),
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
