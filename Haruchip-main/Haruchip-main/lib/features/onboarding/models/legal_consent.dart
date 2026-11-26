import 'package:flutter/foundation.dart';

/// 법적 효력 약관 동의 상태 모델 (개인정보보호법 및 정보통신망법 준수)
///
/// - 기기 OS 접근 권한([AppPermissionsState])과 엄격히 분리되어 관리된다.
/// - 필수 2종([serviceTermsAgreed], [privacyPolicyAgreed])이 모두 동의되어야
///   서비스 시작([canProceed])이 가능하다.
/// - 선택 1종([marketingAgreed]) 동의 시 [marketingAgreedAt] 타임스탬프를 기록한다.
@immutable
class LegalConsentState {
  const LegalConsentState({
    this.serviceTermsAgreed = false,
    this.privacyPolicyAgreed = false,
    this.marketingAgreed = false,
    this.requiredTermsAgreedAt,
    this.marketingAgreedAt,
  });

  final bool serviceTermsAgreed;
  final bool privacyPolicyAgreed;
  final bool marketingAgreed;
  final DateTime? requiredTermsAgreedAt;
  final DateTime? marketingAgreedAt;

  /// 필수 2종 모두 체크 시에만 [동의하고 시작하기] 활성화
  bool get canProceed => serviceTermsAgreed && privacyPolicyAgreed;

  /// 필수 2종 + 선택 1종 모두 체크 여부
  bool get allAgreed =>
      serviceTermsAgreed && privacyPolicyAgreed && marketingAgreed;

  /// 정보통신망법 제50조에 따른 마케팅 수신 동의 완료 안내 문구 포맷
  static String formatMarketingConsentToast(DateTime agreedAt) {
    final mm = agreedAt.month.toString().padLeft(2, '0');
    final dd = agreedAt.day.toString().padLeft(2, '0');
    return '${agreedAt.year}년 $mm월 $dd일 마케팅 정보 수신 동의가 완료되었습니다';
  }

