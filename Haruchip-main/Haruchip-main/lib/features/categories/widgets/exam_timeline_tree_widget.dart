import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../controllers/exam_category_controller.dart';
import '../models/category.dart';

/// 시험 카테고리 타임라인 트리 & 세부 일정 렌더링 위젯
///
/// 시각적 디자인 규칙:
/// 1. 시험일 (메인): `subjectColor` 기반의 진하고 눈에 띄는 메인 강조 컬러, 가장 굵은 폰트 스타일.
/// 2. 접수일/발표일 (서브): 동일 계열의 채도가 낮고 차분한 서브 컬러 적용, 일반/얇은 폰트 스타일.
/// 3. 종료(마감)된 일정: 지나간 일정은 Opacity (0.4~0.5), Gray-out 처리 및 취소선(TextDecoration.lineThrough) 표기.
/// 4. 타임라인 트리 UI: 하나의 시험 클릭 시 `접수 → 필기 → 발표 → 실기 → 최종합격` 순으로 연동되는 세로 타임라인 트리를 노출.
/// 5. D-Day가 임박한 순서대로 상단 배치.
class ExamTimelineTreeWidget extends StatefulWidget {
  const ExamTimelineTreeWidget({
    super.key,
    required this.examTitle,
    required this.subjectColorHex,
    required this.events,
    this.initiallyExpanded = true,
  });

  final String examTitle;
  final String subjectColorHex;
  final List<ExamEventItem> events;
  final bool initiallyExpanded;

  @override
  State<ExamTimelineTreeWidget> createState() => _ExamTimelineTreeWidgetState();
}

class _ExamTimelineTreeWidgetState extends State<ExamTimelineTreeWidget> {
  late bool _isExpanded;
  final _controller = const ExamCategoryController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = colorFromHex(widget.subjectColorHex);
    final sortedByUrgency = _controller.sortEventsByUrgency(widget.events);
    final sortedByFlow = _controller.sortByFlowOrder(widget.events);

    final nearestEvent = sortedByUrgency.isNotEmpty ? sortedByUrgency.first : null;
    final nearestDays = nearestEvent?.daysRemaining();

    String badgeLabel = 'D-day';
    if (nearestDays != null) {
      if (nearestDays == 0) {
        badgeLabel = 'D-day';
      } else if (nearestDays > 0) {
        badgeLabel = 'D-$nearestDays';
      } else {
        badgeLabel = 'D+${nearestDays.abs()}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: subjectColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시험 헤더 카드
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.examTitle,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.protoHeading,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.protoSubtitle,
                  ),
                ],
              ),
            ),
          ),

          // 펼쳐졌을 때의 세로 타임라인 트리 UI
          if (_isExpanded && sortedByFlow.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.protoCardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 세로 타임라인 트리 (접수 → 필기 → 발표 → 실기 → 최종)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.protoSubtitle,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedByFlow.length,
                    itemBuilder: (context, index) {
                      final item = sortedByFlow[index];
                      final isLast = index == sortedByFlow.length - 1;
                      return _TimelineNodeTile(
                        item: item,
                        subjectColor: subjectColor,
                        isLast: isLast,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 타임라인 트리의 세로 노드 타일
class _TimelineNodeTile extends StatelessWidget {
  const _TimelineNodeTile({
    required this.item,
    required this.subjectColor,
    required this.isLast,
  });

  final ExamEventItem item;
  final Color subjectColor;
  final bool isLast;

  static final _controller = const ExamCategoryController();

  @override
  Widget build(BuildContext context) {
    final isPast = item.isEnded();
    final isMain = item.isMain;

    // 1. 메인 시험일 vs 서브 일정 컬러 결정
    final mainColor = subjectColor;
    final subColor = _controller.getSubColor(subjectColor);
    final endedGrayColor = _controller.getEndedGrayColor(subjectColor);

    Color nodeColor;
    Color textColor;
    FontWeight fontWeight;
    TextDecoration? decoration;

    if (isPast) {
      // 3. 마감된 일정: Gray-out & 취소선
      nodeColor = endedGrayColor;
      textColor = endedGrayColor;
      fontWeight = FontWeight.w400;
      decoration = TextDecoration.lineThrough;
    } else if (isMain) {
      // 1. 시험일 (메인): 진하고 눈에 띄는 메인 강조 컬러 & 가장 굵은 폰트
      nodeColor = mainColor;
      textColor = mainColor;
      fontWeight = FontWeight.w900;
      decoration = null;
    } else {
      // 2. 접수일/발표일 (서브): 동일 계열 채도 낮은 서브 컬러 & 일반 폰트
      nodeColor = subColor;
      textColor = subColor;
      fontWeight = FontWeight.w500;
      decoration = null;
    }

    final monthStr = item.date.month.toString().padLeft(2, '0');
    final dayStr = item.date.day.toString().padLeft(2, '0');
    final dateFormatted = '${item.date.year}.$monthStr.$dayStr';

    final daysDiff = item.daysRemaining();
    String dDayStr = 'D-day';
    if (daysDiff > 0) {
      dDayStr = 'D-$daysDiff';
    } else if (daysDiff < 0) {
      dDayStr = '마감됨';
    }

    Widget contentTile = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 세로 트리 연결 라인 & 노드 아이콘
        Column(
          children: [
            Container(
              width: isMain ? 16 : 12,
              height: isMain ? 16 : 12,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMain ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isMain
                    ? [
                        BoxShadow(
                          color: nodeColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isPast
                    ? endedGrayColor.withValues(alpha: 0.3)
                    : subColor.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(width: 12),

        // 이벤트 텍스트 상세
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.flowOrder}단계',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: nodeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.stage.labelKo} (${item.title})',
                        style: TextStyle(
                          fontSize: isMain ? 14 : 12,
                          color: textColor,
                          fontWeight: fontWeight,
                          decoration: decoration,
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 11,
                          color: isPast ? endedGrayColor : AppColors.protoSubtitle,
                          decoration: decoration,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPast
                        ? endedGrayColor.withValues(alpha: 0.2)
                        : (isMain
                            ? mainColor.withValues(alpha: 0.2)
                            : subColor.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    dDayStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                      color: isPast ? endedGrayColor : textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // 3. 종료된 일정: Opacity (0.4~0.5) 적용
    if (isPast) {
      return Opacity(
        opacity: 0.45,
        child: contentTile,
      );
    }
    return contentTile;
  }
}
