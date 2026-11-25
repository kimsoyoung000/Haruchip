import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/haruchip_icon_picker.dart';
import '../../../core/icons/haruchip_icon_viewer.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';
import '../providers/schedule_room_provider.dart';

/// 새 모임 만들기 다이얼로그
Future<ScheduleRoom?> showCreateRoomDialog(BuildContext context, [WidgetRef? ref]) {
  return showDialog<ScheduleRoom>(
    context: context,
    builder: (ctx) => const _CreateRoomDialog(),
  );
}

class _CreateRoomDialog extends ConsumerStatefulWidget {
  const _CreateRoomDialog();

  @override
  ConsumerState<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<_CreateRoomDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _nicknameController = TextEditingController(text: '하루');
  final _customCategoryController = TextEditingController();

  String _selectedEmoji = 'simple_chick';
  String _selectedColor = kPreset50PastelColors[0];
  String _selectedCategory = '동창/동문';
  bool _isCustomCategory = false;

  static const List<String> _categories = [
    '동창/동문',
    '스터디',
    '프로젝트',
    '운동/스포츠',
    '취미/소모임',
    '가족',
    '여행',
    '친목/정기모임',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _nicknameController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _handleCreate() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 모임 방 이름을 입력해주세요.')),
      );
      return;
    }

    final resolvedCategory = _isCustomCategory
        ? (_customCategoryController.text.trim().isNotEmpty
            ? _customCategoryController.text.trim()
            : '기타 모임')
        : _selectedCategory;

    final nickname = _nicknameController.text.trim().isEmpty
        ? '나'
        : _nicknameController.text.trim();

    // 멤버 구분은 계정 uid로 (닉네임은 표시용 이름일 뿐)
    final host = RoomMember(
      uid: ref.read(currentUserProfileProvider).uid,
      name: nickname,
      icon: _selectedEmoji,
      colorHex: _selectedColor,
      isHost: true,
    );

    setState(() => _submitting = true);
    try {
      final newRoom = await ref
          .read(scheduleRoomsProvider.notifier)
          .createRoomSynced(
            name: name,
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            categoryTag: resolvedCategory,
            hostMember: host,
          );
      if (!mounted) return;
      Navigator.of(context).pop(newRoom);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ 방을 만들지 못했어요. 로그인·네트워크·보안 규칙을 확인해주세요. ($e)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '새 모임 만들기',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.protoHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. 모임 이름
            const Text(
              '모임 이름',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '모임명을 입력해 주세요',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
            const SizedBox(height: 14),

            // 2. 모임 분류 (확장된 프리셋 + 직접 입력)
            const Text(
              '모임 분류',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cat in _categories)
                  _buildCategoryChip(
                    label: cat,
                    selected: !_isCustomCategory && _selectedCategory == cat,
                    onTap: () => setState(() {
                      _isCustomCategory = false;
                      _selectedCategory = cat;
                    }),
                  ),
                _buildCategoryChip(
                  label: '+ 직접 입력',
                  selected: _isCustomCategory,
                  onTap: () => setState(() {
                    _isCustomCategory = true;
                  }),
                ),
              ],
            ),
            if (_isCustomCategory) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customCategoryController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '원하는 모임 분류명을 입력해 주세요 (예: 북클럽, 러닝크루)',
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFBF0),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.chipGoldOutline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.chipGoldOutline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.chipGoldOutline,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 3. 내 프로필 설정 (아이콘 + 닉네임 + 고유 색상)
            const Text(
              '내 모임 프로필 & 식별 컬러',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showHaruChipIconPicker(
                      context,
                      initialIconKey: _selectedEmoji,
                      title: '모임 프로필 아이콘 선택',
                    );
                    if (picked != null && mounted) {
                      setState(() => _selectedEmoji = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse('0xFF${_selectedColor.replaceAll('#', '')}'),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HaruChipIconViewer(
                          iconKey: _selectedEmoji,
                          size: 24,
                          circular: true,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF334155),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: '내 닉네임 입력',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 파스텔 50색 팔레트 프리뷰
            const Text(
              '공유 캘린더 전용 1인 1색상',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kPreset50PastelColors.take(18).map((hex) {
                final isSel = _selectedColor == hex;
                final col = Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel
                            ? AppColors.chipYellowText
                            : Colors.black12,
                        width: isSel ? 2.2 : 1,
                      ),
                    ),
                    child: isSel
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.chipYellowText,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 생성 버튼 (하루칩 시그니처 웜 파스텔 옐로우 #FFE699 + 다크 브라운 #3A2E1A)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipYellowBg,
                  foregroundColor: AppColors.chipYellowText,
                  overlayColor: const Color(0xFFF7D779),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '모임 방 개설하기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipYellowBg : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.chipGoldOutline : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.chipYellowText : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
