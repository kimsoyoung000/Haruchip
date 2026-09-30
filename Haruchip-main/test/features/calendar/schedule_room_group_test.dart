import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/logic/settlement_calculator.dart';
import 'package:haruchip/features/calendar/models/schedule_room.dart';

void main() {
  group('Smart Multi-Round Settlement Calculator Tests', () {
    test('Calculates 2-round settlement with alcohol exemption correctly', () {
      final members = [
        const RoomMember(uid: 'u1', name: '김민수', icon: '👤', colorHex: '#FEE2E2', isHost: true),
        const RoomMember(uid: 'u2', name: '이영희', icon: '🌸', colorHex: '#DBEAFE', isHost: false),
        const RoomMember(uid: 'u3', name: '박철수', icon: '⚡', colorHex: '#DCFCE7', isHost: false),
      ];

      // 1차: 삼겹살 90,000원 (김민수 결제, 3명 참석, 예외 없음) -> 각 30,000원
      final round1 = SettlementRound(
        id: 'r1',
        roundNumber: 1,
        title: '1차 삼겹살',
        totalAmount: 90000,
        payerUid: 'u1',
        attendeeUids: ['u1', 'u2', 'u3'],
        exceptions: const [],
      );

      // 2차: 맥주창고 60,000원 (이영희 결제, 3명 참석, 안주 30,000원 + 술값 30,000원 중 박철수(u3)는 비음주자 예외)
      // 안주 30,000원 / 3명 = 각 10,000원
      // 술값 30,000원 / 2명 (u1, u2) = 각 15,000원
      // u1: 10,000 + 15,000 = 25,000원
      // u2: 10,000 + 15,000 = 25,000원
      // u3: 10,000원
      final round2 = SettlementRound(
        id: 'r2',
        roundNumber: 2,
        title: '2차 맥주창고',
        totalAmount: 60000,
        payerUid: 'u2',
        attendeeUids: ['u1', 'u2', 'u3'],
        exceptions: [
          const SettlementException(
            id: 'e1',
            title: '술값',
            amount: 30000,
            exemptMemberUids: ['u3'], // 박철수 제외
          ),
        ],
      );

      final result = calculateMultiRoundSettlement(
        rounds: [round1, round2],
        members: members,
      );

      expect(result.grandTotal, 150000);
      expect(result.memberDetails.length, 3);

      // u1 (김민수): 결제 90,000, 부담 (30,000 + 25,000 = 55,000), net = +35,000 (받을 돈)
      final d1 = result.memberDetails.firstWhere((d) => d.member.uid == 'u1');
      expect(d1.totalPaid, 90000);
      expect(d1.totalOwed, 55000);
      expect(d1.netBalance, 35000);

      // u2 (이영희): 결제 60,000, 부담 (30,000 + 25,000 = 55,000), net = +5,000 (받을 돈)
      final d2 = result.memberDetails.firstWhere((d) => d.member.uid == 'u2');
      expect(d2.totalPaid, 60000);
      expect(d2.totalOwed, 55000);
      expect(d2.netBalance, 5000);

      // u3 (박철수): 결제 0, 부담 (30,000 + 10,000 = 40,000), net = -40,000 (보낼 돈)
      final d3 = result.memberDetails.firstWhere((d) => d.member.uid == 'u3');
      expect(d3.totalPaid, 0);
      expect(d3.totalOwed, 40000);
      expect(d3.netBalance, -40000);

      // Transactions check: u3가 u1에게 35,000원, u2에게 5,000원 송금
      expect(result.transactions.length, 2);
      final txToU1 = result.transactions.firstWhere((t) => t.to == 'u1');
      final txToU2 = result.transactions.firstWhere((t) => t.to == 'u2');

      expect(txToU1.from, 'u3');
      expect(txToU1.amount, 35000);

      expect(txToU2.from, 'u3');
      expect(txToU2.amount, 5000);
    });
  });

  group('Preset 50 Pastel Colors & Room Models Tests', () {
    test('Preset 50 pastel colors list has 50 distinct valid hex colors', () {
      expect(kPreset50PastelColors.length, 50);
      final uniqueSet = kPreset50PastelColors.toSet();
      expect(uniqueSet.length, 50);
      for (final hex in kPreset50PastelColors) {
        expect(hex.startsWith('#'), isTrue);
        expect(hex.length, 7);
      }
    });

    test('RoomVote and VoteOption serialization', () {
      final vote = RoomVote(
        id: 'v1',
        title: '회식 장소 선정',
        description: '강남 또는 홍대 중 투표해주세요',
        authorUid: 'u1',
        allowMultiple: true,
        options: [
          const VoteOption(id: 'o1', text: '강남 삼겹살', voterUids: ['u1', 'u2']),
          const VoteOption(id: 'o2', text: '홍대 이자카야', voterUids: ['u3']),
        ],
        createdAt: DateTime(2026, 10, 1),
        isClosed: false,
      );

      final json = vote.toJson();
      final fromJson = RoomVote.fromJson(json);

      expect(fromJson.id, 'v1');
      expect(fromJson.title, '회식 장소 선정');
      expect(fromJson.description, '강남 또는 홍대 중 투표해주세요');
      expect(fromJson.allowMultiple, isTrue);
      expect(fromJson.options.length, 2);
      expect(fromJson.totalVotes, 3);
    });

    test('RoomNotice serialization', () {
      final notice = RoomNotice(
        id: 'n1',
        authorName: '하루',
        authorIcon: '🐥',
        content: '다음 주 금요일 저녁 7시 모임 확정입니다.',
        createdAt: DateTime(2026, 10, 1),
        isPinned: true,
      );

      final json = notice.toJson();
      final fromJson = RoomNotice.fromJson(json);

      expect(fromJson.id, 'n1');
      expect(fromJson.authorName, '하루');
      expect(fromJson.content, '다음 주 금요일 저녁 7시 모임 확정입니다.');
      expect(fromJson.isPinned, isTrue);
    });
  });
}
