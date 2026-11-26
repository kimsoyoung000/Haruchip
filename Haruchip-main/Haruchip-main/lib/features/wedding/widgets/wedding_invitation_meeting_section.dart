import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/wedding_extras_models.dart';
import '../providers/wedding_extras_provider.dart';

String _fmtDateWithWd(DateTime d) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = weekdays[(d.weekday - 1).clamp(0, 6)];
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}($wd)';
}

/// [청첩장 모임 & 하객/보증인원] 독립 관리 섹션
///
/// 1) 보증인원 카운터 대시보드: 계약 보증인원 | 현재 확정 하객 | 차이(±N명)
/// 2) 청첩장 모임(청모) 리스트: 모임명, 날짜/장소, 소속(신랑/신부/공동), 인원, 1인당 식대, 완료 토글
class WeddingInvitationMeetingSection extends ConsumerWidget {
  const WeddingInvitationMeetingSection({super.key});

  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extras = ref.watch(weddingExtrasProvider);
    final diff = extras.guestDiff;
    final diffText = diff == 0 ? '0명' : (diff > 0 ? '+$diff명' : '$diff명');
    final sortedMeetings = List<WeddingInvitationMeeting>.from(extras.meetings)
      ..sort(compareMeetingsByCloseness);

    return Column(
      key: const Key('wedding_invitation_meetings_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더 + 단일 [+] 라운드 아이콘 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      '청첩장 모임',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${sortedMeetings.length}건',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              key: const Key('wedding_add_meeting_btn'),
              onTap: () => _showMeetingEditSheet(context, ref),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _butterYellow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: _deepBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),

        // 1. 보증인원 카운터 대시보드 (탭하여 보증인원/기타 하객 수정)
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('wedding_guest_counter_card'),
            onTap: () => _showGuestCountEditSheet(context, ref, extras),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFFFFFBF0)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCounterCol(
                      '계약 보증인원',
                      '${extras.guaranteedGuests}명',
                      _deepBrown,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFEDE6D6),
                  ),
                  Expanded(
                    child: _buildCounterCol(
                      '현재 확정 하객',
                      '${extras.totalConfirmedGuests}명',
                      _deepBrown,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFEDE6D6),
                  ),
                  Expanded(
                    child: _buildCounterCol(
                      '차이',
                      diffText,
                      diff >= 0
                          ? const Color(0xFF1E7B56)
                          : const Color(0xFF8A6216),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 2. 청첩장 모임(청모) D-Day 임박순 슬림 리스트
        if (sortedMeetings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '등록된 청첩장 모임이 없습니다. 우측 [+]로 추가해 보세요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          )
        else
          Container(
            key: const Key('wedding_meetings_sorted_list'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (final meeting in sortedMeetings)
                  _buildMeetingCard(context, ref, meeting),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCounterCol(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8C7E6A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// 1줄 슬림 청모 타일: `[체크] 모임명 · 📍장소 · N명 -------- [ 2026.11.29(일) · D-3 ]`
  Widget _buildMeetingCard(
    BuildContext context,
    WidgetRef ref,
    WeddingInvitationMeeting meeting,
  ) {
    final badgeText = meeting.formattedDateWithWeekdayAndDday();
    final hasDate = meeting.meetingDate != null;
    final detailMeta =
        '${meeting.location.isNotEmpty ? '· 📍${meeting.location} ' : ''}· ${meeting.attendeeCount}명';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: _softGray,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: Key('wedding_meeting_card_${meeting.id}'),
          onTap: () => _showMeetingEditSheet(context, ref, existing: meeting),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              children: [
                InkWell(
                  key: Key('wedding_meeting_check_${meeting.id}'),
                  onTap: () => ref
                      .read(weddingExtrasProvider.notifier)
                      .toggleMeetingCompleted(meeting.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: meeting.isCompleted ? _butterYellow : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: meeting.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: _deepBrown,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          meeting.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: meeting.isCompleted
                                ? const Color(0xFF9CA3AF)
                                : _deepBrown,
                            decoration: meeting.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          detailMeta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: meeting.isCompleted
                                ? const Color(0xFFB0B7C3)
                                : const Color(0xFF8C7E6A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: meeting.isCompleted
                        ? const Color(0xFFECEEF1)
                        : (hasDate ? const Color(0xFFFFF4CC) : Colors.white),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: meeting.isCompleted
                          ? const Color(0xFF9CA3AF)
                          : (hasDate ? _deepBrown : const Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGuestCountEditSheet(
    BuildContext context,
    WidgetRef ref,
    WeddingExtrasState extras,
  ) async {
    final guaranteedCtrl =
        TextEditingController(text: extras.guaranteedGuests.toString());
    final extraCtrl =
        TextEditingController(text: extras.extraConfirmedGuests.toString());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: SafeArea(
            top: false,
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
                const Text(
                  '보증인원 및 하객 수 설정',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _deepBrown,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumField(
                        key: const Key('wedding_guaranteed_guests_input'),
                        label: '웨딩홀 계약 보증인원',
                        controller: guaranteedCtrl,
                        suffix: '명',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildNumField(
                        key: const Key('wedding_extra_guests_input'),
                        label: '청모 외 확정 하객',
                        controller: extraCtrl,
                        suffix: '명',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '청첩장 모임 등록 인원(${extras.meetingGuestsTotal}명)과 자동 합산됩니다.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('wedding_guest_count_save_btn'),
                    onPressed: () {
                      final g = int.tryParse(guaranteedCtrl.text.trim()) ??
                          extras.guaranteedGuests;
                      final e = int.tryParse(extraCtrl.text.trim()) ??
                          extras.extraConfirmedGuests;
                      ref.read(weddingExtrasProvider.notifier).setGuestCounts(
                            guaranteedGuests: g,
                            extraConfirmedGuests: e,
                          );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _butterYellow,
                      foregroundColor: _deepBrown,
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
    );
    guaranteedCtrl.dispose();
    extraCtrl.dispose();
  }

  Future<void> _showMeetingEditSheet(
    BuildContext context,
    WidgetRef ref, {
    WeddingInvitationMeeting? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final countCtrl = TextEditingController(
      text: (existing?.attendeeCount ?? 4).toString(),
    );
    final mealCtrl = TextEditingController(
      text: (existing?.mealCostPerPerson ?? 50000).toString(),
    );
    DateTime? selectedDate = existing?.meetingDate;
    GuestAffiliation affiliation =
        existing?.affiliation ?? GuestAffiliation.joint;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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
                    Text(
                      existing != null ? '청첩장 모임 수정' : '새 청첩장 모임 등록',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _deepBrown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      key: const Key('wedding_meeting_title_input'),
                      label: '모임명',
                      controller: titleCtrl,
                      hint: '예: 초등 동창 청모, 회사 동기 모임',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      label: '장소',
                      controller: locCtrl,
                      hint: '예: 강남역 모임 식당',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '소속 구분',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8C7E6A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        for (final a in GuestAffiliation.values) ...[
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => affiliation = a),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: affiliation == a
                                      ? _butterYellow
                                      : _softGray,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  a.labelKo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: affiliation == a
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: affiliation == a
                                        ? _deepBrown
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (a != GuestAffiliation.values.last)
                            const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '모임 날짜',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8C7E6A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showHaruDatePicker(
                          context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _softGray,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          selectedDate != null
                              ? _fmtDateWithWd(selectedDate!)
                              : '날짜 선택 (미정)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selectedDate != null
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedDate != null
                                ? _deepBrown
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumField(
                            key: const Key('wedding_meeting_count_input'),
                            label: '참석 인원수',
                            controller: countCtrl,
                            suffix: '명',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumField(
                            label: '1인당 예상 식대',
                            controller: mealCtrl,
                            suffix: '원',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (existing != null) ...[
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(weddingExtrasProvider.notifier)
                                  .deleteMeeting(existing.id);
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF9CA3AF),
                            ),
                            child: const Text(
                              '삭제',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              key: const Key('wedding_meeting_save_btn'),
                              onPressed: () {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) return;
                                final count =
                                    int.tryParse(countCtrl.text.trim()) ?? 1;
                                final meal = int.tryParse(
                                        mealCtrl.text.replaceAll(',', '').trim()) ??
                                    0;
                                final notifier =
                                    ref.read(weddingExtrasProvider.notifier);
                                if (existing != null) {
                                  notifier.updateMeeting(
                                    existing.copyWith(
                                      title: title,
                                      location: locCtrl.text.trim(),
                                      meetingDate: selectedDate,
                                      clearMeetingDate: selectedDate == null,
                                      affiliation: affiliation,
                                      attendeeCount: count,
                                      mealCostPerPerson: meal,
                                    ),
                                  );
                                } else {
                                  notifier.addMeeting(
                                    WeddingInvitationMeeting(
                                      id: 'meeting-${DateTime.now().microsecondsSinceEpoch}',
                                      title: title,
                                      location: locCtrl.text.trim(),
                                      meetingDate: selectedDate,
                                      affiliation: affiliation,
                                      attendeeCount: count,
                                      mealCostPerPerson: meal,
                                    ),
                                  );
                                }
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _butterYellow,
                                foregroundColor: _deepBrown,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                existing != null ? '수정 저장' : '모임 추가',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    locCtrl.dispose();
    countCtrl.dispose();
    mealCtrl.dispose();
  }

  Widget _buildTextField({
    Key? key,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C7E6A),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: key,
          controller: controller,
          style: const TextStyle(fontSize: 13, color: _deepBrown),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: _softGray,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumField({
    Key? key,
    required String label,
    required TextEditingController controller,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C7E6A),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: key,
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _deepBrown,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8C7E6A),
            ),
            filled: true,
            fillColor: _softGray,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
