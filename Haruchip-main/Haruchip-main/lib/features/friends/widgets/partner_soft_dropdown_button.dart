import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../models/battle_tag_user.dart';
import '../providers/friend_system_provider.dart';

/// 커플 · 군대(곰신) · 결혼 준비 상세 화면 앱바 우측 소프트 드롭다운(Flyout) 파트너 공유 버튼
class PartnerSoftDropdownButton extends ConsumerStatefulWidget {
  const PartnerSoftDropdownButton({
    super.key,
    required this.categoryKey,
    required this.categoryName,
  });

  final String categoryKey; // 'couple' | 'military' | 'wedding'
  final String categoryName;

  @override
  ConsumerState<PartnerSoftDropdownButton> createState() =>
      _PartnerSoftDropdownButtonState();
}

class _PartnerSoftDropdownButtonState
    extends ConsumerState<PartnerSoftDropdownButton>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _removeOverlay(immediate: true);
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  Future<void> _removeOverlay({bool immediate = false}) async {
    if (_overlayEntry == null) return;
    if (!immediate && _animController.isCompleted) {
      await _animController.reverse();
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (overlayCtx) {
        return Stack(
          children: [
            // 외부 영역 탭 시 부드럽게 닫힘
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _removeOverlay(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Material(
                    color: Colors.transparent,
                    child: Consumer(
                      builder: (ctx, ref, _) {
                        final state = ref.watch(friendSystemProvider);
                        final link = state.partnerFor(widget.categoryKey);
                        return _buildFlyoutCard(link);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_overlayEntry!);
    _animController.forward(from: 0.0);
  }

  Widget _buildFlyoutCard(CategoryPartnerLink? link) {
    return Container(
      key: Key('partner_soft_flyout_${widget.categoryKey}'),
      width: 256,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: link == null ? _buildUnconnectedBody() : _buildConnectedBody(link),
    );
  }

  Widget _buildUnconnectedBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.group_outlined, size: 17, color: AppColors.protoHeading),
            SizedBox(width: 6),
            Text(
              '파트너 실시간 공유',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.protoHeading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '아직 함께하는 파트너가 없어요',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          key: const Key('partner_invite_from_friends_btn'),
          onPressed: () async {
            await _removeOverlay(immediate: true);
            if (!mounted) return;
            _showInviteFriendBottomSheet();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.chipYellowBg,
            foregroundColor: AppColors.chipYellowText,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '내 친구에서 초대하기',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedBody(CategoryPartnerLink link) {
    return InkWell(
      key: const Key('partner_connected_profile_row'),
      onTap: () async {
        await _removeOverlay(immediate: true);
        if (!mounted) return;
        _showPartnerDetailSheet(link);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF3FAF4),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: HaruChipIconViewer(
                iconKey: link.partner.avatarIcon,
                size: 24,
                circular: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    link.partner.fullHandle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '실시간 동기화 중 💚',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6B3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInviteFriendBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final friends = ref.watch(friendSystemProvider).friends;
          return Container(
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
                  Text(
                    '${widget.categoryName} 파트너 초대',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '내 친구 목록에서 함께 실시간 동기화할 파트너를 선택하세요.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),
                  if (friends.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '등록된 친구가 아직 없어요.\n[설정 > 친구 관리]에서 닉네임#태그로 친구를 먼저 추가해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    for (final friend in friends) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            HaruChipIconViewer(
                              iconKey: friend.avatarIcon,
                              size: 28,
                              circular: true,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                friend.fullHandle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.protoHeading,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(friendSystemProvider.notifier)
                                    .connectCategoryPartner(
                                      categoryKey: widget.categoryKey,
                                      partner: friend,
                                    );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${friend.nickname}님과 실시간 동기화가 연결되었습니다.',
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                '연결',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPartnerDetailSheet(CategoryPartnerLink link) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3FAF4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: HaruChipIconViewer(
                  iconKey: link.partner.avatarIcon,
                  size: 34,
                  circular: true,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                link.partner.fullHandle,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.protoHeading,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '실시간 동기화 중 💚',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E6B3E),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('partner_disconnect_btn'),
                  onPressed: () {
                    ref
                        .read(friendSystemProvider.notifier)
                        .disconnectCategoryPartner(widget.categoryKey);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('파트너 연결이 해제되었습니다.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '연결 해제',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link = ref.watch(
      friendSystemProvider.select((s) => s.partnerFor(widget.categoryKey)),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        key: Key('partner_share_dropdown_button_${widget.categoryKey}'),
        onPressed: _toggleDropdown,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
        tooltip: '파트너 공유',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 21,
              color: AppColors.protoHeading,
            ),
            if (link != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
