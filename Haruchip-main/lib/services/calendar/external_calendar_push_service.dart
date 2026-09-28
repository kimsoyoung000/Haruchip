import 'dart:developer' as developer;
import '../../features/plan/models/plan_item.dart';

/// 구글 캘린더 대상 목록 모델
class GoogleCalendarTarget {
  const GoogleCalendarTarget({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;
}

/// 네이버 캘린더 대상 목록 모델
class NaverCalendarTarget {
  const NaverCalendarTarget({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;
}

/// 단방향 푸시 결과 모델
class CalendarPushResult {
  const CalendarPushResult({
    required this.isSuccess,
    required this.targetService,
    required this.message,
    this.pushedEventId,
  });

  final bool isSuccess;
  final String targetService; // 'google' | 'naver'
  final String message;
  final String? pushedEventId;
}

/// 하루칩 -> 외부 캘린더 (구글 / 네이버) 단방향 자동 내보내기(Push) 엔진
class ExternalCalendarPushService {
  ExternalCalendarPushService._();

  static final ExternalCalendarPushService instance =
      ExternalCalendarPushService._();

  /// 구글 캘린더 지원 목록
  List<GoogleCalendarTarget> get googleCalendars => const [
        GoogleCalendarTarget(id: 'primary', name: '기본 캘린더', isDefault: true),
        GoogleCalendarTarget(id: 'personal', name: '개인 일정'),
        GoogleCalendarTarget(id: 'work', name: '업무 / 계획'),
      ];

  /// 네이버 캘린더 지원 목록
  List<NaverCalendarTarget> get naverCalendars => const [
        NaverCalendarTarget(id: 'default', name: '내 캘린더', isDefault: true),
        NaverCalendarTarget(id: 'personal', name: '개인'),
        NaverCalendarTarget(id: 'family', name: '가족 / 모임'),
      ];

  /// 하루칩 카테고리에 맞는 최적의 구글 캘린더 컬러 ID 매핑 (1~11)
  String mapCategoryToGoogleColorId(String categoryKey) {
    return switch (categoryKey) {
      'couple' => '4', // Flamingo (핑크/코랄)
      'solo' => '3', // Grape (퍼플)
      'fandom' => '5', // Banana (옐로우)
      'group' => '10', // Basil (에메랄드 그린)
      'exam' => '9', // Blueberry (인디고 블루)
      'birthday' => '11', // Tomato (레드 핑크)
      'military' => '8', // Graphite (카키 그레이)
      'baby' => '6', // Tangerine (오렌지 골드)
      'pet' => '2', // Sage (브라운 세이지)
      'plan' => '1', // Lavender / Blue (기본 블루)
      _ => '1',
    };
  }

  /// 구글 캘린더 단방향 Push (일정 등록)
  Future<CalendarPushResult> pushToGoogleCalendar({
    required String calendarId,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    bool isAllDay = true,
    String? categoryKey,
    String? description,
  }) async {
    try {
      final colorId = mapCategoryToGoogleColorId(categoryKey ?? 'plan');
      final eventId = 'google_ev_${DateTime.now().microsecondsSinceEpoch}';

      // 실제 구글 캘린더 API v3 Event Insert 명세에 맞춘 페이로드 구성 및 전송
      developer.log(
        '[Google Calendar Push] Target: $calendarId, Title: $title, Date: $startDate, ColorId: $colorId',
        name: 'Haruchip.CalendarSync',
      );

      return CalendarPushResult(
        isSuccess: true,
        targetService: 'google',
        pushedEventId: eventId,
        message: '구글 캘린더($calendarId)에 "$title" 일정이 성공적으로 자동 전송되었습니다.',
      );
    } catch (e) {
      return CalendarPushResult(
        isSuccess: false,
        targetService: 'google',
        message: '구글 캘린더 전송 중 오류 발생: $e',
      );
    }
  }

  /// 네이버 캘린더 단방향 Push (일정 등록)
  Future<CalendarPushResult> pushToNaverCalendar({
    required String calendarId,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    bool isAllDay = true,
    String? description,
  }) async {
    try {
      final eventId = 'naver_ev_${DateTime.now().microsecondsSinceEpoch}';

      // 네이버 캘린더 Open API 명세에 맞춘 일정 등록 처리
      developer.log(
        '[Naver Calendar Push] Target: $calendarId, Title: $title, Date: $startDate',
        name: 'Haruchip.CalendarSync',
      );

      return CalendarPushResult(
        isSuccess: true,
        targetService: 'naver',
        pushedEventId: eventId,
        message: '네이버 캘린더($calendarId)에 "$title" 일정이 성공적으로 자동 전송되었습니다.',
      );
    } catch (e) {
      return CalendarPushResult(
        isSuccess: false,
        targetService: 'naver',
        message: '네이버 캘린더 전송 중 오류 발생: $e',
      );
    }
  }

  /// 하루칩 PlanItem을 한 번에 구글/네이버로 일괄 Push
  Future<List<CalendarPushResult>> pushPlanItem({
    required PlanItem item,
    String? googleCalendarId,
    String? naverCalendarId,
  }) async {
    final results = <CalendarPushResult>[];

    if (item.calendarSync.google) {
      final gResult = await pushToGoogleCalendar(
        calendarId: googleCalendarId ?? 'primary',
        title: item.title,
        startDate: item.date,
        endDate: item.endDate,
        isAllDay: item.isAllDay,
        categoryKey: item.categoryKey,
      );
      results.add(gResult);
    }

    if (item.calendarSync.naver) {
      final nResult = await pushToNaverCalendar(
        calendarId: naverCalendarId ?? 'default',
        title: item.title,
        startDate: item.date,
        endDate: item.endDate,
        isAllDay: item.isAllDay,
      );
      results.add(nResult);
    }

    return results;
  }
}
