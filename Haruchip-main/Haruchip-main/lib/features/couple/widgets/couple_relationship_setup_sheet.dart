import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/couple_relationship.dart';
import '../providers/couple_provider.dart';

/// 커플 "만난 날 및 재회 설정" 컴팩트 화이트 바텀시트
///
/// - 커플 상세 화면과 온보딩/카테고리 추가 흐름이 함께 사용한다.
/// - [isInitialized]가 `false`이면 시작일 기본값을 무조건 오늘 날짜(Today)로 열어
///   휠 피커가 과거 목업 날짜(2024년 등)로 잡히지 않도록 보장한다.
/// - 모든 날짜 필드(시작일/이별일/재회일) 터치 시 중간 팝업 없이 인라인 휠 피커로 직행한다.
Future<bool> showCoupleRelationshipSetupSheet(
  BuildContext context,
  WidgetRef ref, {
  bool isInitialized = true,
}) async {
  final couple = ref.read(coupleProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final isLegacyMockStart = !isInitialized ||
      (couple.startDate.year == 2024 &&
          couple.startDate.month == 5 &&
          couple.startDate.day == 14 &&
          !isInitialized);

  DateTime tempStartDate = isLegacyMockStart ? today : couple.startDate;
  List<ReunionPeriod> tempReunions =
      couple.reunions.map((r) => r.copyWith()).toList();

  String formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final mediaQuery = MediaQuery.of(context);
          final currentNow = DateTime.now();
          final currentToday =
              DateTime(currentNow.year, currentNow.month, currentNow.day);
          final totalElapsed = currentToday
              .difference(DateTime(
                tempStartDate.year,
                tempStartDate.month,
                tempStartDate.day,
              ))
              .inDays;
          final breakupDays =
              tempReunions.fold<int>(0, (sum, r) => sum + r.length.inDays);
          final previewDays = (totalElapsed - breakupDays).clamp(0, 99999);

          return Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: mediaQuery.size.height * 0.72,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 드래그 핸들
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // 헤더
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 2, 10, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                '만난 날 및 재회 설정',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.protoHeading,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 현재 연애 일수 프리뷰 카드 (컴팩트 무테두리)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Color(0xFFFF7A9C),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      '현재 연애 일수',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7D6B70),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${previewDays + 1}일',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFD6336C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 섹션 1: 처음 만난 날 (시작일) -> 즉시 인라인 휠 피커 직행
                              const Text(
                                '처음 만난 날 (시작일)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.protoHeading,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                key: const Key('couple_start_date_field'),
                                onTap: () async {
                                  final picked = await showHaruDatePicker(
                                    context,
                                    initialDate: tempStartDate,
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime(2100),
                                    title: '처음 만난 날',
                                  );
                                  if (picked != null) {
                                    setModalState(() => tempStartDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatDate(tempStartDate),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.protoHeading,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: AppColors.chipYellowText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // 섹션 2: 이별 / 재회 이력 (컴팩트 축약)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '이별 / 재회 이력',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.protoHeading,
                                    ),
                                  ),
                                  TextButton(
                                    key: const Key('couple_add_reunion_button'),
                                    onPressed: () {
                                      setModalState(() {
                                        tempReunions.add(
                                          ReunionPeriod(
                                            breakupDate: currentToday,
                                            reuniteDate: currentToday,
                                          ),
                                        );
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppColors.chipYellowText,
                                    ),
                                    child: const Text(
                                      '+ 재회 추가',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: AppColors.chipYellowText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '이별 기간만큼 총 연애 일수에서 제외됩니다.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 8),

                              if (tempReunions.isEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '등록된 이별/재회 기간이 없습니다.',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else
                                for (int i = 0; i < tempReunions.length; i++)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '기간 #${i + 1}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: Color(0xFFEF4444),
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                setModalState(() {
                                                  tempReunions.removeAt(i);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            // 이별일 -> 인라인 휠 피커 직행
                                            Expanded(
                                              child: InkWell(
                                                onTap: () async {
                                                  final picked =
                                                      await showHaruDatePicker(
                                                    context,
                                                    initialDate: tempReunions[i]
                                                        .breakupDate,
                                                    firstDate: DateTime(1950),
                                                    lastDate: DateTime(2100),
                                                    title: '이별일 선택',
                                                  );
                                                  if (picked != null) {
                                                    setModalState(() {
                                                      tempReunions[i] =
                                                          tempReunions[i]
                                                              .copyWith(
                                                        breakupDate: picked,
                                                      );
                                                    });
                                                  }
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        '이별일',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Color(0xFF9CA3AF),
                                                        ),
                                                      ),
                                                      Text(
                                                        formatDate(
                                                            tempReunions[i]
                                                                .breakupDate),
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .protoHeading,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6),
                                              child: Text(
                                                '~',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ),
                                            // 재회일 -> 인라인 휠 피커 직행
                                            Expanded(
                                              child: InkWell(
                                                onTap: () async {
                                                  final picked =
                                                      await showHaruDatePicker(
                                                    context,
                                                    initialDate: tempReunions[i]
                                                            .reuniteDate ??
                                                        currentToday,
                                                    firstDate: DateTime(1950),
                                                    lastDate: DateTime(2100),
                                                    title: '재회일 선택',
                                                  );
                                                  if (picked != null) {
                                                    setModalState(() {
                                                      tempReunions[i] =
                                                          tempReunions[i]
                                                              .copyWith(
                                                        reuniteDate: picked,
                                                      );
                                                    });
                                                  }
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        '재회일',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Color(0xFF9CA3AF),
                                                        ),
                                                      ),
                                                      Text(
                                                        tempReunions[i]
                                                                    .reuniteDate !=
                                                                null
                                                            ? formatDate(
                                                                tempReunions[i]
                                                                    .reuniteDate!)
                                                            : '미재회',
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .protoHeading,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      // 하단 설정 완료 버튼 (하루칩 시그니처 웜 파스텔 옐로우 #FFE699 + 다크 브라운 #3A2E1A)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const Key('couple_setup_submit_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.chipYellowBg,
                              foregroundColor: AppColors.chipYellowText,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              ref
                                  .read(coupleProvider.notifier)
                                  .updateRelationship(
                                    startDate: tempStartDate,
                                    reunions: tempReunions,
                                  );
                              Navigator.pop(ctx, true);
                            },
                            child: const Text(
                              '설정 완료',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.chipYellowText,
                              ),
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
        },
      );
    },
  );
  return saved == true;
}
