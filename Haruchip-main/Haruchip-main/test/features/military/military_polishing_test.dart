import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/military/models/military_rank.dart';
import 'package:haruchip/features/military/models/military_service.dart';
import 'package:haruchip/features/military/providers/military_provider.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';

void main() {
  group('Military Category Full Polishing Tests', () {
    test('1. 정밀 복무율(소수점 6자리), 호봉/계급 승급, 남은 일과일(주말·공휴일·휴가 제외) 계산 검증', () {
      final enlist = DateTime(2025, 12, 13);
      final discharge = defaultDischargeDate(enlist, MilitaryBranch.army);
      final now = DateTime(2026, 5, 14, 12, 30, 0);

      // 소수점 6자리 실시간 진행률
      final exact = calculateExactServiceProgress(
        enlistDate: enlist,
        dischargeDate: discharge,
        now: now,
      );
      expect(exact, greaterThan(0.25));
      expect(exact, lessThan(0.35));
      expect((exact * 100).toStringAsFixed(6).split('.').last.length, 6);

      // 호봉 정보 (일병 구간 내 호봉 & 다음 달 1일)
      final hobong = calculateHobongInfo(enlist, now: now);
      expect(hobong.currentRank, MilitaryRank.privateFirstClass);
      expect(hobong.currentHobong, greaterThanOrEqualTo(1));
      expect(hobong.nextHobongDate, DateTime(2026, 6, 1));

      // 계급 진급 진행률 (일병 -> 상병)
      final rankProg = calculateRankPromotionProgress(enlist, discharge, now: now);
      expect(rankProg.currentRank, MilitaryRank.privateFirstClass);
      expect(rankProg.nextRank, MilitaryRank.corporal);
      expect(rankProg.progress, greaterThan(0.0));
      expect(rankProg.progress, lessThan(1.0));

      // 남은 일과일: 2026-05-04(월) ~ 2026-05-11(월) 구간 (7일)
      // - 5/5 어린이날(공휴일), 5/9(토), 5/10(일) 제외 -> 평일 4일
      // - 개인 휴가 5/6~5/7 (2일) 추가 제외 -> 일과일 2일
      final workdaysWithoutLeave = calculateRemainingWorkdays(
        dischargeDate: DateTime(2026, 5, 11),
        today: DateTime(2026, 5, 4),
      );
      expect(workdaysWithoutLeave, 4);

      final workdaysWithLeave = calculateRemainingWorkdays(
        dischargeDate: DateTime(2026, 5, 11),
        leaveRanges: [
          (startDate: DateTime(2026, 5, 6), endDate: DateTime(2026, 5, 7)),
        ],
        today: DateTime(2026, 5, 4),
      );
      expect(workdaysWithLeave, 2);
    });

    test('2. 휴가·외박·외출 등록/수정/삭제 시 자동 일수 차감 및 칩 캘린더 연속 일정 동기화', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(militaryServiceProvider.notifier);

      // 4박 5일 정기휴가 추가
      notifier.addLeave(
        MilitaryLeaveRecord(
          id: 'lv1',
          type: MilitaryLeaveType.regular,
          title: '정기휴가',
          startDate: DateTime(2026, 5, 29),
          endDate: DateTime(2026, 6, 2),
        ),
      );

      // 2일 포상휴가 추가
      notifier.addLeave(
        MilitaryLeaveRecord(
          id: 'lv2',
          type: MilitaryLeaveType.reward,
          title: '포상휴가',
          startDate: DateTime(2026, 7, 10),
          endDate: DateTime(2026, 7, 11),
        ),
      );

      // 당일 외출 추가
      notifier.addLeave(
        MilitaryLeaveRecord(
          id: 'lv3',
          type: MilitaryLeaveType.outing,
          title: '외출',
          startDate: DateTime(2026, 6, 15),
          endDate: DateTime(2026, 6, 15),
        ),
      );

      final service = container.read(militaryServiceProvider);
      expect(service.usedRegularLeaveDays, 5);
      expect(service.remainingVacationDays, service.totalVacationDays - 5);
      expect(service.usedRewardLeaveDays, 2);
      expect(
        service.remainingRewardVacationDays,
        service.totalRewardVacationDays - 2,
      );
      expect(service.overnightAndOutingCount, 1);

      // 칩 캘린더(planListProvider)에 5일 연속 일정으로 자동 등록되었는지 확인
      final plans = container.read(planListProvider);
      final syncedRegular = plans.firstWhere((p) => p.id == 'mil-leave-lv1');
      expect(syncedRegular.categoryKey, 'military');
      expect(syncedRegular.date, DateTime(2026, 5, 29));
      expect(syncedRegular.endDate, DateTime(2026, 6, 2));

      // 삭제 시 캘린더에서도 제거
      notifier.deleteLeave('lv1');
      expect(
        container.read(planListProvider).any((p) => p.id == 'mil-leave-lv1'),
        isFalse,
      );
    });

    testWidgets(
      '3. 군대 상세 화면: 실시간 복무율, 6대 지표, 호봉/계급 타임라인, 출타 관리, 복무 설정 및 곰신 초대 공유 모달 동작',
      (tester) async {
        final now = DateTime.now();
        final category = CategoryModel(
          id: 'cat_mil',
          categoryKey: 'military',
          name: '군대 (곰신)',
          icon: 'simple_medal',
          createdAt: now,
          metadata: const {'isInitialized': true},
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: CategoryDetailScreen(category: category),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));

        // 1) 실시간 소수점 6자리 복무율 확인
        final liveText = tester.widget<Text>(
          find.byKey(const Key('military_live_percent_text')),
        );
        expect(RegExp(r'^\d+\.\d{6}%$').hasMatch(liveText.data ?? ''), isTrue);

        // 2) 6대 핵심 복무 지표 확인
        expect(find.text('전체 복무일'), findsOneWidget);
        expect(find.text('현재 복무일'), findsOneWidget);
        expect(find.text('남은 복무일'), findsOneWidget);
        expect(find.text('계급 진급일'), findsOneWidget);
        expect(find.text('남은 일과일'), findsOneWidget);
        expect(find.text('다음 휴가일'), findsOneWidget);

        // 3) 타임라인 & 휴가 통계 요약 바 확인
        expect(find.text('계급 · 호봉 승급 타임라인'), findsOneWidget);
        expect(find.text('남은 정기휴가'), findsOneWidget);
        expect(find.text('남은 포상휴가'), findsOneWidget);
        expect(find.text('외박/외출'), findsOneWidget);

        // 4) 상단 프로필 카드 탭 -> 복무 정보 설정 시트 오픈
        await tester.tap(find.byKey(const Key('military_hero_profile_card')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('복무 정보 설정'), findsOneWidget);
        Navigator.of(tester.element(find.text('복무 정보 설정'))).pop();
        await tester.pump(const Duration(milliseconds: 300));

        // 5) 앱바 [초대/공유] 버튼 탭 -> 곰신 실시간 공유 모달 & 난수 코드 확인
        await tester.tap(find.byKey(const Key('military_share_button')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('곰신 · 군인 실시간 공유'), findsOneWidget);
        final codeText = tester.widget<Text>(
          find.byKey(const Key('military_my_invite_code')),
        );
        expect(
          RegExp(r'^MIL-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(codeText.data ?? ''),
          isTrue,
        );
      },
    );
  });
}
