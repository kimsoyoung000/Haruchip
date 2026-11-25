import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../models/baby_profile.dart';

/// 독립된 아기 신체 성장 기록 카드 위젯 (간략히 보기/펼치기 아코디언 + 하루칩 옐로우 기록 추가 버튼)
class BabyGrowthRecordsWidget extends StatefulWidget {
  const BabyGrowthRecordsWidget({
    super.key,
    required this.profile,
    required this.onOpenAddGrowthRecord,
    required this.onEditGrowthRecord,
  });

  final BabyProfile profile;
  final VoidCallback onOpenAddGrowthRecord;
  final ValueChanged<GrowthRecord> onEditGrowthRecord;

  @override
  State<BabyGrowthRecordsWidget> createState() =>
      _BabyGrowthRecordsWidgetState();
}

class _BabyGrowthRecordsWidgetState extends State<BabyGrowthRecordsWidget> {
  bool _isExpanded = false; // 기본값: 간략히 보기

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final records = List<GrowthRecord>.from(widget.profile.growthRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    final latest = records.isNotEmpty ? records.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (타이틀 + [기록 추가] 옐로우 버튼 + [펼치기/간략히 보기] 토글)
          Row(
            children: [
              const Text('📏', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '신체 성장 기록',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.protoHeading,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('baby_add_growth_button'),
                onPressed: widget.onOpenAddGrowthRecord,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text(
                  '기록 추가',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipYellowBg,
                  foregroundColor: AppColors.chipYellowText,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                  elevation: 0,
                ),
              ),
              if (records.length > 1) ...[
                const SizedBox(width: 4),
                TextButton(
                  key: const Key('baby_growth_toggle_button'),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.chipYellowText,
                  ),
                  child: Text(
                    _isExpanded ? '간략히 보기' : '펼치기',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.chipYellowText,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // 2. 아코디언 본문 (간략히 보기: 최근 1건 슬림 바 / 펼치기: 전체 기록)
          if (records.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                '등록된 신체 성장 기록이 없습니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_isExpanded
                  ? _buildSlimGrowthRow(latest!)
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _buildSlimGrowthRow(records[index]),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlimGrowthRow(GrowthRecord record) {
    return InkWell(
      onTap: () => widget.onEditGrowthRecord(record),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              _formatDate(record.date),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 5,
              children: [
                if (record.heightCm != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '키 ${record.heightCm}cm',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                if (record.weightKg != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${record.weightKg}kg',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                if (record.headCircumferenceCm != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '머리 ${record.headCircumferenceCm}cm',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
