import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/native_permission_service.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/layout_tokens.dart';
import '../../../design_system/typography.dart';
import '../../calendar/services/calendar_oauth_sync_service.dart';
import '../data/calendar_integration_options.dart';
import '../providers/app_permissions_provider.dart';
import '../providers/calendar_integration_provider.dart';
import '../widgets/calendar_integration_card.dart';

/// "캘린더 연동 설정" 화면 (기기 로컬 캘린더 권한 vs 구글/네이버 OAuth 2.0 아키텍처 분리)
///
/// 1) [기기 로컬 캘린더 동기화]: OS 캘린더 권한(`Permission.calendarFullAccess`)만으로
///    iCloud / Android 기본 캘린더 앱에 하루칩 일정을 직접 기록한다.
/// 2) [클라우드 계정 연동 (OAuth 2.0)]: 단순 기기 권한만으로는 구글/네이버 클라우드와
///    연동되지 않으므로, 토글 ON 시 각 서비스의 OAuth 2.0 로그인 브라우저를 띄워
///    Access Token을 획득한 뒤 REST API를 호출하는 구조로 명확히 분리한다.
class CalendarIntegrationScreen extends ConsumerWidget {
  const CalendarIntegrationScreen({super.key});

  Future<void> _handleDeviceLocalCalendarToggle(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final permNotifier = ref.read(appPermissionsProvider.notifier);
    final calNotifier = ref.read(calendarIntegrationProvider.notifier);
    final selected = ref.read(calendarIntegrationProvider);

    if (selected.contains('device_local')) {
      calNotifier.toggle('device_local');
      return;
    }

    final syncService = ref.read(calendarOAuthSyncServiceProvider);
    final outcome = await syncService.requestDeviceLocalCalendarSync();
    if (!context.mounted) return;

    if (outcome.isUsable) {
      permNotifier.setPermission('calendar', true);
      calNotifier.toggle('device_local');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('기기 기본 캘린더(iCloud/Android) 로컬 동기화가 활성화되었습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else if (outcome == NativePermissionOutcome.permanentlyDenied) {
      await showPermanentlyDeniedSettingsDialog(
        context,
        permissionTitle: '캘린더',
        onOpenSettings: permNotifier.openDeviceAppSettings,
      );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('기기 캘린더 접근 권한이 허용되어야 로컬 동기화를 사용할 수 있습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _handleCloudOAuthToggle(
    BuildContext context,
    WidgetRef ref,
    String providerKey,
  ) async {
    final calNotifier = ref.read(calendarIntegrationProvider.notifier);
    final selected = ref.read(calendarIntegrationProvider);

    // 이미 연동된 상태에서 OFF 전환 시 즉시 해제
    if (selected.contains(providerKey)) {
      calNotifier.toggle(providerKey);
      return;
    }

    // ON 전환 시 OAuth 2.0 로그인 브라우저 실행 (Access Token 획득 플로우)
    final syncService = ref.read(calendarOAuthSyncServiceProvider);
    final result = await syncService.startCloudOAuthFlow(providerKey);
    if (!context.mounted) return;

    if (result.launched) {
      calNotifier.toggle(providerKey);
    }
    if (result.message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.message!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKeys = ref.watch(calendarIntegrationProvider);
    final isDeviceLocalOn = selectedKeys.contains('device_local');

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.protoBackground,
        elevation: 0,
        foregroundColor: AppColors.protoHeading,
        title: Text(
          '캘린더 연동 설정',
          style: AppTypography.cardLabel.copyWith(color: AppColors.protoHeading),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppLayoutTokens.detailScreenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연동할 캘린더를\n선택해 주세요',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.protoHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '기기 기본 캘린더는 OS 권한으로 바로 동기화되며, '
                      '구글·네이버 클라우드 캘린더는 각 계정 OAuth 2.0 로그인 후 연동됩니다.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.protoSubtitle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _AlwaysOnNotice(),
                    const SizedBox(height: 18),

                    // 섹션 1: 기기 로컬 캘린더 동기화 (OS 캘린더 권한 기반)
                    const Text(
                      '기기 로컬 캘린더 동기화 (OS 권한)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      key: const Key('calendar_device_local_toggle'),
                      onTap: () =>
                          _handleDeviceLocalCalendarToggle(context, ref),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: AppLayoutTokens.cardInternalPadding,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDeviceLocalOn
                                ? AppColors.chipGoldOutline
                                : const Color(0xFFE5E7EB),
                            width: isDeviceLocalOn ? 1.6 : 1,
                          ),
                          boxShadow: AppLayoutTokens.luxuryCardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDeviceLocalOn
                                    ? AppColors.chipYellowBg
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.phone_iphone_rounded,
                                size: 20,
                                color: isDeviceLocalOn
                                    ? AppColors.chipYellowText
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '스마트폰 기본 캘린더 (iCloud / Android)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.protoHeading,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '기기 캘린더 접근 권한만으로 일정을 바로 기록해요',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.protoSubtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isDeviceLocalOn,
                              activeTrackColor: AppColors.chipGoldOutline,
                              onChanged: (_) =>
                                  _handleDeviceLocalCalendarToggle(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 섹션 2: 클라우드 계정 연동 (OAuth 2.0 로그인 브라우저 필수)
                    const Text(
                      '클라우드 계정 연동 (OAuth 2.0 로그인)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '토글을 켜면 각 서비스의 OAuth 2.0 로그인 창이 열리며 Access Token 인증 후 API로 연동됩니다.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.protoSubtitle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final option in kCalendarIntegrationOptions) ...[
                      CalendarIntegrationCard(
                        key: Key('calendar_oauth_card_${option.key}'),
                        option: option,
                        selected: selectedKeys.contains(option.key),
                        onTap: () =>
                            _handleCloudOAuthToggle(context, ref, option.key),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            _BottomCta(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _AlwaysOnNotice extends StatelessWidget {
  const _AlwaysOnNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.protoCardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.protoStepLabel,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '하루칩 캘린더는 항상 켜져 있어요',
              style: AppTypography.caption.copyWith(
                color: AppColors.protoSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.protoButtonBg,
              foregroundColor: AppColors.protoButtonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              '확인',
              style: AppTypography.button.copyWith(
                color: AppColors.protoButtonText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
