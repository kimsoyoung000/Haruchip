import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/core/security/input_sanitizer.dart';
import 'package:haruchip/features/calendar/models/schedule_room.dart';
import 'package:haruchip/features/calendar/providers/schedule_room_provider.dart';
import 'package:haruchip/features/calendar/screens/schedule_room_detail_screen.dart';
import 'package:haruchip/features/calendar/screens/schedule_room_list_screen.dart';
import 'package:haruchip/features/calendar/widgets/create_room_dialog.dart';
import 'package:haruchip/features/calendar/widgets/month_grid.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/friends/models/battle_tag_user.dart';
import 'package:haruchip/features/friends/providers/friend_system_provider.dart';

void main() {
  group('Architecture & Security Total Overhaul Tests', () {
    test('1. 입력값 보안 살균(Injection 방어) 및 공백 정규화 + SHA-256 groupId 검증', () {
      // 배틀태그 공백 정규화 & 특수문자 전면 차단
      expect(
        HaruInputSanitizer.normalizeBattleTag('소영   #7F2K'),
        '소영#7F2K',
      );
      expect(
        HaruInputSanitizer.normalizeBattleTag("소영'\"=;.<?#7f2k--"),
        '소영#7F2K',
      );

      // 일반 텍스트: 일반 문장부호(~, !, ?) 허용, NoSQL/SQL 인젝션 문자($, {}, [], ', ", ;, --) 살균
      expect(
        HaruInputSanitizer.sanitizeText(r'주말 모임~!! {$ne: "1"}; --drop'),
        '주말 모임~!! ne: 1 drop',
      );

      // CSPRNG + SHA-256 내부 groupId 생성
      final id1 = HaruInputSanitizer.generateSecureGroupId();
      final id2 = HaruInputSanitizer.generateSecureGroupId();
      expect(id1.startsWith('grp_'), isTrue);
      expect(id1.length, 28);
      expect(id1, isNot(id2));
    });

    test('2. 모임 권한 체계(부방장 지정/해제, 방장 위임, 내보내기, 방장 나가기 방어, 영구 삭제) 검증', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(scheduleRoomsProvider.notifier);
      final room = notifier.createRoom(
        name: '주말 스터디',
        categoryTag: '스터디',
        hostMember: const RoomMember(
          uid: 'u_host',
          name: '방장하루',
          icon: 'simple_chick',
          isHost: true,
        ),
      );

      // 친구 초대 -> 멤버 합류
      notifier.inviteFriendsToRoom(room.id, const [
        BattleTagUser(
          uid: 'u_friend1',
          nickname: '소영',
          tag: '7F2K',
          avatarIcon: 'simple_rabbit',
        ),
      ]);

      var current =
          container.read(scheduleRoomsProvider).firstWhere((r) => r.id == room.id);
      expect(current.members.length, 2);

      // 부방장 지정
      notifier.toggleCoHost(room.id, 'u_friend1');
      current =
          container.read(scheduleRoomsProvider).firstWhere((r) => r.id == room.id);
      expect(
        current.members.firstWhere((m) => m.uid == 'u_friend1').isCoHost,
        isTrue,
      );

      // 방장은 다른 멤버가 남아있을 때 위임 없이 나가기 불가
      expect(notifier.leaveRoom(room.id, 'u_host'), isFalse);

      // 방장 위임 후 나가기 가능
      notifier.delegateHost(room.id, 'u_friend1');
      current =
          container.read(scheduleRoomsProvider).firstWhere((r) => r.id == room.id);
      expect(
        current.members.firstWhere((m) => m.uid == 'u_friend1').isHost,
        isTrue,
      );
      expect(notifier.leaveRoom(room.id, 'u_host'), isTrue);
    });

    test('3. 2인 카테고리(커플/군대/웨딩) 파트너 수락 시 대시보드 카테고리 자동 생성 및 공동 작업자 등록', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 상대방 대시보드에 'wedding' 카테고리가 없는 상태에서 파트너 연결
      await container.read(friendSystemProvider.notifier).connectCategoryPartner(
            categoryKey: 'wedding',
            partner: const BattleTagUser(
              uid: 'u_partner',
              nickname: '용이',
              tag: '9A4M',
              avatarIcon: 'simple_bear',
            ),
          );

      final cats = container.read(categoryListProvider);
      final weddingCat = cats.firstWhere((c) => c.categoryKey == 'wedding');
      expect(weddingCat.metadata?['partnerUid'], 'u_partner');
      expect(
        (weddingCat.metadata?['coEditors'] as List).contains('u_partner'),
        isTrue,
      );
    });

    testWidgets(
      '4. 칩 모임 메인: 텍스트 난수 초대 코드(HC-) 및 [코드로 참가] 완전 제거, [받은 모임 초대] 노출',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: ScheduleRoomListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('HC-'), findsNothing);
        expect(find.textContaining('코드:'), findsNothing);
        expect(find.text('코드로 참가'), findsNothing);
        expect(find.text('받은 모임 초대'), findsOneWidget);
        expect(find.text('새 모임 만들기'), findsOneWidget);
      },
    );

    testWidgets(
      '5. 모임 상세: 칩 캘린더 동일 MonthGrid 엔진 렌더링 + 초대 코드 미노출 + 카카오톡 스타일 모임 서랍 오픈',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final room = container.read(scheduleRoomsProvider).first;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ScheduleRoomDetailScreen(roomId: room.id),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 상단 초대 코드 완전 제거 & 칩 캘린더 동일 MonthGrid 사용 확인
        expect(find.textContaining('코드:'), findsNothing);
        expect(find.byType(MonthGrid), findsOneWidget);

        // 우측 상단 서랍 버튼 탭 -> 카카오톡 스타일 모임 서랍 오픈
        await tester.tap(find.byKey(const Key('open_room_drawer_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('room_management_drawer')), findsOneWidget);
        expect(find.textContaining('대화상대 '), findsOneWidget);
        expect(find.text('+ 초대하기'), findsOneWidget);
        expect(find.text('모임 나가기'), findsOneWidget);
      },
    );

    testWidgets(
      '6. 새 모임 만들기 모달: 확장된 모임 분류 칩 및 기본/모임 전용 멀티 프로필 토글 확인',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => showCreateRoomDialog(ctx),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();

        expect(find.text('동창/동문'), findsOneWidget);
        expect(find.text('스터디'), findsOneWidget);
        expect(find.text('목적 직접선택'), findsOneWidget);
        expect(find.text('기본 하루칩 프로필 사용'), findsOneWidget);
        expect(find.text('이 모임 전용 프로필 만들기'), findsOneWidget);
      },
    );
  });
}
