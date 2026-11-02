import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/controllers/exam_category_controller.dart';
import '../../categories/models/exam_timeline.dart';
import '../../categories/widgets/exam_timeline_tree_widget.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import 'exam_timeline_row.dart';

/// 대시보드 시험/자격증 카드 — CLAUDE.md §8(대시보드 카테고리 카드).
class ExamDashboardCard extends StatelessWidget {
  const ExamDashboardCard({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onSyncItem,
  });

  final List<PlanItem> items;
  final VoidCallback onAdd;
  final ValueChanged<PlanItem> onSyncItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.protoCardSelectedBg, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.protoCardSelectedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📚', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시험 / 자격증 디데이',
                      style: AppTypography.cardLabel.copyWith(
                        color: AppColors.protoHeading,
                      ),
                    ),
                    Text(
                      '목표 달성 프로젝트 (타임라인 트리)',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.protoStepLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.protoCardSelectedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ 추가',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.protoStepLabel,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '아직 등록된 항목이 없어요',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
            )
          else
            for (final item in items) ...[
              if (item.examTimeline.isNotEmpty) ...[
                Builder(builder: (context) {
                  final events = item.examTimeline.map((e) {
                    final eventType = e.stage.isMainExamDay
                        ? ExamEventType.exam
                        : (e.stage == ExamStage.application
                            ? ExamEventType.registration
                            : ExamEventType.result);

                    int flow = 1;
                    if (e.stage == ExamStage.writtenTest) flow = 2;
                    if (e.stage == ExamStage.writtenResult) flow = 3;
                    if (e.stage == ExamStage.practicalTest) flow = 4;
                    if (e.stage == ExamStage.finalResult) flow = 5;

                    return ExamEventItem(
                      id: '${item.id}-${e.stage.name}',
                      title: item.title,
                      date: e.date,
                      stage: e.stage,
                      eventType: eventType,
                      flowOrder: flow,
                      subjectColorHex: '#4A90E2',
                    );
                  }).toList();

                  return ExamTimelineTreeWidget(
                    examTitle: item.title,
                    subjectColorHex: '#4A90E2',
                    events: events,
                    initiallyExpanded: false,
                  );
                }),
              ] else ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.protoCardSelectedBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.protoCardText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.protoButtonBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dDayLabel(item.date),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.protoButtonText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => onSyncItem(item),
                            child: Text(
                              '연동',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.protoSubtitle,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.examTimeline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ExamTimelineRow(entries: item.examTimeline),
                      ],
                    ],
                  ),
                ),
              ],
            ],
        ],
      ),
    );
  }
}
