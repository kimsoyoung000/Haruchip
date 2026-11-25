import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/design_system/colors.dart';
import 'package:haruchip/features/calendar/widgets/calendar_category_filter_sheet.dart';
import 'package:haruchip/features/categories/data/baby_health_database.dart';
import 'package:haruchip/features/categories/data/category_types.dart';
import 'package:haruchip/features/categories/models/baby_profile.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/widgets/baby_growth_card_widget.dart';
import 'package:haruchip/features/categories/widgets/baby_growth_records_widget.dart';
import 'package:haruchip/features/categories/widgets/baby_health_checkup_widget.dart';
import 'package:haruchip/features/categories/widgets/baby_vaccine_timeline_widget.dart';
import 'package:haruchip/features/categories/widgets/category_onboarding_sheets.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';

void main() {
  group('Solo Removal & Baby Category UX Refactor Tests', () {
    testWidgets('1. 솔로(solo) 카테고리가 프리셋·프로바이더·캘린더 필터에서 영구 제거되었다', (tester) async {
      expect(
        kCategoryTypes.any((c) => c.key == 'solo' || c.labelKo == '솔로'),
        isFalse,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(categoryListProvider.notifier).addCategory(
            categoryKey: 'solo',
            name: '솔로',
            emoji: '🌟',
            colorHex: '#C084FC',
          );
      container.read(categoryListProvider.notifier).addCategory(
            categoryKey: 'baby',
            name: '아기',
            emoji: 'simple_baby_bottle',
            colorHex: '#FDE047',
          );

      final visible = container.read(visibleCategoriesProvider);
      expect(visible.any((c) => c.categoryKey == 'solo'), isFalse);
      expect(visible.any((c) => c.categoryKey == 'baby'), isTrue);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showCalendarCategoryFilterSheet(context),
                  child: const Text('필터 열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('필터 열기'));
      await tester.pumpAndSettle();

      expect(find.text('솔로'), findsNothing);
    });

    testWidgets(
      '2. 아기 온보딩 모달: [수유 텀 없음], 출생시간 CupertinoDatePicker 직행, 혈액형 라운드 바텀시트, 하루칩 옐로우 CTA',
      (tester) async {
        final now = DateTime.now();
        final babyCat = CategoryModel(
          id: 'cat_baby',
          categoryKey: 'baby',
          name: '아기',
          icon: 'simple_baby_bottle',
          createdAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => showBabyOnboardingSheet(
                      context,
                      category: babyCat,
                      ref: ref,
                    ),
                    child: const Text('아기 설정'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('아기 설정'));
        await tester.pumpAndSettle();

        // 수유 텀 없음 칩 확인
        expect(find.text('수유 텀 없음'), findsOneWidget);
        expect(find.text('2.5시간'), findsOneWidget);
        expect(find.text('3.5시간'), findsOneWidget);

        // 하단 설정 완료 버튼 하루칩 옐로우 확인
        final submitBtn = tester.widget<ElevatedButton>(
          find.byKey(const Key('baby_onboarding_submit_button')),
        );
        expect(
          submitBtn.style?.backgroundColor?.resolve(<WidgetState>{}),
          AppColors.chipYellowBg,
        );

        // 출생 시간 필드 탭 -> 즉시 CupertinoDatePicker (Time 모드) 직행
        await tester.ensureVisible(find.byKey(const Key('baby_birth_time_field')));
        await tester.tap(find.byKey(const Key('baby_birth_time_field')));
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoDatePicker), findsOneWidget);

        await tester.tap(find.byKey(const Key('baby_birth_time_done_button')));
        await tester.pumpAndSettle();

        // 혈액형 필드 탭 -> 라운드 화이트 바텀시트 & A형/B형/O형/AB형/미정 확인
        await tester.ensureVisible(find.byKey(const Key('baby_blood_type_field')));
        await tester.tap(find.byKey(const Key('baby_blood_type_field')));
        await tester.pumpAndSettle();
        expect(find.text('혈액형 선택'), findsOneWidget);
        expect(find.text('AB형'), findsOneWidget);
        expect(find.text('미정'), findsWidgets);
      },
    );

    testWidgets(
      '3 & 4. 상단 아기 카드 중복 섹션 버튼 제거 + 예방접종/건강검진/성장기록 간략히 보기 아코디언 및 성장기록 UI 정돈',
      (tester) async {
        final now = DateTime.now();
        final birthDate = now.subtract(const Duration(days: 100));
        final profile = BabyProfile(
          name: '튼튼이',
          birthDate: birthDate,
          feedingIntervalHours: 0,
          feedingIntervalMinutes: 0,
          vaccineDoses: kDefaultVaccineDoses,
          checkupDoses: kDefaultHealthCheckupDoses,
          growthRecords: [
            GrowthRecord(
              id: 'g1',
              date: now.subtract(const Duration(days: 30)),
              heightCm: 58.0,
              weightKg: 5.4,
            ),
            GrowthRecord(
              id: 'g2',
              date: now,
              heightCm: 62.5,
              weightKg: 6.8,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    BabyGrowthCardWidget(
                      profile: profile,
                      onTapEdit: () {},
                      onTapManageSections: () {},
                    ),
                    BabyVaccineTimelineWidget(
                      profile: profile,
                      onToggleVaccine: (_) {},
                      onUpdateVaccine: (_) {},
                    ),
                    BabyHealthCheckupWidget(
                      profile: profile,
                      onToggleCheckup: (_) {},
                    ),
                    BabyGrowthRecordsWidget(
                      profile: profile,
                      onOpenAddGrowthRecord: () {},
                      onEditGrowthRecord: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 상단 카드 내부 '섹션 순서 관리' 중복 버튼 완전 제거 확인
        expect(find.text('섹션 순서 관리'), findsNothing);

        // 3개 롱 섹션 모두 기본 상태 '간략히 보기'(펼치기 버튼 노출)
        expect(find.byKey(const Key('baby_vaccine_toggle_button')), findsOneWidget);
        expect(find.byKey(const Key('baby_checkup_toggle_button')), findsOneWidget);
        expect(find.byKey(const Key('baby_growth_toggle_button')), findsOneWidget);
        expect(find.text('펼치기'), findsNWidgets(3));

        // 성장 기록 내부 안내 문구 제거 & 기록 추가 버튼 하루칩 옐로우 확인
        expect(find.textContaining('항목을 탭하여 수치 및 날짜를 수정'), findsNothing);
        final addGrowthBtn = tester.widget<ElevatedButton>(
          find.byKey(const Key('baby_add_growth_button')),
        );
        expect(
          addGrowthBtn.style?.backgroundColor?.resolve(<WidgetState>{}),
          AppColors.chipYellowBg,
        );

        // 간략히 보기 상태에서는 최신 성장 기록 1건만 표시 (58.0cm 숨김, 62.5cm 노출)
        expect(find.text('키 62.5cm'), findsOneWidget);
        expect(find.text('키 58.0cm'), findsNothing);

        // 성장 기록 펼치기 탭 -> 전체 기록 표시 & '간략히 보기'로 토글
        await tester.ensureVisible(find.byKey(const Key('baby_growth_toggle_button')));
        await tester.tap(find.byKey(const Key('baby_growth_toggle_button')));
        await tester.pumpAndSettle();
        expect(find.text('키 58.0cm'), findsOneWidget);
        expect(find.text('간략히 보기'), findsOneWidget);
      },
    );

    testWidgets(
      '5. 메인 대시보드 아기 카드: 핵심 2개 뱃지(태어난 지 N일째, 생후 N개월 N일차) + 다가오는 접종/검진 D-Day 최대 2개 자동 노출',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final birthDate = today.subtract(const Duration(days: 100));

        final profile = BabyProfile(
          name: '튼튼이',
          birthDate: birthDate,
          vaccineDoses: kDefaultVaccineDoses,
          checkupDoses: kDefaultHealthCheckupDoses,
        );

        final babyCat = CategoryModel(
          id: 'cat_baby',
          categoryKey: 'baby',
          name: '아기',
          icon: 'simple_baby_bottle',
          createdAt: today,
          metadata: {'babyProfile': profile.toJson()},
        );

        final extraCountUp = PlanItem(
          id: 'extra_up',
          title: '첫 뒤집기',
          date: today.subtract(const Duration(days: 10)),
          categoryKey: 'baby',
          displayMode: DdayDisplayMode.daysCount,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    child: CategorySummaryDashboardCard(
                      category: babyCat,
                      countUpItems: [extraCountUp],
                      countDownItems: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 핵심 2개 뱃지만 노출되고 중복 countUp 항목('첫 뒤집기')은 미노출
        expect(find.text('태어난 지 101일째'), findsOneWidget);
        expect(find.textContaining('생후 '), findsOneWidget);
        expect(find.textContaining('첫 뒤집기'), findsNothing);

        // 하단 D-Day 바에 다가오는 접종/검진 일정이 자동 노출됨 (빈 플레이스홀더 미노출)
        expect(find.textContaining('D-'), findsWidgets);
      },
    );
  });
}
