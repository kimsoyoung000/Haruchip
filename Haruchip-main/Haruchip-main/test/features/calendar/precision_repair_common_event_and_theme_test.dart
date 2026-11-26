import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/security/input_sanitizer.dart';
import 'package:haruchip/design_system/colors.dart';
import 'package:haruchip/design_system/layout_tokens.dart';
import 'package:haruchip/features/calendar/models/schedule_room.dart';
import 'package:haruchip/features/calendar/providers/schedule_room_provider.dart';
import 'package:haruchip/features/calendar/screens/schedule_room_detail_screen.dart';
import 'package:haruchip/features/calendar/widgets/month_grid.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';

void main() {
  group('Precision Repair: Raw Icon Fix, Nickname, Drawer, Common Event Color & Pastel Theme', () {
    test(
      '1. 닉네임 금칙어 필터: 하루칩 여행자 허용, 운영자/관리자/admin/root 및 비속어 차단',
      () {
        expect(HaruInputSanitizer.validateNickname('하루칩 여행자'), isNull);
        expect(HaruInputSanitizer.validateNickname('하루칩'), isNull);
        expect(HaruInputSanitizer.validateNickname('운영자'), isNotNull);
        expect(HaruInputSanitizer.validateNickname('관리자'), isNotNull);
        expect(HaruInputSanitizer.validateNickname('admin'), isNotNull);
        expect(HaruInputSanitizer.validateNickname('root'), isNotNull);
      },
    );

    testWidgets(
      '2. 모임 상세: 햄버거(☰) 영구 삭제 & 단일 서랍 버튼, simple_star 원시 텍스트 미노출, 1인 vs 2인 공통 일정 컬러 분리',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final today = DateTime.now();
        final dateOnly = DateTime(today.year, today.month, today.day);

        final testRoom = ScheduleRoom(
          id: 'room_common',
          name: '주말 크루',
          inviteCode: 'HC-CM01',
          categoryTag: '친목',
          sharedEventColorHex: '#E4C1F9', // 공통 모임 대표 컬러 (라벤더)
          members: const [
            RoomMember(
              uid: '하루',
              name: '하루',
              icon: 'simple_star',
              colorHex: '#FFE699', // 개인 칩 컬러 (옐로우)
              isHost: true,
            ),
            RoomMember(
              uid: '민수',
              name: '민수',
              icon: 'simple_dog',
              colorHex: '#A9DEF9',
            ),
          ],
          dates: const {},
          events: [
            // 1인 개인 일정 -> 개인 칩 컬러(#FFE699)
            RoomSharedEvent(
              id: 'ev-solo',
              roomId: 'room_common',
              title: '개인 헬스장',
              authorUid: '하루',
              date: dateOnly,
              isAllDay: true,
              participantUids: const ['하루'],
              isSharedGroupEvent: false,
            ),
            // 2인 이상 공통 일정 -> 공통 모임 대표 컬러(#E4C1F9)
            RoomSharedEvent(
              id: 'ev-group',
              roomId: 'room_common',
              title: '크루 정기 모임',
              authorUid: '하루',
              date: dateOnly,
              isAllDay: true,
              participantUids: const ['하루', '민수'],
              isSharedGroupEvent: true,
            ),
          ],
          notices: const [],
          votes: const [],
          rounds: const [],
          settlementHistory: const [],
        );

        container.read(scheduleRoomsProvider.notifier).state = [testRoom];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ScheduleRoomDetailScreen(roomId: 'room_common'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 햄버거(Icons.menu_rounded) 영구 삭제 & 단일 서랍 버튼 확인
        expect(find.byIcon(Icons.menu_rounded), findsNothing);
        expect(find.byKey(const Key('open_room_drawer_button')), findsOneWidget);

        // 'simple_star' 원시 키 텍스트가 화면 어디에도 노출되지 않는지 확인
        expect(find.textContaining('simple_star'), findsNothing);
        expect(find.textContaining('simple_dog'), findsNothing);

        // MonthGrid 내 컬러 검증: 1인=#FFE699, 2인 공통=#E4C1F9
        final grid = tester.widget<MonthGrid>(find.byType(MonthGrid));
        final soloEv = grid.allEvents!.firstWhere((e) => e.id == 'ev-solo');
        final groupEv = grid.allEvents!.firstWhere((e) => e.id == 'ev-group');
        expect(soloEv.colorHex, '#FFE699');
        expect(groupEv.colorHex, '#E4C1F9');

        // 서랍 오픈 -> [공통 모임 대표 컬러] 팔레트 변경 시 즉시 반영 확인
        await tester.tap(find.byKey(const Key('open_room_drawer_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('drawer_shared_event_color_section')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('drawer_shared_color_#B8E0D2')));
        await tester.pumpAndSettle();

        final updatedRoom = container
            .read(scheduleRoomsProvider)
            .firstWhere((r) => r.id == 'room_common');
        expect(updatedRoom.sharedEventColorHex, '#B8E0D2');
      },
    );

    test(
      '3. 전역 배경(#F8F9FA) 및 9대 카테고리 고유 파스텔 팔레트 복구/보존 검증',
      () {
        expect(AppColors.cleanCanvasBg, const Color(0xFFF8F9FA));
        expect(AppColors.protoBackground, const Color(0xFFF8F9FA));
        expect(AppLayoutTokens.luxuryCardShadow.first.color, const Color(0x08000000));
        expect(AppLayoutTokens.luxuryCardShadow.first.blurRadius, 10.0);
        expect(AppLayoutTokens.luxuryCardShadow.first.offset, const Offset(0, 3));

        expect(CategoryThemePalette.forCategoryKey('couple').bg, const Color(0xFFFFF0F2));
        expect(CategoryThemePalette.forCategoryKey('baby').bg, const Color(0xFFFFF9E6));
        expect(CategoryThemePalette.forCategoryKey('military').bg, const Color(0xFFF0F7F2));
        expect(CategoryThemePalette.forCategoryKey('fandom').bg, const Color(0xFFFEFDE8));
        expect(CategoryThemePalette.forCategoryKey('pet').bg, const Color(0xFFFFF4EC));
        expect(CategoryThemePalette.forCategoryKey('exam').bg, const Color(0xFFF0F6FF));
        expect(CategoryThemePalette.forCategoryKey('wedding').bg, const Color(0xFFF9F4FC));
        expect(CategoryThemePalette.forCategoryKey('travel').bg, const Color(0xFFF0FAF9));
        expect(CategoryThemePalette.forCategoryKey('goal').bg, const Color(0xFFF5F2FA));
        expect(CategoryThemePalette.forCategoryKey('routine').bg, const Color(0xFFF5F2FA));
      },
    );
  });
}
