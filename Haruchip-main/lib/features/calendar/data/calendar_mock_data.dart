import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../models/calendar_event.dart';
import '../models/schedule_room.dart';

/// AppColors 토큰(Color)을 CalendarEvent.colorHex가 요구하는 '#RRGGBB' 문자열로
/// 변환한다. 색상값 자체는 항상 AppColors.proto* 토큰에서만 가져온다(§6).
String _toHex(Color color) {
  String channel(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}'.toUpperCase();
}

/// source별 표시 색상.
///
/// NOTE(토큰 갭): AppColors에는 구글/네이버 브랜드색 전용 토큰이 아직 없다.
/// personal은 커플 핑크 톤(protoCoupleText)을, google/naver는 각각
/// practicalAccent(파랑 계열)/emotionalAccent(핑크 계열)를 임시로 빌려 썼다.
/// 실제 구글(빨강 계열)·네이버(초록 계열) 브랜드 색이 필요하면
/// `protoGoogleSource` / `protoNaverSource` 같은 토큰을 colors.dart에 새로
/// 추가해야 한다 — 이번 작업 범위(로직 담당자)에서는 임의로 만들지 않았다.
String colorHexForSource(String source) {
  switch (source) {
    case 'google':
      return _toHex(AppColors.practicalAccent);
    case 'naver':
      return _toHex(AppColors.emotionalAccent);
    case 'personal':
    default:
      return _toHex(AppColors.protoCoupleText);
  }
}

/// CalendarEvent mock 목록.
final List<CalendarEvent> mockCalendarEvents = [
  CalendarEvent(
    id: 'evt-1',
    date: DateTime(2026, 8, 14),
    title: '민수와 데이트',
    time: '19:00',
    source: 'personal',
    colorHex: colorHexForSource('personal'),
    isPublic: false,
  ),
  CalendarEvent(
    id: 'evt-2',
    date: DateTime(2026, 8, 20),
    title: '팀 프로젝트 회식',
    time: '18:30',
    source: 'google',
    colorHex: colorHexForSource('google'),
    isPublic: false,
  ),
  CalendarEvent(
    id: 'evt-3',
    date: DateTime(2026, 9, 1),
    title: '정보처리기사 필기',
    source: 'naver',
    colorHex: colorHexForSource('naver'),
    isPublic: true,
  ),
];

