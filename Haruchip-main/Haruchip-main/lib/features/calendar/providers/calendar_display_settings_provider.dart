import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/local_store.dart';
import '../models/calendar_display_settings.dart';

/// 칩 캘린더 표시 설정(글꼴 크기, 굵기, 라벨 형식, 넘겨보기, 테마 색상, 첫 진입 안내) 상태 관리
class CalendarDisplaySettingsNotifier extends Notifier<CalendarDisplaySettings> {
  @override
  CalendarDisplaySettings build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) {
      store.writeString(
        LocalStoreKeys.calendarDisplaySettings,
        jsonEncode(next.toJson()),
      );
    });

    final raw = store.readString(LocalStoreKeys.calendarDisplaySettings);
    if (raw == null) return const CalendarDisplaySettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CalendarDisplaySettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return CalendarDisplaySettings.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return const CalendarDisplaySettings();
  }

  void setFontSize(CalendarFontSize fontSize) {
    state = state.copyWith(fontSize: fontSize);
  }

  void setFontWeight(CalendarFontWeight fontWeight) {
    state = state.copyWith(fontWeight: fontWeight);
  }

  void setShowTime(bool value) {
    state = state.copyWith(showTime: value);
  }

  void setCompactTimeEvent(bool value) {
    state = state.copyWith(compactTimeEvent: value);
  }

  void setShowLunar(bool value) {
    state = state.copyWith(showLunar: value);
  }

  void setStartOnMonday(bool value) {
    state = state.copyWith(startOnMonday: value);
  }

  void setScrollDirection(CalendarScrollDirection direction) {
    state = state.copyWith(scrollDirection: direction);
  }

  void setThemeColorName(String name) {
    state = state.copyWith(themeColorName: name);
  }

  void markOnboardingSeen() {
    if (!state.hasSeenOnboarding) {
      state = state.copyWith(hasSeenOnboarding: true);
    }
  }
}

final calendarDisplaySettingsProvider =
    NotifierProvider<CalendarDisplaySettingsNotifier, CalendarDisplaySettings>(
  CalendarDisplaySettingsNotifier.new,
);
