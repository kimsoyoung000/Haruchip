import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/local_store.dart';
import '../models/wedding_extras_models.dart';

const String _kWeddingExtrasStoreKey = 'haruchip.wedding.extras.v1';

/// 청첩장 모임 · 하객 보증인원 · 본식 후 사후 정산 · 섹션 순서/숨김 상태 Notifier
class WeddingExtrasNotifier extends Notifier<WeddingExtrasState> {
  @override
  WeddingExtrasState build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) {
      store.writeString(_kWeddingExtrasStoreKey, jsonEncode(next.toJson()));
    });

    final raw = store.readString(_kWeddingExtrasStoreKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return WeddingExtrasState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }

    return WeddingExtrasState(
      guaranteedGuests: 250,
      extraConfirmedGuests: 220,
      meetings: [
        WeddingInvitationMeeting(
          id: 'meeting-sample-1',
          title: '대학 동기 청첩장 모임',
          meetingDate: DateTime.now().add(const Duration(days: 14)),
          location: '강남역 모임 식당',
          affiliation: GuestAffiliation.joint,
          attendeeCount: 6,
          mealCostPerPerson: 55000,
        ),
        WeddingInvitationMeeting(
          id: 'meeting-sample-2',
          title: '회사 팀 청첩장 모임',
          meetingDate: DateTime.now().add(const Duration(days: 21)),
          location: '여의도 한정식',
          affiliation: GuestAffiliation.groom,
          attendeeCount: 4,
          mealCostPerPerson: 60000,
        ),
      ],
      afterWeddingTasks: createDefaultAfterWeddingTasks(),
    );
  }

  void setGuestCounts({
    required int guaranteedGuests,
    required int extraConfirmedGuests,
  }) {
    state = state.copyWith(
      guaranteedGuests: guaranteedGuests.clamp(0, 99999),
      extraConfirmedGuests: extraConfirmedGuests.clamp(0, 99999),
    );
  }

  void addMeeting(WeddingInvitationMeeting meeting) {
    state = state.copyWith(meetings: [...state.meetings, meeting]);
  }

  void updateMeeting(WeddingInvitationMeeting updated) {
    state = state.copyWith(
      meetings: state.meetings
          .map((m) => m.id == updated.id ? updated : m)
          .toList(),
    );
  }

  void toggleMeetingCompleted(String id) {
    state = state.copyWith(
      meetings: state.meetings
          .map((m) => m.id == id ? m.copyWith(isCompleted: !m.isCompleted) : m)
          .toList(),
    );
  }

  void deleteMeeting(String id) {
    state = state.copyWith(
      meetings: state.meetings.where((m) => m.id != id).toList(),
    );
  }

  void addAfterTask(AfterWeddingTask task) {
    state = state.copyWith(
      afterWeddingTasks: [...state.afterWeddingTasks, task],
    );
  }

  void updateAfterTask(AfterWeddingTask updated) {
    state = state.copyWith(
      afterWeddingTasks: state.afterWeddingTasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList(),
    );
  }

  void toggleAfterTask(String id) {
    state = state.copyWith(
      afterWeddingTasks: state.afterWeddingTasks
          .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
          .toList(),
    );
  }

  void deleteAfterTask(String id) {
    state = state.copyWith(
      afterWeddingTasks:
          state.afterWeddingTasks.where((t) => t.id != id).toList(),
    );
  }

  void updateSectionConfig({
    required List<String> order,
    required Set<String> hidden,
  }) {
    final normalized = <String>[
      for (final key in order)
        if (kDefaultWeddingSectionOrder.contains(key)) key,
      for (final key in kDefaultWeddingSectionOrder)
        if (!order.contains(key)) key,
    ];
    state = state.copyWith(
      sectionOrder: normalized,
      hiddenSections: hidden,
    );
  }
}

final weddingExtrasProvider =
    NotifierProvider<WeddingExtrasNotifier, WeddingExtrasState>(
  WeddingExtrasNotifier.new,
);