/// ScheduleRoom mock 목록.
///
/// haruchip_app.html의 mock 방 2개("주말 대학 동창 모임" / "팀 프로젝트 회식")와
/// 같은 톤으로 맞췄다. uid는 화면 담당자가 실제 로그인 uid로 교체하기 쉽도록
/// 이름 그대로 문자열 키로 뒀다.
final List<ScheduleRoom> mockScheduleRooms = [
  ScheduleRoom(
    id: 'room-1',
    name: '주말 대학 동창 모임',
    inviteCode: 'HC-8829AF',
    description: '분기별 정기 모임 및 맛집 탐방 스터디',
    categoryTag: '동창회',
    members: const [
      RoomMember(uid: '하루', name: '하루', icon: '🐥', colorHex: '#DFE7FD', isHost: true),
      RoomMember(uid: '민수', name: '민수', icon: '🐶', colorHex: '#FFD1DC'),
      RoomMember(uid: '서연', name: '서연', icon: '🐱', colorHex: '#D0F4DE'),
      RoomMember(uid: '도윤', name: '도윤', icon: '🦊', colorHex: '#FCF6BD'),
    ],
    dates: {
      '2026-10-01': ['하루', '민수', '서연', '도윤'],
      '2026-10-05': ['하루', '민수', '서연'],
      '2026-10-12': ['하루', '도윤'],
    },
    payments: const {'하루': 60000, '서연': 40000},
    events: [
      RoomSharedEvent(
        id: 'revt-1',
        roomId: 'room-1',
        title: '정기 10월 모임 & 저녁 회식',
        authorUid: '하루',
        date: DateTime.now(),
        time: '18:30',
        location: '강남역 11번 출구 맛집',
        memo: '예약 완료! 늦지 않게 와주세요.',
      ),
      RoomSharedEvent(
        id: 'revt-2',
        roomId: 'room-1',
        title: '가을 단풍 등산 약속',
        authorUid: '민수',
        date: DateTime.now().add(const Duration(days: 10)),
        time: '09:00',
        location: '청계산 입구',
      ),
    ],
    notices: [
      RoomNotice(
        id: 'notice-1',
        authorName: '하루',
        authorIcon: '🐥',
        content: '📌 이번 정기 모임 장소는 강남역 인근입니다. 주차는 공영주차장 이용 권장드려요!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: true,
        confirmedMemberUids: const ['하루', '민수', '서연'],
        comments: [
          NoticeComment(
            id: 'cmt-1',
            authorUid: '민수',
            authorName: '민수',
            authorIcon: '🐶',
            content: '확인했습니다! 6시 반까지 갈게요~',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          NoticeComment(
            id: 'cmt-2',
            authorUid: '서연',
            authorName: '서연',
            authorIcon: '🐱',
            content: '저 조금 10분 정도 늦을 수 있어요!',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    ],
    votes: [
      RoomVote(
        id: 'vote-1',
        title: '2차 장소 어디로 갈까요?',
        authorUid: '하루',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        deadline: DateTime.now().add(const Duration(days: 1, hours: 8)),
        allowMultiple: true,
        isAnonymous: false,
        options: [
          const VoteOption(id: 'opt-1', text: '조용한 이자카야 🍶', voterUids: ['하루', '서연']),
          const VoteOption(id: 'opt-2', text: '신나는 볼링장 🎳', voterUids: ['민수']),
          const VoteOption(id: 'opt-3', text: '분위기 좋은 카페 ☕', voterUids: ['도윤']),
        ],
      ),
    ],
    rounds: [
      const SettlementRound(
        id: 'round-1',
        roundNumber: 1,
        title: '1차 고깃집 저녁 식사',
        totalAmount: 140000,
        payerUid: '하루',
        attendeeUids: ['하루', '민수', '서연', '도윤'],
        exceptions: [
          SettlementException(
            id: 'exp-1',
            title: '술값 (음주자만)',
            amount: 40000,
            exemptMemberUids: ['서연'], // 서연 비음주
          ),
        ],
      ),
      const SettlementRound(
        id: 'round-2',
        roundNumber: 2,
        title: '2차 보드게임 카페',
        totalAmount: 36000,
        payerUid: '서연',
        attendeeUids: ['하루', '민수', '서연'],
      ),
    ],
    settlementHistory: [
      SettlementRecord(
        id: 'settle-rec-1',
        roomId: 'room-1',
        title: '10/24 정기 동창회 1·2차 정산',
        date: DateTime.now().subtract(const Duration(days: 2)),
        totalAmount: 176000,
        rounds: const [
          SettlementRound(
            id: 'round-1',
            roundNumber: 1,
            title: '1차 고깃집 저녁 식사',
            totalAmount: 140000,
            payerUid: '하루',
            attendeeUids: ['하루', '민수', '서연', '도윤'],
            exceptions: [
              SettlementException(
                id: 'exp-1',
                title: '술값 (음주자만)',
                amount: 40000,
                exemptMemberUids: ['서연'],
              ),
            ],
          ),
          SettlementRound(
            id: 'round-2',
            roundNumber: 2,
            title: '2차 보드게임 카페',
            totalAmount: 36000,
            payerUid: '서연',
            attendeeUids: ['하루', '민수', '서연'],
          ),
        ],
        payerUid: '하루',
        attendeeUids: const ['하루', '민수', '서연', '도윤'],
        perMemberAmounts: const {
          '민수': 47000,
          '서연': 37000,
          '도윤': 37000,
        },
        transferStatus: const {
          '민수': true,
          '서연': false,
          '도윤': true,
        },
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
  ),
  ScheduleRoom(
    id: 'room-2',
    name: '팀 프로젝트 회식',
    inviteCode: 'TEAM99',
    description: 'HaruChip 스프린트 런칭 기념 회식',
    categoryTag: '프로젝트',
    members: const [
      RoomMember(uid: '하루', name: '하루', icon: '🐥', colorHex: '#DFE7FD', isHost: false),
      RoomMember(uid: '팀장님', name: '팀장님', icon: '🦁', colorHex: '#FFD8BE', isHost: true),
      RoomMember(uid: '인턴', name: '인턴', icon: '🐰', colorHex: '#E4C1F9'),
    ],
    dates: {
      '2026-10-08': ['하루', '팀장님', '인턴'],
    },
    payments: const {'팀장님': 45000},
    events: [
      RoomSharedEvent(
        id: 'revt-3',
        roomId: 'room-2',
        title: '스프린트 리뷰 & 런칭 축하',
        authorUid: '팀장님',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '19:00',
        location: '판교역 아브뉴프랑',
      ),
    ],
  ),
];
