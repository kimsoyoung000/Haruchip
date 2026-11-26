import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/models/schedule_room.dart';
import 'package:haruchip/features/calendar/providers/schedule_room_provider.dart';
import 'package:haruchip/features/calendar/screens/schedule_room_detail_screen.dart';
import 'package:haruchip/features/calendar/widgets/month_grid.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

void main() {
  group('Group Calendar Full-Screen & Chip Color Override Tests', () {
    testWidgets(
      '1. 공유 캘린더 상단 참여 멤버 카드 영구 삭제 및 풀스크린 칩 캘린더(MonthGrid) 즉시 배치 검증',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const roomDD = ScheduleRoom(
          id: 'room_dd',
          name: 'ㄷㄷ',
          inviteCode: 'HC-DD01',
          categoryTag: '모임',
          members: [
            RoomMember(
              uid: '하루',
              name: '하루',
              icon: 'simple_chick',
              colorHex: '#FFE699',
              isHost: true,
            ),
          ],
          dates: {},
          events: [],
          notices: [],
          votes: [],
          rounds: [],
          settlementHistory: [],
        );
        container.read(scheduleRoomsProvider.notifier).state = [roomDD];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ScheduleRoomDetailScreen(roomId: 'room_dd'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 상단 '참여 멤버 (1명)' 카드 영구 삭제 확인
        expect(find.textContaining('참여 멤버 ('), findsNothing);
        // 풀스크린 캘린더 컨테이너 + MonthGrid 즉시 노출 확인
        expect(
          find.byKey(const Key('room_fullscreen_calendar_container')),
          findsOneWidget,
        );
        expect(find.byType(MonthGrid), findsOneWidget);
      },
    );

    testWidgets(
      '2. 모임 내부 일정 등록 모달: 카테고리 필드 제거, 현재 모임 고정, 타 모임방만 선택 칩 노출 검증',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const roomDD = ScheduleRoom(
          id: 'room_dd',
          name: 'ㄷㄷ',
          inviteCode: 'HC-DD01',
          categoryTag: '모임',
          members: [
            RoomMember(
              uid: '하루',
              name: '하루',
              icon: 'simple_chick',
              colorHex: '#FFE699',
              isHost: true,
            ),
          ],
          dates: {},
          events: [],
          notices: [],
          votes: [],
          rounds: [],
          settlementHistory: [],
        );
        const roomRR = ScheduleRoom(
          id: 'room_rr',
          name: 'ㄹㄹ',
          inviteCode: 'HC-RR01',
          categoryTag: '모임',
          members: [
            RoomMember(
              uid: '하루',
              name: '하루',
              icon: 'simple_chick',
              colorHex: '#A9DEF9',
              isHost: true,
            ),
          ],
          dates: {},
          events: [],
          notices: [],
          votes: [],
          rounds: [],
          settlementHistory: [],
        );
        container.read(scheduleRoomsProvider.notifier).state = [roomDD, roomRR];

        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: AddEventBottomSheet(
                  categoryKey: 'group',
                  initialRoomId: 'room_dd',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 모임 일정 추가 타이틀 & 카테고리 드롭다운 완전 삭제 확인
        expect(find.text('모임 일정 추가'), findsOneWidget);
        expect(find.byKey(const Key('add_event_category_selector')), findsNothing);

        // 현재 모임방(ㄷㄷ)은 고정 뱃지, 선택 칩에는 타 모임방(ㄹㄹ)만 노출
        expect(
          find.byKey(const Key('add_event_current_room_fixed_badge')),
          findsOneWidget,
        );
        expect(find.text('ㄷㄷ (현재 모임 고정)'), findsOneWidget);
        expect(find.byKey(const Key('add_event_room_chip_room_dd')), findsNothing);
        expect(find.byKey(const Key('add_event_room_chip_room_rr')), findsOneWidget);
      },
    );

    testWidgets(
      '3. 다중 모임방 동시 연동 시 모임별 작성자 칩 컬러(ㄷㄷ=#FFE699, ㄹㄹ=#A9DEF9) 강제 오버라이딩 검증',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final today = DateTime.now();
        final dateOnly = DateTime(today.year, today.month, today.day);

        const roomDD = ScheduleRoom(
          id: 'room_dd',
          name: 'ㄷㄷ',
          inviteCode: 'HC-DD01',
          categoryTag: '모임',
          members: [
            RoomMember(
              uid: '하루',
              name: '하루',
              icon: 'simple_chick',
              colorHex: '#FFE699', // 노란색
              isHost: true,
            ),
          ],
          dates: {},
          events: [],
          notices: [],
          votes: [],
          rounds: [],
          settlementHistory: [],
        );
        const roomRR = ScheduleRoom(
          id: 'room_rr',
          name: 'ㄹㄹ',
          inviteCode: 'HC-RR01',
          categoryTag: '모임',
          members: [
            RoomMember(
              uid: '하루',
              name: '하루',
              icon: 'simple_chick',
              colorHex: '#A9DEF9', // 파란색
              isHost: true,
            ),
          ],
          dates: {},
          events: [],
          notices: [],
          votes: [],
          rounds: [],
          settlementHistory: [],
        );

        final roomsNotifier = container.read(scheduleRoomsProvider.notifier);
        roomsNotifier.state = [roomDD, roomRR];

        // 1개 일정을 두 모임방(ㄷㄷ, ㄹㄹ)에 동시 Batch 연동
        await roomsNotifier.addRoomEventToMultipleRooms(
          roomIds: const ['room_dd', 'room_rr'],
          baseEvent: RoomSharedEvent(
            id: 'shared-ev-1',
            roomId: 'room_dd',
            title: '주말 브런치',
            authorUid: '하루',
            date: dateOnly,
            isAllDay: true,
          ),
        );

        // 1) ㄷㄷ 모임 캘린더 -> 작성자의 ㄷㄷ 칩 컬러(#FFE699)로 오버라이딩
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ScheduleRoomDetailScreen(roomId: 'room_dd'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final gridDD = tester.widget<MonthGrid>(find.byType(MonthGrid));
        final evInDD = gridDD.allEvents!.firstWhere((e) => e.id == 'shared-ev-1');
        expect(evInDD.colorHex, '#FFE699');

        // 2) ㄹㄹ 모임 캘린더 -> 동일 일정이 작성자의 ㄹㄹ 칩 컬러(#A9DEF9)로 오버라이딩
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ScheduleRoomDetailScreen(roomId: 'room_rr'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final gridRR = tester.widget<MonthGrid>(find.byType(MonthGrid));
        final evInRR = gridRR.allEvents!.firstWhere((e) => e.id == 'shared-ev-1');
        expect(evInRR.colorHex, '#A9DEF9');
      },
    );
  });
}
