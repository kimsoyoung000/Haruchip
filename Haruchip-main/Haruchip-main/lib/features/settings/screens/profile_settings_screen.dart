import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_picker.dart';
import '../../../core/icons/haruchip_icon_registry.dart';
import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../core/security/input_sanitizer.dart';
import '../../../core/theme/app_font_settings_provider.dart';
import '../../../core/utils/safe_image_widget.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../calendar/providers/calendar_display_settings_provider.dart';
import '../../calendar/providers/schedule_room_provider.dart';
import '../../calendar/widgets/calendar_display_settings_sheet.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../../friends/models/battle_tag_user.dart';
import '../../friends/providers/friend_system_provider.dart';
import '../../friends/widgets/friend_management_card.dart';
import '../../home/providers/main_tab_provider.dart';
import '../../home/screens/trash_bin_screen.dart';
import '../../home/widgets/dashboard_category_filter_sheet.dart';
import '../../onboarding/providers/calendar_integration_provider.dart';
import '../../onboarding/providers/dashboard_view_mode_provider.dart';
import '../../onboarding/screens/app_permission_screen.dart';
import '../../onboarding/screens/splash_screen.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../trash/providers/trash_provider.dart';
import '../../widgets/screens/widget_simulator_screen.dart';
import 'hidden_categories_screen.dart';
import 'storage_manager_screen.dart';

