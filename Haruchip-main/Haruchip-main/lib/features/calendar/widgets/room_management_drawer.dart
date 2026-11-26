import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/icons/haruchip_icon_picker.dart';
import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../core/security/input_sanitizer.dart';
import '../../../core/utils/safe_image_widget.dart';
import '../../../design_system/colors.dart';
import '../../friends/models/battle_tag_user.dart';
import '../../friends/providers/friend_system_provider.dart';
import '../models/schedule_room.dart';
import '../providers/schedule_room_provider.dart';

Color _parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length == 6) {
    final v = int.tryParse('FF$cleaned', radix: 16);
    if (v != null) return Color(v);
  }
  return const Color(0xFFDFE7FD);
}

/// 카카오톡 단톡방 서랍 스타일의 모임 관리 우측 사이드 시트(EndDrawer)
class RoomManagementDrawer extends ConsumerWidget {
  const RoomManagementDrawer({
    super.key,
    required this.room,
    required this.myMember,
    required this.onSelectTab,
    required this.onRoomExited,
  });

  final ScheduleRoom room;
  final RoomMember myMember;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onRoomExited;

  Future<void> _showInviteFriendsSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final existingUids = room.members.map((m) => m.uid).toSet();
    final friends = ref
        .read(friendSystemProvider)
        .friends
        .where((f) => !existingUids.contains(f.uid))
        .toList();
    final selectedUids = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
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
                const SizedBox(height: 12),
                const Text(
                  '모임에 친구 초대하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.protoHeading,
                  ),
                ),
                const SizedBox(height: 10),
                if (friends.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cleanCanvasBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      '초대할 수 있는 친구가 없습니다.\n[설정 > 내 친구]에서 닉네임#태그로 친구를 먼저 추가해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  )
                else ...[
                  for (final f in friends)
                    CheckboxListTile(
                      value: selectedUids.contains(f.uid),
                      activeColor: AppColors.chipYellowText,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      secondary: HaruChipIconViewer(
                        iconKey: f.avatarIcon,
                        size: 26,
                        circular: true,
                      ),
                      title: Text(
                        f.fullHandle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onChanged: (checked) {
                        setSheetState(() {
                          if (checked == true) {
                            selectedUids.add(f.uid);
                          } else {
                            selectedUids.remove(f.uid);
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: selectedUids.isEmpty
                        ? null
                        : () {
                            final picked = friends
                                .where((f) => selectedUids.contains(f.uid))
                                .toList();
                            ref
                                .read(scheduleRoomsProvider.notifier)
                                .inviteFriendsToRoom(room.id, picked);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '친구 ${picked.length}명을 모임에 초대했습니다.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chipYellowBg,
                      foregroundColor: AppColors.chipYellowText,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '선택한 친구 초대 (${selectedUids.length}명)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLeaveRoom(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(scheduleRoomsProvider.notifier);
    final left = notifier.leaveRoom(room.id, myMember.uid);
    if (left) {
      Navigator.pop(context); // close drawer
      onRoomExited();
      return;
    }

    // 방장 + 다른 멤버 존재 -> 방장 권한 위임 팝업 안내
    final candidates =
        room.members.where((m) => m.uid != myMember.uid).toList();
    String? selectedUid = candidates.isNotEmpty ? candidates.first.uid : null;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '방장 권한 위임 필요',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '방장은 다른 멤버에게 방장 권한을 위임한 뒤 모임을 나갈 수 있습니다.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 12),
              for (final c in candidates)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selectedUid == c.uid
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: selectedUid == c.uid
                        ? AppColors.chipYellowText
                        : const Color(0xFF9CA3AF),
                  ),
                  title: Text(
                    '${c.name}${c.isCoHost ? ' (부방장)' : ''}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => setDialogState(() => selectedUid = c.uid),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedUid == null
                  ? null
                  : () {
                      notifier.delegateHost(room.id, selectedUid!);
                      notifier.leaveRoom(room.id, myMember.uid);
                      Navigator.pop(dialogCtx);
                      Navigator.pop(context); // close drawer
                      onRoomExited();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chipYellowBg,
                foregroundColor: AppColors.chipYellowText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '위임 후 나가기',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteRoom(BuildContext context, WidgetRef ref) async {
    // 1차 경고 컨펌 모달
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '모임 삭제 경고',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE11D48),
          ),
        ),
        content: const Text(
          '모든 일정, 공지, 정산 내역이 영구히 삭제됩니다.\n정말 이 모임을 삭제하시겠습니까?',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('다음 (2차 확인)'),
          ),
        ],
      ),
    );
    if (firstConfirm != true || !context.mounted) return;

    // 2차 최종 삭제 확인
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '최종 삭제 확인',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE11D48),
          ),
        ),
        content: Text(
          '[${room.name}] 모임과 모든 데이터를 즉시 영구 삭제합니다. 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '영구 삭제',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (secondConfirm == true && context.mounted) {
      ref.read(scheduleRoomsProvider.notifier).deleteRoom(room.id);
      Navigator.pop(context); // close drawer
      onRoomExited();
    }
  }

  /// 모임 서랍 내 [나] 탭 -> [모임 프로필 & 칩 컬러 설정 모달]
  /// - 기본 하루칩 프로필 vs 이 모임 전용 프로필(닉네임 + 아바타/웹 안전 사진) 토글
  /// - 1인 1색 칩 컬러 중복 선점 방어 (다른 멤버가 사용 중인 컬러는 잠금 + 안내 토스트)
  Future<void> _showMyRoomProfileAndColorModal(
    BuildContext context,
    WidgetRef ref,
    ScheduleRoom liveRoom,
    RoomMember liveMe,
  ) async {
    final globalProfile = ref.read(friendSystemProvider).myProfile;
    bool usesCustom = liveMe.usesCustomProfile;
    final nickCtrl = TextEditingController(
      text: liveMe.usesCustomProfile ? liveMe.name : globalProfile.nickname,
    );
    String selectedIcon =
        liveMe.usesCustomProfile ? liveMe.icon : globalProfile.avatarIcon;
    String? customPhoto = liveMe.usesCustomProfile
        ? liveMe.customPhotoUrl
        : globalProfile.photoUrl;
    String selectedColor = liveMe.colorHex.toUpperCase();
    String? nickError;

    final otherTakenColors = liveRoom.members
        .where((m) => m.uid != liveMe.uid)
        .map((m) => m.colorHex.toUpperCase())
        .toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalCtx).size.height * 0.86,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                        const Text(
                          '내 모임 프로필 & 칩 컬러',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 30, minHeight: 30),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1) 기본 프로필 vs 이 모임 전용 프로필 토글
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cleanCanvasBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '이 모임 전용 프로필 사용',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.protoHeading,
                                  ),
                                ),
                                Text(
                                  '끄면 하루칩 기본 프로필이 자동 반영됩니다.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8C7E6A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            key: const Key('room_custom_profile_switch'),
                            value: usesCustom,
                            activeTrackColor: AppColors.chipYellowBg,
                            activeThumbColor: AppColors.chipYellowText,
                            onChanged: (v) {
                              setSheetState(() {
                                usesCustom = v;
                                nickError = null;
                                if (!v) {
                                  nickCtrl.text = globalProfile.nickname;
                                  selectedIcon = globalProfile.avatarIcon;
                                  customPhoto = globalProfile.photoUrl;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2) 전용 프로필 편집 (아바타/사진 + 닉네임)
                    if (usesCustom) ...[
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _parseHexColor(selectedColor)
                                  .withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: (customPhoto != null &&
                                    customPhoto!.isNotEmpty)
                                ? ClipOval(
                                    child: buildUserImage(
                                      customPhoto!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : HaruChipIconViewer(
                                    iconKey: selectedIcon,
                                    size: 28,
                                    circular: true,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showHaruChipIconPicker(
                                modalCtx,
                                initialIconKey: selectedIcon,
                                title: '모임 아이콘 선택',
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  selectedIcon = picked;
                                  customPhoto = null;
                                });
                              }
                            },
                            icon: const Icon(Icons.emoji_emotions_outlined,
                                size: 15),
                            label: const Text(
                              '아이콘',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.protoHeading,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                imageQuality: 80,
                              );
                              if (file == null) return;
                              final src = await xFileToSafeImageSource(file);
                              if (src.isNotEmpty) {
                                setSheetState(() => customPhoto = src);
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 15),
                            label: const Text(
                              '사진',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.protoHeading,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('room_custom_nickname_input'),
                        controller: nickCtrl,
                        maxLength: 10,
                        onChanged: (_) {
                          if (nickError != null) {
                            setSheetState(() => nickError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '모임 전용 닉네임 (2~10자)',
                          errorText: nickError,
                          filled: true,
                          fillColor: AppColors.cleanCanvasBg,
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
                      ),
                      const SizedBox(height: 6),
                    ],

                    // 3) 1인 1색 칩 컬러 팔레트 (중복 선점 방어)
                    const Text(
                      '내 칩 컬러 선택 (1인 1색)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '자물쇠가 표시된 컬러는 다른 멤버가 사용 중입니다.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final hex in kPreset50PastelColors.take(24))
                          () {
                            final upper = hex.toUpperCase();
                            final isTaken = otherTakenColors.contains(upper);
                            final isSelected = selectedColor == upper;
                            return GestureDetector(
                              key: isTaken
                                  ? Key('chip_color_locked_$upper')
                                  : Key('chip_color_avail_$upper'),
                              onTap: () {
                                if (isTaken) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '이미 다른 멤버가 사용 중인 컬러입니다',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  return;
                                }
                                setSheetState(() => selectedColor = upper);
                              },
                              child: Opacity(
                                opacity: isTaken ? 0.42 : 1.0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _parseHexColor(upper),
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.chipYellowText,
                                            width: 2.4,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: isTaken
                                      ? const Icon(
                                          Icons.lock_rounded,
                                          size: 14,
                                          color: Color(0xFF4B5563),
                                        )
                                      : (isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: AppColors.chipYellowText,
                                            )
                                          : null),
                                ),
                              ),
                            );
                          }(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        key: const Key('room_member_profile_save_btn'),
                        onPressed: () {
                          if (usesCustom) {
                            final err =
                                HaruInputSanitizer.validateNickname(nickCtrl.text);
                            if (err != null) {
                              setSheetState(() => nickError = err);
                              return;
                            }
                          }
                          final ok = ref
                              .read(scheduleRoomsProvider.notifier)
                              .updateMemberCustomization(
                                roomId: liveRoom.id,
                                uid: liveMe.uid,
                                name: usesCustom
                                    ? HaruInputSanitizer.sanitizeText(
                                        nickCtrl.text,
                                      )
                                    : globalProfile.nickname,
                                icon: usesCustom
                                    ? selectedIcon
                                    : globalProfile.avatarIcon,
                                colorHex: selectedColor,
                                usesCustomProfile: usesCustom,
                                customPhotoUrl: usesCustom
                                    ? customPhoto
                                    : globalProfile.photoUrl,
                                clearCustomPhotoUrl: usesCustom
                                    ? (customPhoto?.isEmpty ?? true)
                                    : (globalProfile.photoUrl?.isEmpty ?? true),
                              );
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('이미 다른 멤버가 사용 중인 컬러입니다'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.chipYellowBg,
                          foregroundColor: AppColors.chipYellowText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '저장하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    nickCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendState = ref.watch(friendSystemProvider);
    final rooms = ref.watch(scheduleRoomsProvider);
    final liveRoom =
        rooms.where((r) => r.id == room.id).firstOrNull ?? room;
    final liveMe = liveRoom.members
            .where((m) => m.uid == myMember.uid)
            .firstOrNull ??
        myMember;

    return Drawer(
      key: const Key('room_management_drawer'),
      backgroundColor: Colors.white,
      width: MediaQuery.sizeOf(context).width.clamp(280.0, 320.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveRoom.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          liveRoom.categoryTag,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // (1) 상단 바로가기 4대 버튼: [공지] [투표] [일정 조율] [정산 장부]
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  _buildShortcutButton(
                    context,
                    icon: Icons.campaign_outlined,
                    label: '공지',
                    tabIndex: 2,
                  ),
                  const SizedBox(width: 6),
                  _buildShortcutButton(
                    context,
                    icon: Icons.how_to_vote_outlined,
                    label: '투표',
                    tabIndex: 2,
                  ),
                  const SizedBox(width: 6),
                  _buildShortcutButton(
                    context,
                    icon: Icons.event_available_outlined,
                    label: '일정 조율',
                    tabIndex: 1,
                  ),
                  const SizedBox(width: 6),
                  _buildShortcutButton(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: '정산 장부',
                    tabIndex: 3,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // (2) 참여 멤버 리스트
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '대화상대 ${liveRoom.members.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  TextButton(
                    key: const Key('drawer_invite_friends_btn'),
                    onPressed: () => _showInviteFriendsSheet(context, ref),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.chipYellowBg,
                      foregroundColor: AppColors.chipYellowText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '+ 초대하기',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liveRoom.members.length,
                itemBuilder: (context, index) {
                  final m = liveRoom.members[index];
                  final isSelf = m.uid == liveMe.uid;
                  final displayName = isSelf
                      ? m.name
                      : friendState.displayMemberName(m.uid, m.name);
                  final isFriend = friendState.isFriend(m.uid);
                  final hasSent = friendState.hasSentRequest(m.uid);
                  final isBlocked = friendState.isBlocked(m.uid);

                  return ListTile(
                    key: isSelf
                        ? const Key('drawer_self_profile_tile')
                        : Key('drawer_member_tile_${m.uid}'),
                    dense: true,
                    onTap: isSelf
                        ? () => _showMyRoomProfileAndColorModal(
                              context,
                              ref,
                              liveRoom,
                              liveMe,
                            )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: _parseHexColor(m.colorHex)
                              .withValues(alpha: 0.45),
                          child: (m.customPhotoUrl != null &&
                                  m.customPhotoUrl!.isNotEmpty)
                              ? ClipOval(
                                  child: buildUserImage(
                                    m.customPhotoUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : HaruChipIconViewer(
                                  iconKey: m.icon,
                                  size: 22,
                                  circular: true,
                                ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _parseHexColor(m.colorHex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.protoHeading,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 4),
                          _buildRoleBadge(
                            '나',
                            AppColors.cleanCanvasBg,
                            const Color(0xFF6B7280),
                          ),
                        ],
                        if (m.isHost) ...[
                          const SizedBox(width: 4),
                          _buildRoleBadge('방장', AppColors.chipYellowBg,
                              AppColors.chipYellowText),
                        ] else if (m.isCoHost) ...[
                          const SizedBox(width: 4),
                          _buildRoleBadge('부방장', const Color(0xFFE8F5E9),
                              const Color(0xFF2E6B3E)),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelf)
                          const Icon(
                            Icons.palette_outlined,
                            size: 16,
                            color: Color(0xFF9CA3AF),
                          )
                        else if (!isFriend && !isBlocked) ...[
                          if (hasSent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cleanCanvasBg,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                '요청됨',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              key: Key('drawer_add_friend_${m.uid}'),
                              onTap: () {
                                final targetUser = BattleTagUser(
                                  uid: m.uid,
                                  nickname: m.name,
                                  tag: generateBattleTag(),
                                  avatarIcon: m.icon,
                                );
                                ref
                                    .read(friendSystemProvider.notifier)
                                    .sendFriendRequest(targetUser);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${m.name}님에게 친구 요청을 보냈습니다.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.chipYellowBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '+ 친구',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.chipYellowText,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        if (liveMe.isHost && !isSelf)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            color: Colors.white,
                            onSelected: (action) {
                              final notifier =
                                  ref.read(scheduleRoomsProvider.notifier);
                              if (action == 'cohost') {
                                notifier.toggleCoHost(liveRoom.id, m.uid);
                              } else if (action == 'delegate') {
                                notifier.delegateHost(liveRoom.id, m.uid);
                              } else if (action == 'kick') {
                                notifier.kickMember(liveRoom.id, m.uid);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem<String>(
                                value: 'cohost',
                                child: Text(
                                  m.isCoHost ? '부방장 해제' : '부방장 지정',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delegate',
                                child: Text(
                                  '방장 위임',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'kick',
                                child: Text(
                                  '내보내기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // (3) 하단 위험 영역: [모임 나가기] & [모임 삭제 (방장/부방장 전용)]
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      key: const Key('drawer_leave_room_btn'),
                      onPressed: () => _handleLeaveRoom(context, ref),
                      icon: const Icon(
                        Icons.exit_to_app_rounded,
                        size: 17,
                        color: Color(0xFF6B7280),
                      ),
                      label: const Text(
                        '모임 나가기',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  if (liveMe.canManageRoom) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        key: const Key('drawer_delete_room_btn'),
                        onPressed: () => _handleDeleteRoom(context, ref),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: Color(0xFFE11D48),
                        ),
                        label: const Text(
                          '모임 삭제',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE11D48),
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
      ),
    );
  }

  Widget _buildShortcutButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int tabIndex,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSelectTab(tabIndex);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cleanCanvasBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.chipYellowText),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.protoHeading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
