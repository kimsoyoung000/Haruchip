import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';

/// 모임 투표 생성 다이얼로그
Future<RoomVote?> showAddRoomVoteDialog(
  BuildContext context, {
  required String authorUid,
}) {
  return showModalBottomSheet<RoomVote>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddRoomVoteDialog(authorUid: authorUid),
  );
}

class _AddRoomVoteDialog extends StatefulWidget {
  const _AddRoomVoteDialog({required this.authorUid});

  final String authorUid;

  @override
  State<_AddRoomVoteDialog> createState() => _AddRoomVoteDialogState();
}

class _AddRoomVoteDialogState extends State<_AddRoomVoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final List<TextEditingController> _optionControllers = [];
  bool _allowMultiple = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _optionControllers.add(TextEditingController());
    _optionControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택지는 최대 10개까지 추가할 수 있습니다.')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택지는 최소 2개 이상이어야 합니다.')),
      );
      return;
    }
    setState(() {
      final c = _optionControllers.removeAt(index);
      c.dispose();
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 투표 제목을 입력해주세요.')),
      );
      return;
    }

    final options = <VoteOption>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isNotEmpty) {
        options.add(
          VoteOption(
            id: 'opt-$i-${DateTime.now().microsecondsSinceEpoch}',
            text: text,
            voterUids: const [],
          ),
        );
      }
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 유효한 선택지를 최소 2개 이상 입력해주세요.')),
      );
      return;
    }

    final vote = RoomVote(
      id: 'vote-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      authorUid: widget.authorUid,
      createdAt: DateTime.now(),
      options: options,
      allowMultiple: _allowMultiple,
      isClosed: false,
    );

    Navigator.of(context).pop(vote);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🗳️ 모임 투표 만들기',
                    style: AppTypography.cardLabel.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '투표 제목',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '예: 회식 장소 투표, 날짜 후보 선택',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      '설명 / 안내 (선택)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '투표 관련 추가 안내사항 입력',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '선택지 목록 (${_optionControllers.length}개)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.protoSubtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0F172A)),
                          label: const Text(
                            '항목 추가',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (int i = 0; i < _optionControllers.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _optionControllers[i],
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '선택지 ${i + 1} 입력',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ),
                            if (_optionControllers.length > 2)
                              IconButton(
                                onPressed: () => _removeOption(i),
                                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.redAccent),
                                padding: const EdgeInsets.only(left: 4),
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Multiple choices toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '복수 선택 허용',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '멤버들이 여러 항목을 동시에 투표할 수 있습니다',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: _allowMultiple,
                            onChanged: (v) => setState(() => _allowMultiple = v),
                            activeTrackColor: const Color(0xFF0F172A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('투표 등록하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
