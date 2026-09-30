import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';

/// 모임 공지/메모 추가 다이얼로그
Future<RoomNotice?> showAddRoomNoticeDialog(
  BuildContext context, {
  required String authorName,
  required String authorIcon,
}) {
  return showDialog<RoomNotice>(
    context: context,
    builder: (ctx) => _AddRoomNoticeDialog(
      authorName: authorName,
      authorIcon: authorIcon,
    ),
  );
}

class _AddRoomNoticeDialog extends StatefulWidget {
  const _AddRoomNoticeDialog({
    required this.authorName,
    required this.authorIcon,
  });

  final String authorName;
  final String authorIcon;

  @override
  State<_AddRoomNoticeDialog> createState() => _AddRoomNoticeDialogState();
}

class _AddRoomNoticeDialogState extends State<_AddRoomNoticeDialog> {
  late TextEditingController _contentController;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 공지 내용을 입력해주세요.')),
      );
      return;
    }

    final notice = RoomNotice(
      id: 'notice-${DateTime.now().microsecondsSinceEpoch}',
      authorName: widget.authorName,
      authorIcon: widget.authorIcon,
      content: content,
      createdAt: DateTime.now(),
      isPinned: _isPinned,
    );

    Navigator.of(context).pop(notice);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📌 공지 / 메모 등록',
                  style: AppTypography.cardLabel.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.protoHeading,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '모임 멤버들과 공유할 공지사항이나 메모를 작성하세요...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v ?? false),
                  activeColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const Text(
                  '상단에 고정하기 📌',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('공지 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
