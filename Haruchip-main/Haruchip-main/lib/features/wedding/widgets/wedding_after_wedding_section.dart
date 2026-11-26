import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_extras_models.dart';
import '../providers/wedding_extras_provider.dart';

String _fmtWon(int amount) {
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
}

/// [본식 후 정산 & 답례 (After Wedding)] 사후 관리 체크리스트 섹션
/// - 기본 6대 프리셋 탑재 + 체크박스 완료 토글 + 지출 금액 & 메모 입력/편집 지원
class WeddingAfterWeddingSection extends ConsumerWidget {
  const WeddingAfterWeddingSection({super.key});

  static const Color _butterYellow = AppColors.chipYellowBg; // #FFE699
  static const Color _deepBrown = AppColors.chipYellowText; // #3A2E1A
  static const Color _softGray = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extras = ref.watch(weddingExtrasProvider);
    final tasks = extras.afterWeddingTasks;
    final completed = tasks.where((t) => t.isCompleted).length;

    return Column(
      key: const Key('wedding_after_wedding_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더 + 완료 카운트 + 단일 [+] 라운드 아이콘 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      '본식 후 정산 & 답례',
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
                      '$completed/${tasks.length}',
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
              key: const Key('wedding_add_after_task_btn'),
              onTap: () => _showAfterTaskEditSheet(context, ref),
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

        // 사후 관리 체크리스트 카드 컨테이너
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: tasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      '등록된 사후 관리 항목이 없습니다.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final task in tasks)
                      _buildAfterTaskTile(context, ref, task),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAfterTaskTile(
    BuildContext context,
    WidgetRef ref,
    AfterWeddingTask task,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: _softGray,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          key: Key('wedding_after_task_tile_${task.id}'),
          onTap: () => _showAfterTaskEditSheet(context, ref, existing: task),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  key: Key('wedding_after_task_check_${task.id}'),
                  onTap: () => ref
                      .read(weddingExtrasProvider.notifier)
                      .toggleAfterTask(task.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? _butterYellow : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: _deepBrown,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: task.isCompleted
                              ? const Color(0xFF9CA3AF)
                              : _deepBrown,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.memo.isNotEmpty) ...[
                        const SizedBox(height: 1.5),
                        Text(
                          task.memo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8C7E6A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.costAmount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4CC),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      _fmtWon(task.costAmount),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _deepBrown,
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

  Future<void> _showAfterTaskEditSheet(
    BuildContext context,
    WidgetRef ref, {
    AfterWeddingTask? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final costCtrl = TextEditingController(
      text: existing != null && existing.costAmount > 0
          ? existing.costAmount.toString()
          : '',
    );
    final memoCtrl = TextEditingController(text: existing?.memo ?? '');

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
                Text(
                  existing != null ? '사후 정산 항목 수정' : '사후 정산 항목 추가',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _deepBrown,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '항목명',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8C7E6A),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 13, color: _deepBrown),
                  decoration: _dec('예: 사회자 수고비 정산'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '지출 금액 (선택)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8C7E6A),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  key: const Key('wedding_after_task_cost_input'),
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _deepBrown,
                  ),
                  decoration: _dec('예: 200000', suffix: '원'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '메모',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8C7E6A),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: memoCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: _deepBrown),
                  decoration: _dec('송금 계좌, 전달 완료 여부 등 메모'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (existing != null) ...[
                      TextButton(
                        onPressed: () {
                          ref
                              .read(weddingExtrasProvider.notifier)
                              .deleteAfterTask(existing.id);
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
                          key: const Key('wedding_after_task_save_btn'),
                          onPressed: () {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            final cost = int.tryParse(
                                    costCtrl.text.replaceAll(',', '').trim()) ??
                                0;
                            final notifier =
                                ref.read(weddingExtrasProvider.notifier);
                            if (existing != null) {
                              notifier.updateAfterTask(
                                existing.copyWith(
                                  title: title,
                                  costAmount: cost,
                                  memo: memoCtrl.text.trim(),
                                ),
                              );
                            } else {
                              notifier.addAfterTask(
                                AfterWeddingTask(
                                  id: 'after-${DateTime.now().microsecondsSinceEpoch}',
                                  title: title,
                                  costAmount: cost,
                                  memo: memoCtrl.text.trim(),
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
                          child: const Text(
                            '저장하기',
                            style: TextStyle(
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
    );
    titleCtrl.dispose();
    costCtrl.dispose();
    memoCtrl.dispose();
  }

  InputDecoration _dec(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      suffixText: suffix,
      suffixStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8C7E6A),
      ),
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