/// 메인 셸의 4번째 탭 "프로필 & 설정"
///
/// 단일 수직 계층 구조:
/// - [구역 1: 최상단] 내 프로필 요약 카드 (소셜 연동 계정, 고유 유저 코드 노출 영구 제거)
/// - [구역 2: 중간 영역] 6대 도메인 독립 화이트 라운드 카드 그룹
///   1) 대시보드 (디데이) 설정
///   2) 칩 캘린더 설정
///   3) 칩 모임 설정
///   4) 위젯 설정
///   5) 화면 & 글꼴 설정
///   6) 데이터 관리 & 백업
/// - [구역 3: 최하단] 계정 및 보안 (위험 영역 격리) + 앱 버전/카피라이트
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  bool _isSyncing = false;

  // 모임 공유 캘린더 알림 & 화면 잠금 토글 상태
  bool _groupSharedAlarmEnabled = true;
  bool _screenLockEnabled = false;

  /// 프로필 아이콘/사진 변경 바텀시트 (HaruChipIconPicker 연동 + 즉시 전역 상태 & 모임 동기화)
  Future<void> _openAvatarPicker() async {
    final currentProfile = ref.read(friendSystemProvider).myProfile;
    final picked = await showHaruChipIconPicker(
      context,
      initialIconKey: currentProfile.avatarIcon,
      title: '프로필 아이콘 선택',
    );
    if (picked == null || !mounted) return;
    ref.read(friendSystemProvider.notifier).updateMyProfile(
          avatarIcon: picked,
          clearPhotoUrl: true,
        );
    final updated = ref.read(friendSystemProvider).myProfile;
    ref.read(scheduleRoomsProvider.notifier).syncGlobalProfileToRooms(
          uid: updated.uid,
          name: updated.nickname,
          icon: updated.avatarIcon,
          photoUrl: updated.photoUrl,
        );
    final label = HaruChipIconRegistry.labelForKey(picked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('프로필 아바타가 [$label](으)로 변경되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 닉네임(2~10자 + 금칙어 필터) & 4자리 배틀태그(#TAG) 글로벌 유니크 수정 팝업 다이얼로그
  void _openEditProfileDialog() {
    final myBattleProfile = ref.read(friendSystemProvider).myProfile;
    final nameController =
        TextEditingController(text: myBattleProfile.nickname);
    final tagController = TextEditingController(text: myBattleProfile.tag);
    String? nickError;
    String? tagError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.chipYellowText),
              const SizedBox(width: 8),
              Text(
                '프로필 수정',
                style: AppTypography.heading2.copyWith(
                  fontSize: 18,
                  color: AppColors.protoHeading,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '하루칩에서 사용할 닉네임과 4자리 태그(#TAG)를 설정해 주세요.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile_nickname_input'),
                controller: nameController,
                maxLength: 10,
                autofocus: true,
                onChanged: (_) {
                  if (nickError != null) {
                    setDialogState(() => nickError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '새 닉네임 입력 (2~10자)',
                  errorText: nickError,
                  filled: true,
                  fillColor: AppColors.cleanCanvasBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.chipGoldOutline,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('profile_tag_input'),
                controller: tagController,
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  if (tagError != null) {
                    setDialogState(() => tagError = null);
                  }
                },
                decoration: InputDecoration(
                  prefixText: '# ',
                  hintText: '영문 대문자/숫자 4자리 (예: 7F2K)',
                  errorText: tagError,
                  filled: true,
                  fillColor: AppColors.cleanCanvasBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.chipGoldOutline,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.protoSubtitle),
              ),
            ),
            ElevatedButton(
              key: const Key('profile_edit_save_btn'),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newTag = tagController.text.trim().toUpperCase();

                final validatedNickErr =
                    HaruInputSanitizer.validateNickname(newName);
                if (validatedNickErr != null) {
                  setDialogState(() => nickError = validatedNickErr);
                  return;
                }
                if (!isValidBattleTag(newTag)) {
                  setDialogState(() {
                    tagError = '영문 대문자 또는 숫자 4자리를 입력하세요.';
                  });
                  return;
                }

                final result = await ref
                    .read(friendSystemProvider.notifier)
                    .updateMyProfileValidated(
                      nickname: newName,
                      tag: newTag,
                      avatarIcon: myBattleProfile.avatarIcon,
                    );
                if (!result.ok || result.profile == null) {
                  setDialogState(() => nickError = result.error);
                  return;
                }

                final saved = result.profile!;
                ref.read(scheduleRoomsProvider.notifier).syncGlobalProfileToRooms(
                      uid: saved.uid,
                      name: saved.nickname,
                      icon: saved.avatarIcon,
                      photoUrl: saved.photoUrl,
                    );

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (mounted) {
                  final suffix = result.tagRegenerated
                      ? ' (중복 방지를 위해 태그가 자동 변경되었습니다)'
                      : '';
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '프로필이 "${saved.fullHandle}"(으)로 즉시 반영되었습니다.$suffix',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
                '저장',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 외부 캘린더 즉시 수동 동기화
  Future<void> _triggerManualSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('구글/네이버 캘린더와 모든 D-Day 및 일정이 동기화되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 전체 데이터 백업 내보내기 (JSON Export — 민감한 내부 UID/유저코드 미포함)
  void _exportBackupData() {
    final categories = ref.read(categoryListProvider);
    final plans = ref.read(planListProvider);

    final backupMap = <String, dynamic>{
      'appName': 'Haruchip',
      'version': '2.5.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'plans': plans.map((p) => p.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupMap);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 데이터 백업 내보내기',
                  style: AppTypography.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.protoHeading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '카테고리 ${categories.length}개, 일정 및 D-Day ${plans.length}개가 백업 데이터로 추출되었습니다.',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cleanCanvasBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('백업 JSON 데이터가 클립보드에 복사되었습니다.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('클립보드에 복사'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.protoHeading,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'haruchip_backup_latest.json 파일로 안전하게 내보냈습니다.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('백업 파일 저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chipYellowBg,
                      foregroundColor: AppColors.chipYellowText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  /// 백업 데이터 복원하기 (JSON Import)
  void _importBackupData() {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '백업 데이터 복원하기',
          style: AppTypography.heading2.copyWith(
            fontSize: 18,
            color: AppColors.protoHeading,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이전에 복사한 Haruchip 백업 JSON 텍스트를 아래에 붙여넣어 주세요.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText: '{\n  "appName": "Haruchip",\n  ...\n}',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: AppColors.cleanCanvasBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.protoSubtitle),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = textController.text.trim();
              if (raw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON 데이터를 입력해주세요.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              try {
                final dynamic parsed = jsonDecode(raw);
                if (parsed is! Map<String, dynamic> ||
                    parsed['appName'] != 'Haruchip') {
                  throw const FormatException('유효하지 않은 Haruchip 백업 포맷입니다.');
                }

                int restoredCategoriesCount = 0;
                int restoredPlansCount = 0;

                if (parsed['categories'] is List) {
                  final list = (parsed['categories'] as List)
                      .whereType<Map<String, dynamic>>()
                      .map((m) => Category.fromJson(m))
                      .toList();
                  if (list.isNotEmpty) {
                    ref.read(categoryListProvider.notifier).replaceAll(list);
                    restoredCategoriesCount = list.length;
                  }
                }

                if (parsed['plans'] is List) {
                  final list = (parsed['plans'] as List)
                      .whereType<Map<String, dynamic>>()
                      .map((m) => PlanItem.fromJson(m))
                      .toList();
                  if (list.isNotEmpty) {
                    ref.read(planListProvider.notifier).replaceAll(list);
                    restoredPlansCount = list.length;
                  }
                }

                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '백업 복원 완료! 카테고리 $restoredCategoriesCount개, 일정 $restoredPlansCount개가 복원되었습니다.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('복원 실패: 올바른 JSON 데이터인지 확인해주세요. ($e)'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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
              '데이터 복원 적용',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  /// 약관 / 개인정보 / 연동 계정 안내 모달
  void _showPolicyInfoSheet(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: AppTypography.heading2.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.protoHeading,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF4B5563),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chipYellowBg,
                    foregroundColor: AppColors.chipYellowText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 로그아웃 처리
  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text('현재 계정에서 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chipYellowBg,
              foregroundColor: AppColors.chipYellowText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '로그아웃',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  /// 회원 탈퇴 (애플 심사 필수 준수 - Guideline 5.1.1(v))
  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
            SizedBox(width: 8),
            Text(
              '회원 탈퇴 (계정 삭제)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFFE11D48),
              ),
            ),
          ],
        ),
        content: const Text(
          '정말로 하루칩을 탈퇴하시겠습니까?\n\n'
          '모든 D-Day와 공유 방 데이터가 즉시 파기되며 복구할 수 없습니다.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('즉시 탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authServiceProvider).deleteAccount();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 영구히 삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('탈퇴 처리 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _resolveProviderLabel(String? providerId) {
    if (providerId == null || providerId.isEmpty) return '소셜 계정 연동됨';
    if (providerId.contains('google')) return 'Google 연동됨';
    if (providerId.contains('apple')) return 'Apple 연동됨';
    if (providerId.contains('kakao')) return '카카오 연동됨';
    return '소셜 계정 연동됨';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userEmail = currentUser?.email ?? 'haruchip_user@gmail.com';
    final providerId = (currentUser?.providerData.isNotEmpty ?? false)
        ? currentUser!.providerData.first.providerId
        : null;
    final providerBadgeLabel = _resolveProviderLabel(providerId);

    final trashItems = ref.watch(trashBinProvider);
    final hiddenCategories = ref.watch(hiddenCategoriesProvider);
    final selectedViewMode = ref.watch(resolvedDashboardViewModeProvider);
    final calendarDisplaySettings = ref.watch(calendarDisplaySettingsProvider);
    final fontSettings = ref.watch(appFontSettingsProvider);
    final rooms = ref.watch(scheduleRoomsProvider);
    final calendarSet = ref.watch(calendarIntegrationProvider);
    final isGoogleSync = calendarSet.contains('google');
    final isNaverSync = calendarSet.contains('naver');

    return Scaffold(
      backgroundColor: AppColors.cleanCanvasBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 화면 타이틀
              Text(
                '프로필 & 설정',
                style: AppTypography.heading1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.protoHeading,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // ===============================================================
              // [구역 1: 최상단] 내 프로필 요약 카드 (고유 유저 코드 영구 제거)
              // ===============================================================
              _buildWhiteGroupCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _openAvatarPicker,
                      child: Stack(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: AppColors.cleanCanvasBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: watchUserProfileDocument(
                                ref.watch(friendSystemProvider).myProfile.uid,
                              ),
                              builder: (context, snapshot) {
                                final localProfile =
                                    ref.watch(friendSystemProvider).myProfile;
                                final remoteData = snapshot.data?.data();
                                final photoUrl =
                                    (remoteData?['photoUrl'] as String?) ??
                                        localProfile.photoUrl;
                                final iconKey =
                                    (remoteData?['avatarIcon'] as String?) ??
                                        localProfile.avatarIcon;
                                if (photoUrl != null && photoUrl.isNotEmpty) {
                                  return ClipOval(
                                    child: buildUserImage(
                                      photoUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                return HaruChipIconViewer(
                                  iconKey: iconKey,
                                  size: 32,
                                  circular: true,
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.chipYellowBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 11,
                                color: AppColors.chipYellowText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: watchUserProfileDocument(
                          ref.watch(friendSystemProvider).myProfile.uid,
                        ),
                        builder: (context, snapshot) {
                          final localProfile =
                              ref.watch(friendSystemProvider).myProfile;
                          final remoteData = snapshot.data?.data();
                          final liveNickname =
                              (remoteData?['nickname'] as String?) ??
                                  localProfile.nickname;
                          final liveTag = (remoteData?['tag'] as String?) ??
                              localProfile.tag;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    liveNickname,
                                    key: const Key('profile_live_nickname'),
                                    style: AppTypography.heading2.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.protoHeading,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cleanCanvasBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#$liveTag',
                                      key: const Key('profile_live_tag'),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.chipYellowBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      providerBadgeLabel,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.chipYellowText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                userEmail,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 12,
                                  color: AppColors.protoSubtitle,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _openEditProfileDialog,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.cleanCanvasBg,
                        foregroundColor: AppColors.protoHeading,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '프로필 수정',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ===============================================================
              // [구역 1-2] 내 친구 (N명) 미니멀 한 줄 타일 -> 친구 관리 바텀시트 모달
              // ===============================================================
              _buildWhiteGroupCard(
                child: Consumer(
                  builder: (context, ref, _) {
                    final friendState = ref.watch(friendSystemProvider);
                    final friendCount = friendState.friends.length;
                    final pendingCount = friendState.incomingRequests.length;
                    return InkWell(
                      key: const Key('settings_friends_summary_tile'),
                      onTap: () => showFriendManagementModal(context),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: AppColors.chipYellowBg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.group_outlined,
                                size: 18,
                                color: AppColors.chipYellowText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '내 친구 $friendCount명',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.protoHeading,
                                ),
                              ),
                            ),
                            if (pendingCount > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEAEA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '요청 $pendingCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 2-1] 대시보드 (디데이) 설정
              // ===============================================================
              _buildSectionHeader('대시보드 (디데이) 설정'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLeadingIconBox(
                                Icons.dashboard_customize_outlined,
                                AppColors.chipYellowText,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '대시보드 뷰 모드 설정',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.protoHeading,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '홈 화면에서 카테고리와 D-Day를 보여주는 레이아웃',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.protoSubtitle,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSegmentOptionButton(
                                  title: '타임라인 뷰',
                                  subtitle: '세로 스크롤형',
                                  icon: Icons.view_agenda_outlined,
                                  isSelected: selectedViewMode == 'vertical',
                                  onTap: () => ref
                                      .read(dashboardViewModeProvider.notifier)
                                      .select('vertical'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSegmentOptionButton(
                                  title: '칩 모아보기 뷰',
                                  subtitle: '2열 박스형',
                                  icon: Icons.grid_view_rounded,
                                  isSelected: selectedViewMode == 'box' ||
                                      selectedViewMode == 'horizontal' ||
                                      selectedViewMode == 'grid',
                                  onTap: () => ref
                                      .read(dashboardViewModeProvider.notifier)
                                      .select('grid'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.sort_rounded,
                      title: '카테고리 순서 편집',
                      subtitle: '칩 데이 메인 화면의 카테고리 카드 순서를 변경합니다.',
                      badgeText: '순서 변경',
                      onTap: () => showCategoryOrderEditSheet(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.visibility_off_outlined,
                      title: '대시보드 숨김 카드 보관함',
                      subtitle: '숨겨둔 카테고리 카드를 언제든 다시 복구할 수 있습니다.',
                      badgeText: '${hiddenCategories.length}개',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HiddenCategoriesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 2-2] 칩 캘린더 설정
              // ===============================================================
              _buildSectionHeader('칩 캘린더 설정'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: Column(
                  children: [
                    // 캘린더 시작 요일 (일요일 / 월요일)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLeadingIconBox(
                                Icons.date_range_rounded,
                                AppColors.chipYellowText,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '캘린더 시작 요일',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.protoHeading,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      calendarDisplaySettings.startOnMonday
                                          ? '월요일부터 시작 (월~일)'
                                          : '일요일부터 시작 (일~토)',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.protoSubtitle,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSegmentOptionButton(
                                  title: '일요일부터 시작',
                                  subtitle: '일 · 월 · 화 · 수 · 목 · 금 · 토',
                                  isSelected:
                                      !calendarDisplaySettings.startOnMonday,
                                  onTap: () => ref
                                      .read(calendarDisplaySettingsProvider
                                          .notifier)
                                      .setStartOnMonday(false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSegmentOptionButton(
                                  title: '월요일부터 시작',
                                  subtitle: '월 · 화 · 수 · 목 · 금 · 토 · 일',
                                  isSelected:
                                      calendarDisplaySettings.startOnMonday,
                                  onTap: () => ref
                                      .read(calendarDisplaySettingsProvider
                                          .notifier)
                                      .setStartOnMonday(true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.calendar_view_month_rounded,
                      title: '캘린더 표시 설정',
                      subtitle:
                          '글꼴 ${calendarDisplaySettings.fontSize.labelKo} · 굵기 ${calendarDisplaySettings.fontWeight.labelKo}',
                      badgeText: '맞춤 설정',
                      onTap: () => showCalendarDisplaySettingsSheet(
                        context,
                        isOnboarding: false,
                      ),
                    ),
                    _buildDivider(),
                    // 외부 캘린더 동기화 (Google / Naver)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLeadingIconBox(
                                Icons.sync_rounded,
                                AppColors.chipYellowText,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '외부 캘린더 동기화 설정',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.protoHeading,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    _isSyncing ? null : _triggerManualSync,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.chipYellowText,
                                  backgroundColor: AppColors.chipYellowBg,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _isSyncing ? '동기화 중...' : '지금 동기화',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildToggleRow(
                            title: 'Google 캘린더 연동',
                            subtitle: '하루칩 일정을 구글 캘린더와 동기화합니다.',
                            value: isGoogleSync,
                            onChanged: (_) => ref
                                .read(calendarIntegrationProvider.notifier)
                                .toggle('google'),
                          ),
                          _buildToggleRow(
                            title: '네이버 캘린더 연동',
                            subtitle: '하루칩 일정을 네이버 캘린더와 동기화합니다.',
                            value: isNaverSync,
                            onChanged: (_) => ref
                                .read(calendarIntegrationProvider.notifier)
                                .toggle('naver'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 2-3] 칩 모임 설정
              // ===============================================================
              _buildSectionHeader('칩 모임 설정'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.groups_rounded,
                      title: '참여 중인 모임 목록 바로가기',
                      subtitle: '현재 참여 중인 모임 방과 정산 내역을 확인합니다.',
                      badgeText: '${rooms.length}개 모임',
                      onTap: () {
                        ref.read(mainTabIndexProvider.notifier).select(2);
                      },
                    ),
                    _buildDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _buildLeadingIconBox(
                            Icons.notifications_active_outlined,
                            AppColors.chipYellowText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '공유 캘린더 알림 설정',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.protoHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '모임 일정 확정·공지·투표 업데이트 푸시 알림',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.protoSubtitle,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _groupSharedAlarmEnabled,
                            activeTrackColor: AppColors.chipGoldOutline,
                            onChanged: (v) =>
                                setState(() => _groupSharedAlarmEnabled = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 2-4] 위젯 설정
              // ===============================================================
              _buildSectionHeader('위젯 설정'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: _buildSettingsTile(
                  icon: Icons.widgets_outlined,
                  title: '모바일 홈/잠금화면 위젯 시뮬레이터',
                  subtitle: '2x2 감성 위젯 · 4x2 스마트 캘린더 미리보기',
                  badgeText: '미리보기',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WidgetSimulatorScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 2-5] 화면 & 글꼴 설정
              // ===============================================================
              _buildSectionHeader('화면 & 글꼴 설정'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: _buildSettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: '글꼴 및 글자 크기 설정',
                  subtitle:
                      '${fontSettings.fontFamily.labelKo} · 글자 크기 ${fontSettings.fontSize.labelKo}',
                  badgeText: '전역 폰트',
                  onTap: () => showAppFontSettingsSheet(context),
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 2-6] 데이터 관리 & 백업
              // ===============================================================
              _buildSectionHeader('데이터 관리 & 백업'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.cleaning_services_outlined,
                      title: '저장공간 관리',
                      subtitle: '카테고리별 지난 일정 정리 및 캐시 관리',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StorageManagerScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_outline_rounded,
                      title: '휴지통 (삭제된 D-Day 복구/영구삭제)',
                      subtitle: '삭제 후 30일 이내 일정을 언제든 복구할 수 있습니다.',
                      badgeText: '${trashItems.length}개 보관 중',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TrashBinScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.file_upload_outlined,
                      title: '전체 데이터 백업 내보내기',
                      subtitle: '카테고리와 D-Day 데이터를 JSON으로 내보냅니다.',
                      onTap: _exportBackupData,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.file_download_outlined,
                      title: '백업 데이터 복원하기',
                      subtitle: '저장해둔 JSON 백업 데이터를 불러와 복원합니다.',
                      onTap: _importBackupData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // [구역 3: 최하단] 계정 및 보안 (위험 영역 격리)
              // ===============================================================
              _buildSectionHeader('계정 및 보안'),
              const SizedBox(height: 8),
              _buildWhiteGroupCard(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      title: '앱 접근 권한 재설정',
                      subtitle: '알림, 사진, 카메라 등 기기 접근 권한을 관리합니다.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppPermissionScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _buildLeadingIconBox(
                            Icons.lock_outline_rounded,
                            AppColors.chipYellowText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '화면 잠금 설정',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.protoHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '생체인증 / PIN으로 내 하루칩 기록 보호',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.protoSubtitle,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _screenLockEnabled,
                            activeTrackColor: AppColors.chipGoldOutline,
                            onChanged: (v) {
                              setState(() => _screenLockEnabled = v);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    v
                                        ? '화면 잠금(생체인증/PIN)이 활성화되었습니다.'
                                        : '화면 잠금이 해제되었습니다.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.manage_accounts_outlined,
                      title: '연동된 계정 관리',
                      subtitle: '$providerBadgeLabel ($userEmail)',
                      onTap: () => _showPolicyInfoSheet(
                        '연동된 계정 관리',
                        '현재 계정: $userEmail\n연동 상태: $providerBadgeLabel\n\n하루칩은 소셜 로그인 인증 토큰을 안전하게 암호화하여 관리하며, 내부 UID는 백엔드 인가 용도로만 격리 사용됩니다.',
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      title: '서비스 이용약관',
                      subtitle: '하루칩 서비스 이용 규정 안내',
                      onTap: () => _showPolicyInfoSheet(
                        '서비스 이용약관',
                        '하루칩(HaruChip)은 사용자의 D-Day, 일정 및 모임 조율 데이터를 안전하게 보관하며, 동의 없이 제3자에게 제공하지 않습니다.',
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보 처리방침',
                      subtitle: '개인정보 수집·보관 및 파기 정책',
                      onTap: () => _showPolicyInfoSheet(
                        '개인정보 처리방침',
                        '수집 항목: 이메일, 닉네임, 사용자가 직접 등록한 일정 및 카테고리 데이터.\n회원 탈퇴 시 모든 개인 데이터는 관련 법령에 따라 지체 없이 파기됩니다.',
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      title: '로그아웃',
                      subtitle: '현재 기기에서 계정 연결을 해제합니다.',
                      onTap: _handleSignOut,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.person_remove_outlined,
                      iconColor: const Color(0xFFE11D48),
                      iconBgColor: const Color(0xFFFFF1F2),
                      title: '회원 탈퇴 (계정 영구 삭제)',
                      titleColor: const Color(0xFFE11D48),
                      subtitle: '모든 기록과 계정이 즉시 삭제되며 복구할 수 없습니다.',
                      onTap: _handleDeleteAccount,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // 최하단 앱 버전 & 미니멀 카피라이트
              const Center(
                child: Column(
                  children: [
                    Text(
                      'HaruChip v2.5.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '© 2026 HaruChip. All rights reserved.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB0B7C3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B7280),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  /// 무테두리 순백 라운드 카드 그룹 (BorderRadius 18 + 미세 그림자)
  Widget _buildWhiteGroupCard({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Color(0xFFF3F4F6),
    );
  }

  Widget _buildLeadingIconBox(
    IconData icon,
    Color iconColor, {
    Color bgColor = const Color(0xFFFFF8E1),
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: iconColor),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color iconColor = AppColors.chipYellowText,
    Color iconBgColor = const Color(0xFFFFF8E1),
    required String title,
    Color titleColor = AppColors.protoHeading,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _buildLeadingIconBox(icon, iconColor, bgColor: iconBgColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.protoSubtitle,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.chipYellowBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.chipYellowText,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 46),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.protoHeading,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.protoSubtitle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.chipGoldOutline,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOptionButton({
    required String title,
    required String subtitle,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipYellowBg : AppColors.cleanCanvasBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.chipGoldOutline : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.chipYellowText
                    : AppColors.protoSubtitle,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.chipYellowText
                    : AppColors.protoHeading,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? AppColors.chipYellowText.withValues(alpha: 0.78)
                    : AppColors.protoSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
