import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/security/input_sanitizer.dart';
import 'package:haruchip/features/calendar/models/schedule_room.dart';
import 'package:haruchip/features/calendar/providers/schedule_room_provider.dart';
import 'package:haruchip/features/calendar/widgets/room_management_drawer.dart';
import 'package:haruchip/features/friends/models/battle_tag_user.dart';
import 'package:haruchip/features/friends/providers/friend_system_provider.dart';
import 'package:haruchip/features/friends/widgets/friend_management_card.dart';
import 'package:haruchip/features/settings/screens/profile_settings_screen.dart';

void main() {
  group('Member Profile, Chip Color, Alias & Autocomplete Refactor Tests', () {
    test('1. 닉네임 유효성(2~10자, 금칙어/예약어 차단) 및 글로벌 fullHandle 중복 시 자동 난수 재생성', () async {
      // 길이 검증
      expect(HaruInputSanitizer.validateNickname('가'), isNotNull);
      expect(HaruInputSanitizer.validateNickname('   가  '), isNotNull);
      expect(HaruInputSanitizer.validateNickname('일이삼사오육칠팔구십일'), isNotNull);

      // 금칙어/시스템 예약어 차단
      expect(HaruInputSanitizer.validateNickname('운영자12'), isNotNull);
      expect(HaruInputSanitizer.validateNickname('관리자님'), isNotNull);
      expect(HaruInputSanitizer.validateNickname('하루칩공식'), isNotNull);
      expect(HaruInputSanitizer.validateNickname('admin계정'), isNotNull);
      expect(HaruInputSanitizer.validateNickname('시발테스트'), isNotNull);

      // 정상 닉네임 허용
      expect(HaruInputSanitizer.validateNickname('다정'), isNull);
      expect(HaruInputSanitizer.validateNickname('소영'), isNull);

      // 이미 존재하는 fullHandle('소영#7F2K')로 저장 시도 시 태그 자동 재생성으로 고유성 보장
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(friendSystemProvider.notifier)
          .updateMyProfileValidated(nickname: '소영', tag: '7F2K');

      expect(result.ok, isTrue);
      expect(result.tagRegenerated, isTrue);
      expect(result.profile, isNotNull);
      expect(result.profile!.nickname, '소영');
      expect(result.profile!.tag, isNot('7F2K'));
    });

    testWidgets('2. 프로필 수정 즉각 동기화 반영 (ProfileSettingsScreen + 모임 멤버 동기화)', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 프로필 수정 다이얼로그 오픈 -> 새 닉네임 '민수' + 태그 'ABCD' 저장
      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('profile_nickname_input')),
        '민수',
      );
      await tester.enterText(
        find.byKey(const Key('profile_tag_input')),
        'ABCD',
      );
      await tester.tap(find.byKey(const Key('profile_edit_save_btn')));
      await tester.pumpAndSettle();

      // 화면에 즉시 '민수' / '#ABCD' 반영 확인
      expect(find.byKey(const Key('profile_live_nickname')), findsOneWidget);
      expect(find.text('민수'), findsOneWidget);
      expect(find.text('#ABCD'), findsOneWidget);
    });

    testWidgets('3. 모임 서랍 내 [나] 탭 -> 프로필 & 1인 1색 중복 컬러 방어 + 비친구 [+ 친구] & 별명 표시', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const me = RoomMember(
        uid: 'me_uid',
        name: '민수',
        icon: 'simple_chick',
        colorHex: '#FFD1DC',
        isHost: true,
      );
      const other = RoomMember(
        uid: 'other_uid',
        name: '지훈',
        icon: 'simple_bear',
        colorHex: '#FFE4E1',
      );
      const friendMember = RoomMember(
        uid: 'user_soyoung_7f2k',
        name: '소영',
        icon: 'simple_rabbit',
        colorHex: '#FFD8BE',
      );

      final room = ScheduleRoom(
        id: 'room_color_test',
        name: '주말 여행 모임',
        inviteCode: 'HC-TEST01',
        categoryTag: '여행',
        members: const [me, other, friendMember],
        dates: const {},
        events: const [],
        notices: const [],
        votes: const [],
        rounds: const [],
        settlementHistory: const [],
      );

      // 방 등록 및 친구/별명 설정
      final roomsNotifier = container.read(scheduleRoomsProvider.notifier);
      roomsNotifier.state = [room];

      final friendNotifier = container.read(friendSystemProvider.notifier);
      friendNotifier.receiveFriendRequest(
        FriendRequestItem(
          id: 'req-soyoung',
          fromUser: kDiscoverableSampleUsers.first,
          createdAt: DateTime.now(),
        ),
      );
      friendNotifier.acceptFriendRequest('req-soyoung');
      friendNotifier.setFriendAlias('user_soyoung_7f2k', '대학동기');

      // 1인 1색 Provider 레벨 중복 차단 확인
      final blocked = roomsNotifier.updateMemberCustomization(
        roomId: room.id,
        uid: me.uid,
        colorHex: '#FFE4E1', // other가 이미 선점한 컬러
      );
      expect(blocked, isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RoomManagementDrawer(
                room: room,
                myMember: me,
                onSelectTab: (_) {},
                onRoomExited: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 별명이 지정된 친구는 '대학동기 (소영#7F2K)' 형태로 표시
      expect(find.text('대학동기 (소영#7F2K)'), findsOneWidget);

      // 비친구 멤버(other_uid) 우측에 [+ 친구] 버튼 노출 및 요청 전송 동작
      expect(find.byKey(const Key('drawer_add_friend_other_uid')), findsOneWidget);
      await tester.tap(find.byKey(const Key('drawer_add_friend_other_uid')));
      await tester.pumpAndSettle();
      expect(find.text('요청됨'), findsOneWidget);

      // [나] 항목 탭 -> 모임 프로필 & 칩 컬러 설정 모달 오픈
      await tester.tap(find.byKey(const Key('drawer_self_profile_tile')));
      await tester.pumpAndSettle();
      expect(find.text('내 모임 프로필 & 칩 컬러'), findsOneWidget);

      // 다른 멤버가 선점한 컬러(#FFE4E1) 잠금 확인 및 탭 시 안내 토스트 노출
      expect(find.byKey(const Key('chip_color_locked_#FFE4E1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chip_color_locked_#FFE4E1')));
      await tester.pumpAndSettle();
      expect(find.text('이미 다른 멤버가 사용 중인 컬러입니다'), findsOneWidget);
    });

    testWidgets('4. 친구 검색 실시간 자동완성 추천 드롭다운 (2글자 이상, 접두사/태그 매칭 상위 4명) 및 별명 설정', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FriendManagementCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2글자 입력('하루') -> 접두사 일치 추천 드롭다운 노출
      await tester.enterText(
        find.byKey(const Key('friend_search_input')),
        '하루',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friend_autocomplete_dropdown')), findsOneWidget);
      expect(find.text('하루별#ABCD'), findsOneWidget);
      expect(find.text('하루마루#1234'), findsOneWidget);
      expect(find.text('하루코#5678'), findsOneWidget);

      // 태그 포함 입력('하루별#AB') -> 하루별#ABCD로 좁혀짐
      await tester.enterText(
        find.byKey(const Key('friend_search_input')),
        '하루별#AB',
      );
      await tester.pumpAndSettle();
      expect(find.text('하루별#ABCD'), findsOneWidget);
      expect(find.text('하루마루#1234'), findsNothing);

      // 추천 항목 탭 -> 검색창 자동완성 + 프로필 결과 카드 즉시 포커스
      await tester.tap(
        find.byKey(const Key('friend_suggestion_user_harubyeol_abcd')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friend_autocomplete_dropdown')), findsNothing);
      expect(find.text('친구 요청'), findsOneWidget);
    });
  });
}
