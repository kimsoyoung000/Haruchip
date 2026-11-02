/// 하루칩 캘린더 화면에 표시되는 일정 한 건 (CLAUDE.md §7-4).
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.time,
    required this.source,
    required this.colorHex,
    this.categoryKey = 'plan',
    this.isPublic = false,
  });

  final String id;
  final DateTime date;
  final String title;

  /// 'HH:mm' 형식 텍스트. 종일 일정이면 null.
  final String? time;

  /// 'personal' | 'google' | 'naver'
  final String source;

  /// '#RRGGBB' 형식. 항상 `AppColors.proto*` 토큰에서 파생시켜서 채운다.
  final String colorHex;

  /// 카테고리 키 ('plan' | 'couple' | 'solo' | 'fandom' | 'group' | 'exam' | 'birthday' | 'baby' | 'pet' | 'military')
  final String categoryKey;

  /// 공개/비공개 토글 상태 (기본 비공개 — CLAUDE.md §7-4).
  final bool isPublic;
}
