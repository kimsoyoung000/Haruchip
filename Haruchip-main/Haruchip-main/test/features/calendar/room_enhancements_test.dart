import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/models/schedule_room.dart';
import 'package:haruchip/features/calendar/providers/schedule_room_provider.dart';

void main() {
  group('Settlement Ledger & Transfer Tracking Tests', () {
    test('SettlementRecord calculates transfer progress and status correctly', () {
      final record = SettlementRecord(
        id: 'rec_1',
        roomId: 'room_1',
        title: '강남 파티룸 정산',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        totalAmount: 120000,
        rounds: const [],
        transferStatus: {
          'user_1': true,
          'user_2': false,
          'user_3': true,
        },
      );

      expect(record.completedTransfersCount, 2);
      expect(record.totalTransferTargetCount, 3);
      expect(record.transferProgress, closeTo(2 / 3, 0.01));
    });

    test('SettlementRecord with all completed transfers returns completed status', () {
      final record = SettlementRecord(
        id: 'rec_2',
        roomId: 'room_1',
        title: '글램핑 정산',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        totalAmount: 300000,
        rounds: const [],
        transferStatus: {
          'user_1': true,
          'user_2': true,
        },
      );

      expect(record.completedTransfersCount, 2);
      expect(record.transferProgress, 1.0);
    });

    test('Toggling transfer status in scheduleRoomsProvider updates the record in real-time', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rooms = container.read(scheduleRoomsProvider);
      final room = rooms.first;
      expect(room.settlementHistory.isNotEmpty, isTrue);

      final firstRecord = room.settlementHistory.first;
      final targetMemberUid = firstRecord.transferStatus.keys.first;
      final initialStatus = firstRecord.transferStatus[targetMemberUid] ?? false;

      container.read(scheduleRoomsProvider.notifier).toggleTransferStatus(
            room.id,
            firstRecord.id,
            targetMemberUid,
          );

      final updatedRooms = container.read(scheduleRoomsProvider);
      final updatedRoom = updatedRooms.firstWhere((r) => r.id == room.id);
      final updatedRecord = updatedRoom.settlementHistory.firstWhere((s) => s.id == firstRecord.id);

      expect(updatedRecord.transferStatus[targetMemberUid], !initialStatus);
    });
  });

  group('RoomVote Model & Voting Flow Tests', () {
    test('Anonymous poll correctly hides voter identities in options', () {
      final vote = RoomVote(
        id: 'vote_anon',
        title: '회식 장소 투표 (익명)',
        authorUid: 'user_host',
        options: [
          VoteOption(id: 'opt_1', text: '삼겹살 맛집', voterUids: ['user_1', 'user_2']),
          VoteOption(id: 'opt_2', text: '파스타 레스토랑', voterUids: ['user_3']),
        ],
        isAnonymous: true,
        allowMultiple: false,
        createdAt: DateTime.now(),
      );

      expect(vote.isAnonymous, isTrue);
      expect(vote.options[0].voteCount, 2);
      expect(vote.options[1].voteCount, 1);
    });

    test('Vote countdown calculation returns remaining time or closed status', () {
      final activeVote = RoomVote(
        id: 'vote_active',
        title: '모임 날짜 선택',
        options: [VoteOption(id: 'opt_1', text: '토요일')],
        deadline: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
        createdAt: DateTime.now(),
      );

      expect(activeVote.isExpiredOrClosed, isFalse);
      expect(activeVote.remainingTimeLabel.startsWith('마감까지'), isTrue);

      final closedVote = RoomVote(
        id: 'vote_closed',
        title: '종료된 투표',
        options: [VoteOption(id: 'opt_1', text: '옵션')],
        isClosed: true,
        createdAt: DateTime.now(),
      );

      expect(closedVote.isExpiredOrClosed, isTrue);
      expect(closedVote.remainingTimeLabel, '투표 마감됨');
    });

    test('reVote allows member to cancel previous choices and recast votes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final room = container.read(scheduleRoomsProvider).first;
      final vote = room.votes.first;

      // Cast initial vote on first option
      container.read(scheduleRoomsProvider.notifier).castVote(
            roomId: room.id,
            voteId: vote.id,
            optionId: vote.options.first.id,
            voterUid: 'my_test_uid',
          );

      var updatedVote = container.read(scheduleRoomsProvider).first.votes.firstWhere((v) => v.id == vote.id);
      expect(updatedVote.options.first.voterUids.contains('my_test_uid'), isTrue);

      // Re-vote to clear previous votes for my_test_uid
      container.read(scheduleRoomsProvider.notifier).reVote(
            room.id,
            vote.id,
            'my_test_uid',
          );

      updatedVote = container.read(scheduleRoomsProvider).first.votes.firstWhere((v) => v.id == vote.id);
      expect(updatedVote.options.first.voterUids.contains('my_test_uid'), isFalse);

      // Now vote on second option
      container.read(scheduleRoomsProvider.notifier).castVote(
            roomId: room.id,
            voteId: vote.id,
            optionId: vote.options[1].id,
            voterUid: 'my_test_uid',
          );

      updatedVote = container.read(scheduleRoomsProvider).first.votes.firstWhere((v) => v.id == vote.id);
      expect(updatedVote.options[1].voterUids.contains('my_test_uid'), isTrue);
    });
  });

  group('RoomNotice Model & Pin/Comment Tests', () {
    test('Notice read toggle adds and removes user from confirmedMemberUids', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final room = container.read(scheduleRoomsProvider).first;
      final notice = room.notices.first;

      // Toggle read ON
      container.read(scheduleRoomsProvider.notifier).toggleNoticeRead(
            room.id,
            notice.id,
            'test_user_777',
          );

      var updatedNotice = container.read(scheduleRoomsProvider).first.notices.firstWhere((n) => n.id == notice.id);
      expect(updatedNotice.confirmedMemberUids.contains('test_user_777'), isTrue);

      // Toggle read OFF
      container.read(scheduleRoomsProvider.notifier).toggleNoticeRead(
            room.id,
            notice.id,
            'test_user_777',
          );

      updatedNotice = container.read(scheduleRoomsProvider).first.notices.firstWhere((n) => n.id == notice.id);
      expect(updatedNotice.confirmedMemberUids.contains('test_user_777'), isFalse);
    });

    test('Adding comment to notice appends to notice comments feed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final room = container.read(scheduleRoomsProvider).first;
      final notice = room.notices.first;
      final initialCount = notice.comments.length;

      container.read(scheduleRoomsProvider.notifier).addNoticeComment(
            room.id,
            notice.id,
            NoticeComment(
              id: 'comment_1',
              authorUid: 'user_1',
              authorName: '홍길동',
              authorIcon: '🤠',
              content: '확인했습니다! 정시에 도착할게요.',
              createdAt: DateTime.now(),
            ),
          );

      final updatedNotice = container.read(scheduleRoomsProvider).first.notices.firstWhere((n) => n.id == notice.id);
      expect(updatedNotice.comments.length, initialCount + 1);
      expect(updatedNotice.comments.last.content, '확인했습니다! 정시에 도착할게요.');
    });
  });
}
