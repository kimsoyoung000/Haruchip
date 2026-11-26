import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/friends/models/battle_tag_user.dart';
import 'package:haruchip/features/friends/providers/friend_system_provider.dart';
import 'package:haruchip/features/friends/widgets/friend_management_card.dart';
import 'package:haruchip/features/friends/widgets/partner_soft_dropdown_button.dart';
import 'package:haruchip/features/settings/screens/profile_settings_screen.dart';

void main() {
  group('Battle-Tag Friend System & Soft Partner Share Tests', () {
    test('1. 배틀태그(닉네임#TAG) 자동 생성, 수정, 검색, 수락/거절, 삭제, 차단/해제 로직 검증', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(friendSystemProvider.notifier);
      final initial = container.read(friendSystemProvider).myProfile;
      expect(isValidBattleTag(initial.tag), isTrue);
      expect(initial.fullHandle, '${initial.nickname}#${initial.tag}');

      // 닉네임 및 태그 수정
      expect(notifier.updateMyProfile(nickname: '지민', tag: 'AB12'), isTrue);
      expect(container.read(friendSystemProvider).myProfile.fullHandle, '지민#AB12');
      expect(notifier.updateMyProfile(tag: 'invalid!'), isFalse);

      // 닉네임#태그 검색
      final found = await notifier.searchByFullHandle('소영#7F2K');
      expect(found, isNotNull);
      expect(found!.fullHandle, '소영#7F2K');

      // 친구 요청 전송
      await notifier.sendFriendRequest(found);
      expect(container.read(friendSystemProvider).hasSentRequest(found.uid), isTrue);

      // 받은 친구 요청 수락
      notifier.receiveFriendRequest(
        FriendRequestItem(
          id: 'req_1',
          fromUser: found,
          createdAt: DateTime.now(),
        ),
      );
      expect(container.read(friendSystemProvider).incomingRequests.length, 1);

      notifier.acceptFriendRequest('req_1');
      expect(container.read(friendSystemProvider).incomingRequests, isEmpty);
      expect(container.read(friendSystemProvider).isFriend(found.uid), isTrue);

      // 카테고리 파트너 연결 -> partnerUid 상호 등록
      container.read(categoryListProvider.notifier).addCategory(
            categoryKey: 'couple',
            name: '커플',
            emoji: 'simple_heart',
            colorHex: '#FF8DA1',
          );
      await notifier.connectCategoryPartner(
        categoryKey: 'couple',
        partner: found,
      );
      expect(
        container.read(friendSystemProvider).partnerFor('couple')?.partner.uid,
        found.uid,
      );
      final coupleCat = container
          .read(categoryListProvider)
          .firstWhere((c) => c.categoryKey == 'couple');
      expect(coupleCat.metadata?['partnerUid'], found.uid);

      // 차단 -> 친구 및 파트너 연결 해제 후 차단 목록으로 이동
      notifier.blockUser(found);
      expect(container.read(friendSystemProvider).isFriend(found.uid), isFalse);
      expect(container.read(friendSystemProvider).isBlocked(found.uid), isTrue);
      expect(container.read(friendSystemProvider).partnerFor('couple'), isNull);

      // 차단 해제
      notifier.unblockUser(found.uid);
      expect(container.read(friendSystemProvider).isBlocked(found.uid), isFalse);
    });

    testWidgets(
      '2. 상단 소프트 드롭다운(PartnerSoftDropdownButton): 미연결 -> 친구 초대 연결 -> 실시간 동기화 중 💚 -> 연결 해제',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const friend = BattleTagUser(
          uid: 'user_soyoung_7f2k',
          nickname: '소영',
          tag: '7F2K',
          avatarIcon: 'simple_rabbit',
        );
        container.read(friendSystemProvider.notifier).receiveFriendRequest(
              FriendRequestItem(
                id: 'r1',
                fromUser: friend,
                createdAt: DateTime.now(),
              ),
            );
        container.read(friendSystemProvider.notifier).acceptFriendRequest('r1');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('커플'),
                  actions: const [
                    PartnerSoftDropdownButton(
                      categoryKey: 'couple',
                      categoryName: '커플',
                    ),
                  ],
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );

        // 미연결 상태에서 드롭다운 오픈
        await tester.tap(find.byKey(const Key('partner_share_dropdown_button_couple')));
        await tester.pumpAndSettle();
        expect(find.text('아직 함께하는 파트너가 없어요'), findsOneWidget);
        expect(find.text('내 친구에서 초대하기'), findsOneWidget);

        // 내 친구에서 초대하기 -> 친구 선택 바텀시트 -> 연결
        await tester.tap(find.byKey(const Key('partner_invite_from_friends_btn')));
        await tester.pumpAndSettle();
        expect(find.text('소영#7F2K'), findsOneWidget);
        await tester.tap(find.text('연결'));
        await tester.pumpAndSettle();

        // 연결 완료 후 다시 드롭다운 오픈 -> '실시간 동기화 중 💚' 노출
        await tester.tap(find.byKey(const Key('partner_share_dropdown_button_couple')));
        await tester.pumpAndSettle();
        expect(find.text('실시간 동기화 중 💚'), findsOneWidget);

        // 파트너 프로필 탭 -> 연결 해제
        await tester.tap(find.byKey(const Key('partner_connected_profile_row')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('partner_disconnect_btn')));
        await tester.pumpAndSettle();

        expect(container.read(friendSystemProvider).partnerFor('couple'), isNull);
      },
    );

    testWidgets(
      '3. 설정 탭 [친구 관리] 카드: 배틀태그 검색 -> 친구 요청 및 [계정 및 보안] 상단 배치 확인',
      (tester) async {
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

        await tester.enterText(
          find.byKey(const Key('friend_search_input')),
          '소영#7F2K',
        );
        await tester.tap(find.byKey(const Key('friend_search_button')));
        await tester.pumpAndSettle();

        expect(find.text('소영#7F2K'), findsWidgets);
        expect(find.byKey(const Key('friend_send_request_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('friend_send_request_button')));
        await tester.pumpAndSettle();
        expect(find.text('요청 완료'), findsOneWidget);
      },
    );

    testWidgets('4. ProfileSettingsScreen 최상단 프로필 카드 바로 밑에 [내 친구 N명] 타일이 노출되고 터치 시 친구 관리 모달이 열린다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProfileSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final friendTile = find.byKey(const Key('settings_friends_summary_tile'));
      expect(friendTile, findsOneWidget);
      expect(find.text('내 친구 0명'), findsOneWidget);

      await tester.tap(friendTile);
      await tester.pumpAndSettle();
      expect(find.text('친구 관리'), findsOneWidget);
      expect(find.byKey(const Key('friend_search_input')), findsOneWidget);
    });
  });
}
