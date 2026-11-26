import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../core/security/input_sanitizer.dart';
import '../../../design_system/colors.dart';
import '../models/battle_tag_user.dart';
import '../providers/friend_system_provider.dart';

/// [설정 > 내 친구 N명] 터치 시 열리는 독립 [친구 관리] 바텀시트 모달
Future<void> showFriendManagementModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.84,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 10, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '친구 관리',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: FriendManagementCard(embeddedInModal: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 통합 친구 관리 모듈 (배틀태그 검색 · 받은 요청 · 내 친구 목록 · 차단 목록 관리)
class FriendManagementCard extends ConsumerStatefulWidget {
  const FriendManagementCard({super.key, this.embeddedInModal = false});

  final bool embeddedInModal;

  @override
  ConsumerState<FriendManagementCard> createState() =>
      _FriendManagementCardState();
}

class _FriendManagementCardState extends ConsumerState<FriendManagementCard> {
  final TextEditingController _searchController = TextEditingController();
  BattleTagUser? _searchResult;
  List<BattleTagUser> _suggestions = const [];
  bool _hasSearched = false;
  bool _isSearching = false;
  bool _showBlockedList = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String raw) async {
    final compact = raw.replaceAll(' ', '');
    if (compact.length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }
    final list = await ref
        .read(friendSystemProvider.notifier)
        .suggestUsersByPrefix(raw, limit: 4);
    if (!mounted) return;
    setState(() => _suggestions = list);
  }

  void _selectSuggestion(BattleTagUser user) {
    _searchController.text = user.fullHandle;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: user.fullHandle.length),
    );
    setState(() {
      _suggestions = const [];
      _searchResult = user;
      _hasSearched = true;
      _isSearching = false;
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _suggestions = const [];
    });
    final found = await ref
        .read(friendSystemProvider.notifier)
        .searchByFullHandle(query);
    if (!mounted) return;
    setState(() {
      _searchResult = found;
      _hasSearched = true;
      _isSearching = false;
    });
  }

  Future<void> _showAliasEditDialog(
    BuildContext context,
    BattleTagUser friend,
    String? currentAlias,
  ) async {
    final ctrl = TextEditingController(text: currentAlias ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '친구 별명 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.protoHeading,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${friend.fullHandle}님에게 나만 볼 수 있는 별명을 지정할 수 있어요.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('friend_alias_input'),
              controller: ctrl,
              maxLength: 12,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '별명 입력 (비우면 원래 닉네임 표시)',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            key: const Key('friend_alias_save_btn'),
            onPressed: () {
              ref
                  .read(friendSystemProvider.notifier)
                  .setFriendAlias(friend.uid, ctrl.text);
              Navigator.pop(dialogCtx);
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
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendSystemProvider);

    return Container(
      key: const Key('settings_friend_management_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) 친구 검색 및 추가 (닉네임#태그)
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('friend_search_input'),
                  controller: _searchController,
                  inputFormatters: [
                    HaruInputSanitizer.battleTagInputFormatter,
                  ],
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: '닉네임 또는 닉네임#태그 검색 (2글자 이상)',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    filled: true,
                    fillColor: AppColors.cleanCanvasBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const Key('friend_search_button'),
                onPressed: _isSearching ? null : _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipYellowBg,
                  foregroundColor: AppColors.chipYellowText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '검색',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          // 실시간 자동완성 추천 드롭다운 (최대 4명 노출)
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              key: const Key('friend_autocomplete_dropdown'),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _suggestions.length; i++) ...[
                    InkWell(
                      key: Key('friend_suggestion_${_suggestions[i].uid}'),
                      onTap: () => _selectSuggestion(_suggestions[i]),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            HaruChipIconViewer(
                              iconKey: _suggestions[i].avatarIcon,
                              size: 24,
                              circular: true,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _suggestions[i].fullHandle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.protoHeading,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.north_west_rounded,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i != _suggestions.length - 1)
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ],
                ],
              ),
            ),
          ],

          // 검색 결과 카드
          if (_hasSearched) ...[
            const SizedBox(height: 10),
            if (_searchResult == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '일치하는 닉네임#태그 유저를 찾지 못했어요.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              )
            else
              _buildSearchResultTile(state, _searchResult!),
          ],

          // 2) 받은 친구 요청
          if (state.incomingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            Text(
              '받은 친구 요청 (${state.incomingRequests.length})',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.protoHeading,
              ),
            ),
            const SizedBox(height: 8),
            for (final req in state.incomingRequests)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    HaruChipIconViewer(
                      iconKey: req.fromUser.avatarIcon,
                      size: 26,
                      circular: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.fromUser.fullHandle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(friendSystemProvider.notifier)
                          .rejectFriendRequest(req.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '거절',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(friendSystemProvider.notifier)
                          .acceptFriendRequest(req.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chipYellowBg,
                        foregroundColor: AppColors.chipYellowText,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),

          // 3) 내 친구 목록 (N명)
          Text(
            '내 친구 목록 (${state.friends.length}명)',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.protoHeading,
            ),
          ),
          const SizedBox(height: 8),
          if (state.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '아직 등록된 친구가 없습니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            )
          else
            for (final friend in state.friends)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cleanCanvasBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    HaruChipIconViewer(
                      iconKey: friend.avatarIcon,
                      size: 26,
                      circular: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.displayLabelFor(friend),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                    IconButton(
                      key: Key('friend_alias_btn_${friend.uid}'),
                      tooltip: '별명 설정',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF8C7E6A),
                      ),
                      onPressed: () => _showAliasEditDialog(
                        context,
                        friend,
                        state.aliasFor(friend.uid),
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (action) {
                        final notifier =
                            ref.read(friendSystemProvider.notifier);
                        if (action == 'alias') {
                          _showAliasEditDialog(
                            context,
                            friend,
                            state.aliasFor(friend.uid),
                          );
                        } else if (action == 'delete') {
                          notifier.removeFriend(friend.uid);
                        } else if (action == 'block') {
                          notifier.blockUser(friend);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'alias',
                          child: Text(
                            '별명 설정',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            '친구 삭제',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'block',
                          child: Text(
                            '차단하기',
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
              ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),

          // 4) 차단 목록 관리
          InkWell(
            onTap: () => setState(() => _showBlockedList = !_showBlockedList),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '차단 목록 관리 (${state.blockedUsers.length}명)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Icon(
                    _showBlockedList
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
          if (_showBlockedList) ...[
            const SizedBox(height: 8),
            if (state.blockedUsers.isEmpty)
              const Text(
                '차단된 사용자가 없습니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              )
            else
              for (final blocked in state.blockedUsers)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          blocked.fullHandle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7F1D1D),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(friendSystemProvider.notifier)
                            .unblockUser(blocked.uid),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '차단 해제',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(FriendSystemState state, BattleTagUser user) {
    final alreadyFriend = state.isFriend(user.uid);
    final alreadySent = state.hasSentRequest(user.uid);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cleanCanvasBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          HaruChipIconViewer(
            iconKey: user.avatarIcon,
            size: 28,
            circular: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              user.fullHandle,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.protoHeading,
              ),
            ),
          ),
          if (alreadyFriend)
            const Text(
              '이미 친구',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E6B3E),
              ),
            )
          else if (alreadySent)
            const Text(
              '요청 완료',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
            )
          else
            ElevatedButton(
              key: const Key('friend_send_request_button'),
              onPressed: () async {
                await ref
                    .read(friendSystemProvider.notifier)
                    .sendFriendRequest(user);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.fullHandle}님에게 친구 요청을 보냈습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chipYellowBg,
                foregroundColor: AppColors.chipYellowText,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                '친구 요청',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
