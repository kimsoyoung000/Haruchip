import '../models/schedule_room.dart';

/// 정산 송금 제안: [from]이 [to]에게 [amount]를 보내면 된다.
class SettlementTransaction {
  const SettlementTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });

  final String from;
  final String to;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is SettlementTransaction &&
      other.from == from &&
      other.to == to &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(from, to, amount);

  @override
  String toString() => 'SettlementTransaction($from -> $to: $amount)';
}

/// 단일 정산 계산 결과
class SettlementResult {
  const SettlementResult({
    required this.total,
    required this.share,
    required this.tx,
  });

  /// 전체 지출 합계
  final int total;

  /// 1인당 부담액 (반올림)
  final int share;

  /// 부채 최소화 그리디로 계산한 송금 제안 목록
  final List<SettlementTransaction> tx;
}

/// 멤버별 세부 정산 내역
class MemberSettlementDetail {
  const MemberSettlementDetail({
    required this.member,
    required this.totalPaid,
    required this.totalOwed,
    required this.netBalance,
  });

  final RoomMember member;
  final int totalPaid;
  final int totalOwed;
  final int netBalance; // positive: 받을 돈, negative: 보낼 돈
}

/// 다차수 & 예외 공제 통합 정산 결과
class MultiRoundSettlementResult {
  const MultiRoundSettlementResult({
    required this.grandTotal,
    required this.memberDetails,
    required this.transactions,
  });

  final int grandTotal;
  final List<MemberSettlementDetail> memberDetails;
  final List<SettlementTransaction> transactions;
}

class _Balance {
  _Balance(this.uid, this.balance);

  final String uid;
  int balance;
}

/// 단일 라운드 기본 정산 (기존 호환)
SettlementResult calculateSettlement(
  Map<String, int> payments,
  List<String> members,
) {
  final total = payments.values.fold<int>(0, (a, b) => a + b);
  final share = members.isEmpty ? 0 : ((total / members.length) + 0.5).floor();

  final balances = members
      .map((name) => _Balance(name, (payments[name] ?? 0) - share))
      .toList();

  final creditors = balances.where((b) => b.balance > 0).toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));
  final debtors = balances.where((b) => b.balance < 0).toList()
    ..sort((a, b) => a.balance.compareTo(b.balance));

  var i = 0;
  var j = 0;
  final tx = <SettlementTransaction>[];
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i];
    final c = creditors[j];
    final amt = (-d.balance < c.balance) ? -d.balance : c.balance;
    if (amt > 0) {
      tx.add(SettlementTransaction(from: d.uid, to: c.uid, amount: amt));
    }
    d.balance += amt;
    c.balance -= amt;
    if (d.balance.abs() < 1) i++;
    if (c.balance.abs() < 1) j++;
  }

  return SettlementResult(total: total, share: share, tx: tx);
}

/// 1차, 2차... N차 다차수 & 예외자 공제 정밀 정산 연산 엔진
MultiRoundSettlementResult calculateMultiRoundSettlement({
  required List<SettlementRound> rounds,
  required List<RoomMember> members,
}) {
  if (rounds.isEmpty || members.isEmpty) {
    return MultiRoundSettlementResult(
      grandTotal: 0,
      memberDetails: members
          .map((m) => MemberSettlementDetail(
                member: m,
                totalPaid: 0,
                totalOwed: 0,
                netBalance: 0,
              ))
          .toList(),
      transactions: const [],
    );
  }

  var grandTotal = 0;
  final paidMap = <String, int>{for (final m in members) m.uid: 0};
  final owedMap = <String, int>{for (final m in members) m.uid: 0};

  for (final round in rounds) {
    grandTotal += round.totalAmount;

    // 결제자가 낸 금액 기록
    if (paidMap.containsKey(round.payerUid)) {
      paidMap[round.payerUid] = (paidMap[round.payerUid] ?? 0) + round.totalAmount;
    }

    // 예외 공제 금액 합산
    final totalExceptionAmount = round.exceptions.fold<int>(0, (s, e) => s + e.amount);
    final baseAmount = (round.totalAmount - totalExceptionAmount).clamp(0, round.totalAmount);

    // 1. 기본 금액(공통 식대 등)은 참석자 전원 분배
    final attendees = round.attendeeUids.where((uid) => paidMap.containsKey(uid)).toList();
    if (attendees.isNotEmpty && baseAmount > 0) {
      final basePerPerson = baseAmount / attendees.length;
      for (final uid in attendees) {
        owedMap[uid] = (owedMap[uid] ?? 0) + basePerPerson.round();
      }
    }

    // 2. 예외 항목(술값, 특정 메뉴 등)은 비참여자 제외 후 분배
    for (final exp in round.exceptions) {
      if (exp.amount <= 0) continue;
      final eligibleAttendees = attendees
          .where((uid) => !exp.exemptMemberUids.contains(uid))
          .toList();

      final targetGroup = eligibleAttendees.isNotEmpty ? eligibleAttendees : attendees;
      if (targetGroup.isNotEmpty) {
        final expPerPerson = exp.amount / targetGroup.length;
        for (final uid in targetGroup) {
          owedMap[uid] = (owedMap[uid] ?? 0) + expPerPerson.round();
        }
      }
    }
  }

  // 멤버별 세부 요약 생성
  final memberDetails = <MemberSettlementDetail>[];
  final balances = <_Balance>[];

  for (final m in members) {
    final paid = paidMap[m.uid] ?? 0;
    final owed = owedMap[m.uid] ?? 0;
    final net = paid - owed;

    memberDetails.add(MemberSettlementDetail(
      member: m,
      totalPaid: paid,
      totalOwed: owed,
      netBalance: net,
    ));

    balances.add(_Balance(m.uid, net));
  }

  // 부채 최소화 매칭 알고리즘
  final creditors = balances.where((b) => b.balance > 0).toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));
  final debtors = balances.where((b) => b.balance < 0).toList()
    ..sort((a, b) => a.balance.compareTo(b.balance));

  var i = 0;
  var j = 0;
  final txList = <SettlementTransaction>[];
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i];
    final c = creditors[j];
    final amt = (-d.balance < c.balance) ? -d.balance : c.balance;
    if (amt > 0) {
      txList.add(SettlementTransaction(from: d.uid, to: c.uid, amount: amt));
    }
    d.balance += amt;
    c.balance -= amt;
    if (d.balance.abs() < 1) i++;
    if (c.balance.abs() < 1) j++;
  }

  return MultiRoundSettlementResult(
    grandTotal: grandTotal,
    memberDetails: memberDetails,
    transactions: txList,
  );
}
