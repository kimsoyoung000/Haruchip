import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/local_store.dart';
import '../models/legal_consent.dart';

const String _kLegalConsentStorageKey = 'haruchip_legal_consent_v1';

/// 법적 약관 동의 상태 관리 및 DB(로컬 + Firestore Timestamp) 법적 로깅 노티파이어
class LegalConsentNotifier extends Notifier<LegalConsentState> {
  @override
  LegalConsentState build() {
    final store = ref.watch(localStoreProvider);
    final raw = store.readString(_kLegalConsentStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return LegalConsentState.fromJson(decoded);
      } catch (_) {}
    }
    return const LegalConsentState();
  }

  void toggleAll() {
    final nextVal = !state.allAgreed;
    final now = DateTime.now();
    state = state.copyWith(
      serviceTermsAgreed: nextVal,
      privacyPolicyAgreed: nextVal,
      marketingAgreed: nextVal,
      requiredTermsAgreedAt: nextVal ? now : state.requiredTermsAgreedAt,
      marketingAgreedAt: nextVal ? now : null,
      clearMarketingAgreedAt: !nextVal,
    );
    _persistLocal();
  }

  void toggleServiceTerms() {
    final next = !state.serviceTermsAgreed;
    state = state.copyWith(
      serviceTermsAgreed: next,
      requiredTermsAgreedAt:
          (next && state.privacyPolicyAgreed) ? DateTime.now() : null,
    );
    _persistLocal();
  }

  void togglePrivacyPolicy() {
    final next = !state.privacyPolicyAgreed;
    state = state.copyWith(
      privacyPolicyAgreed: next,
      requiredTermsAgreedAt:
          (next && state.serviceTermsAgreed) ? DateTime.now() : null,
    );
    _persistLocal();
  }

  /// [선택 1] 마케팅 수신 동의 토글 — ON 전환 시 동의 타임스탬프 기록
  DateTime? toggleMarketing() {
    final next = !state.marketingAgreed;
    final agreedAt = next ? DateTime.now() : null;
    state = state.copyWith(
      marketingAgreed: next,
      marketingAgreedAt: agreedAt,
      clearMarketingAgreedAt: !next,
    );
    _persistLocal();
    return agreedAt;
  }

  /// [동의하고 시작하기] 최종 확정 및 DB(`marketingAgreedAt: Timestamp`) 법적 로깅
  Future<DateTime?> commitConsentToDatabase({
    FirebaseFirestore? firestoreOverride,
    String? uidOverride,
  }) async {
    if (!state.canProceed) return null;

    final now = DateTime.now();
    final marketingTs =
        state.marketingAgreed ? (state.marketingAgreedAt ?? now) : null;
    state = state.copyWith(
      requiredTermsAgreedAt: state.requiredTermsAgreedAt ?? now,
      marketingAgreedAt: marketingTs,
      clearMarketingAgreedAt: !state.marketingAgreed,
    );
    _persistLocal();

    await _logToFirestore(
      firestoreOverride: firestoreOverride,
      uidOverride: uidOverride,
      requiredAt: state.requiredTermsAgreedAt ?? now,
      marketingAt: marketingTs,
    );
    return marketingTs;
  }

  void _persistLocal() {
    final store = ref.read(localStoreProvider);
    store.writeString(_kLegalConsentStorageKey, jsonEncode(state.toJson()));
  }

  Future<void> _logToFirestore({
    FirebaseFirestore? firestoreOverride,
    String? uidOverride,
    required DateTime requiredAt,
    required DateTime? marketingAt,
  }) async {
    try {
      String? uid = uidOverride;
      FirebaseFirestore? db = firestoreOverride;

      if (db == null) {
        if (Firebase.apps.isEmpty) return;
        uid ??= FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || uid.isEmpty) return;
        db = FirebaseFirestore.instance;
      }
      if (uid == null || uid.isEmpty) return;

      await db.collection('users').doc(uid).set(
        <String, dynamic>{
          'legalConsent': <String, dynamic>{
            'serviceTermsAgreed': state.serviceTermsAgreed,
            'privacyPolicyAgreed': state.privacyPolicyAgreed,
            'requiredTermsAgreedAt': Timestamp.fromDate(requiredAt),
            'marketingAgreed': state.marketingAgreed,
            'marketingAgreedAt':
                marketingAt != null ? Timestamp.fromDate(marketingAt) : null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'marketingAgreed': state.marketingAgreed,
          'marketingAgreedAt':
              marketingAt != null ? Timestamp.fromDate(marketingAt) : null,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('LegalConsent Firestore logging skipped/failed: $e');
    }
  }
}

final legalConsentProvider =
    NotifierProvider<LegalConsentNotifier, LegalConsentState>(
  LegalConsentNotifier.new,
);
