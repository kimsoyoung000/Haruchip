import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_provider.dart';

/// 단일 결혼 준비 항목 3초 빠른 수정/추가 바텀시트
/// (일정명, 날짜/시간, 장소, 담당자[공동/신랑/신부], 시기 그룹, 메모)
class WeddingItemEditModal extends ConsumerStatefulWidget {
  const WeddingItemEditModal({
    super.key,
    this.item,
  });

  final WeddingItem? item;

  static Future<void> show(BuildContext context, [WeddingItem? item]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeddingItemEditModal(item: item),
    );
  }

  @override
  ConsumerState<WeddingItemEditModal> createState() =>
      _WeddingItemEditModalState();
}

class _WeddingItemEditModalState extends ConsumerState<WeddingItemEditModal> {
  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _memoController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late bool _isAllDay;
  late bool _isCompleted;
  late WeddingAssignee _assignee;
  late WeddingDomainGroup _domainGroup;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _locationController = TextEditingController(text: widget.item?.location ?? '');
    _memoController = TextEditingController(text: widget.item?.memo ?? '');

    _selectedDate = widget.item?.targetDate;
    _selectedTime = widget.item?.deadlineTime;
    _isAllDay = widget.item?.deadlineTime == null;
    _isCompleted = widget.item?.isCompleted ?? false;
    _assignee = widget.item?.assignee ?? WeddingAssignee.joint;
    _domainGroup =
        widget.item?.domainGroup ?? WeddingDomainGroup.hallAndCeremony;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정명을 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final location = _locationController.text.trim();
    final memo = _memoController.text.trim();
    final deadlineTime = _isAllDay ? null : _selectedTime;

    if (widget.item != null) {
      final updated = widget.item!.copyWith(
        title: title,
        targetDate: _selectedDate,
        deadlineTime: deadlineTime,
        location: location,
        memo: memo,
        isCompleted: _isCompleted,
        assignee: _assignee,
        domainGroupOverride: _domainGroup,
        clearDate: _selectedDate == null,
        clearTime: _isAllDay || deadlineTime == null,
      );
      ref.read(weddingListProvider.notifier).updateItem(updated);
    } else {
      final currentItems = ref.read(weddingListProvider);
      final newItem = WeddingItem(
        id: 'wedding-custom-${DateTime.now().microsecondsSinceEpoch}',
        orderIndex: currentItems.length + 1,
        title: title,
        targetDate: _selectedDate,
        deadlineTime: deadlineTime,
        location: location,
        memo: memo,
        isCompleted: _isCompleted,
        assignee: _assignee,
        domainGroupOverride: _domainGroup,
        standardOffsetDays: 30,
        stage: WeddingStage.finalCheckAndCeremony,
      );
      ref.read(weddingListProvider.notifier).addItem(newItem);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정이 저장 및 캘린더에 동기화되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _delete() {
    if (widget.item == null) return;
    ref.read(weddingListProvider.notifier).removeItem(widget.item!.id);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정이 삭제되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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

            // 상단 타이틀 + 완료 토글 + 삭제
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _isCompleted = !_isCompleted),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _isCompleted ? _butterYellow : _softGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _isCompleted
                        ? const Icon(Icons.check_rounded, size: 15, color: _deepBrown)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item != null ? '일정 수정' : '새 일정 추가',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _deepBrown,
                    ),
                  ),
                ),
                if (widget.item != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFF9CA3AF),
                    ),
                    tooltip: '일정 삭제',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 1. 일정명
            _buildFieldLabel('일정명'),
            const SizedBox(height: 4),
            TextField(
              key: const Key('wedding_item_title_input'),
              controller: _titleController,
              style: const TextStyle(fontSize: 13.5, color: _deepBrown),
              decoration: _inputDecoration('예: 드레스 투어, 스튜디오 촬영'),
            ),
            const SizedBox(height: 10),

            // 2. 장소 / 업체명
            _buildFieldLabel('장소 / 업체명'),
            const SizedBox(height: 4),
            TextField(
              key: const Key('wedding_item_location_input'),
              controller: _locationController,
              style: const TextStyle(fontSize: 13.5, color: _deepBrown),
              decoration: _inputDecoration('예: 아펠가모 공덕, 로브드K'),
            ),
            const SizedBox(height: 10),

            // 3. 담당자 (공동 / 신랑 / 신부)
            _buildFieldLabel('담당자'),
            const SizedBox(height: 5),
            Row(
              children: [
                for (final a in WeddingAssignee.values) ...[
                  Expanded(
                    child: InkWell(
                      key: Key('wedding_item_assignee_${a.name}'),
                      onTap: () => setState(() => _assignee = a),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _assignee == a ? _butterYellow : _softGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          a.labelKo,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                _assignee == a ? FontWeight.w800 : FontWeight.w600,
                            color: _assignee == a
                                ? _deepBrown
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (a != WeddingAssignee.values.last) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // 4. 일정 및 시간
            _buildFieldLabel('날짜 및 시간'),
            const SizedBox(height: 4),
            CommonDateTimePicker(
              initialStartDate: _selectedDate != null
                  ? DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime?.hour ?? 14,
                      _selectedTime?.minute ?? 0,
                    )
                  : DateTime.now(),
              hasEndDate: false,
              isAllDay: _isAllDay,
              showAllDayToggle: true,
              accentColor: const Color(0xFFF2B84B),
              onDateTimeChanged: (start, _, isAllDay) {
                setState(() {
                  _selectedDate = DateTime(start.year, start.month, start.day);
                  _selectedTime = isAllDay
                      ? null
                      : TimeOfDay(hour: start.hour, minute: start.minute);
                  _isAllDay = isAllDay;
                });
              },
            ),
            const SizedBox(height: 10),

            // 5. 메모
            _buildFieldLabel('메모'),
            const SizedBox(height: 4),
            TextField(
              controller: _memoController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: _deepBrown),
              decoration: _inputDecoration('담당자 연락처, 준비물, 특이사항'),
            ),
            const SizedBox(height: 16),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                key: const Key('wedding_item_save_btn'),
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _butterYellow,
                  foregroundColor: _deepBrown,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.item != null ? '수정 사항 저장' : '일정 추가하기',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8C7E6A),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: _softGray,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
    );
  }
}