  LegalConsentState copyWith({
    bool? serviceTermsAgreed,
    bool? privacyPolicyAgreed,
    bool? marketingAgreed,
    DateTime? requiredTermsAgreedAt,
    DateTime? marketingAgreedAt,
    bool clearMarketingAgreedAt = false,
  }) {
    return LegalConsentState(
      serviceTermsAgreed: serviceTermsAgreed ?? this.serviceTermsAgreed,
      privacyPolicyAgreed: privacyPolicyAgreed ?? this.privacyPolicyAgreed,
      marketingAgreed: marketingAgreed ?? this.marketingAgreed,
      requiredTermsAgreedAt:
          requiredTermsAgreedAt ?? this.requiredTermsAgreedAt,
      marketingAgreedAt: clearMarketingAgreedAt
          ? null
          : (marketingAgreedAt ?? this.marketingAgreedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceTermsAgreed': serviceTermsAgreed,
        'privacyPolicyAgreed': privacyPolicyAgreed,
        'marketingAgreed': marketingAgreed,
        'requiredTermsAgreedAt': requiredTermsAgreedAt?.toIso8601String(),
        'marketingAgreedAt': marketingAgreedAt?.toIso8601String(),
      };

  factory LegalConsentState.fromJson(Map<String, dynamic> json) {
    return LegalConsentState(
      serviceTermsAgreed: json['serviceTermsAgreed'] as bool? ?? false,
      privacyPolicyAgreed: json['privacyPolicyAgreed'] as bool? ?? false,
      marketingAgreed: json['marketingAgreed'] as bool? ?? false,
      requiredTermsAgreedAt: json['requiredTermsAgreedAt'] != null
          ? DateTime.tryParse(json['requiredTermsAgreedAt'] as String)
          : null,
      marketingAgreedAt: json['marketingAgreedAt'] != null
          ? DateTime.tryParse(json['marketingAgreedAt'] as String)
          : null,
    );
  }
}

/// 약관 전문 데이터 (모달/뷰어 노출용)
class HaruLegalDocuments {
  HaruLegalDocuments._();

  static const String serviceTermsTitle = '서비스 이용약관 (필수)';
  static const String serviceTermsBody = '''
제1조 (목적)
본 약관은 하루칩(HaruChip)이 제공하는 D-Day 관리, 캘린더, 모임 일정 조율 및 부가 서비스의 이용 조건과 절차, 회사와 이용자의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.

제2조 (서비스의 제공 및 변경)
1. 회사는 이용자에게 개인 기념일·카테고리 관리, 통합 칩 캘린더, 배틀태그 기반 친구 연결 및 모임 공유 캘린더 기능을 제공합니다.
2. 회사는 서비스 품질 향상을 위해 기능의 일부를 개선하거나 변경할 수 있으며, 중요한 변경 사항은 앱 내 공지를 통해 사전 안내합니다.

제3조 (이용자의 의무)
1. 이용자는 타인의 개인정보를 도용하거나 운영자 사칭, 욕설·비방 등 건전한 서비스 이용을 저해하는 행위를 하여서는 안 됩니다.
2. 이용자가 등록한 일정·사진·메모 등 콘텐츠에 대한 책임은 해당 이용자에게 있습니다.

제4조 (계정 해지 및 데이터 삭제)
이용자는 언제든지 앱 내 설정 메뉴를 통해 서비스 이용 계약을 해지(회원 탈퇴)할 수 있으며, 관계 법령상 보존 의무가 있는 경우를 제외하고 즉시 파기됩니다.
''';

  static const String privacyPolicyTitle = '개인정보 수집 및 이용 동의 (필수)';
  static const String privacyPolicyBody = '''
하루칩(HaruChip)은 「개인정보 보호법」에 따라 서비스 제공을 위해 아래와 같이 개인정보를 수집·이용합니다.

1. 수집 항목
- 필수: 회원 식별자(UID), 닉네임 및 배틀태그(#TAG), 소셜 로그인 이메일(구글/애플 연동 시)
- 선택: 프로필 사진, 카테고리별 D-Day·기념일·일정·메모 데이터, 외부 캘린더 연동 토큰(OAuth 동의 시)

2. 수집 및 이용 목적
- 회원 식별, 배틀태그 기반 친구 검색·연결 및 1:1/모임 일정 실시간 동기화
- D-Day 알림 발송, 고객 문의 대응 및 부정 이용 방지

3. 보유 및 이용 기간
- 회원 탈퇴 시까지 보유하며, 탈퇴 요청 시 지체 없이 파기합니다.
- 단, 관계 법령에 의해 보존이 필요한 경우 해당 법령에서 정한 기간 동안 보관합니다.

4. 동의 거부 권리 및 불이익
이용자는 개인정보 수집·이용에 대한 동의를 거부할 수 있으나, 필수 항목 미동의 시 하루칩 서비스 가입 및 이용이 제한됩니다.
''';

  static const String marketingConsentTitle = '혜택 및 마케팅 정보 수신 동의 (선택)';
  static const String marketingConsentBody = '''
하루칩(HaruChip)에서 제공하는 신규 기능 안내, 시즌 이벤트, 맞춤형 혜택 정보를 앱 푸시 알림·문자·카카오톡 채널을 통해 받아보실 수 있습니다.

1. 수집 및 이용 항목: 회원 식별자(UID), 푸시 알림 토큰, 마케팅 수신 동의 일시
2. 이용 목적: 신규 업데이트, 프로모션 및 맞춤형 이벤트 정보 안내 (야간 21시~08시 발송 제한)
3. 보유 기간: 동의 철회 또는 회원 탈퇴 시까지

※ 본 동의는 선택 사항이며, 동의하지 않아도 하루칩의 모든 핵심 기능을 정상적으로 이용하실 수 있습니다. 동의 후에도 [프로필 & 설정]에서 언제든지 철회할 수 있습니다.
''';
}
