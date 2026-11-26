import 'package:flutter/material.dart';

/// 앱 권한 항목 메타데이터
class PermissionItemInfo {
  const PermissionItemInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isRequired = false,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;
}

/// 기기 OS 접근 권한 항목 리스트 (법적 약관/마케팅 수신 동의와 엄격 분리)
const List<PermissionItemInfo> kAppPermissionItems = [
  PermissionItemInfo(
    key: 'notification',
    title: '알림',
    description: 'D-Day 당일 및 시간 잔여 카운트다운 시스템 알림 수신',
    icon: Icons.notifications_active_outlined,
  ),
  PermissionItemInfo(
    key: 'photos',
    title: '갤러리/사진',
    description: '프로필 사진 설정 및 D-Day 공유 카드 저장 (iOS 제한 접근 지원)',
    icon: Icons.photo_library_outlined,
  ),
  PermissionItemInfo(
    key: 'camera',
    title: '카메라',
    description: '프로필 사진 직접 촬영 등록',
    icon: Icons.camera_alt_outlined,
  ),
  PermissionItemInfo(
    key: 'calendar',
    title: '캘린더',
    description: '기기 기본 캘린더(iCloud / Android)와 하루칩 일정 로컬 동기화',
    icon: Icons.calendar_month_outlined,
  ),
  PermissionItemInfo(
    key: 'settlement',
    title: '모임 간편 정산 연결',
    description: '카카오페이/토스 앱 바로가기 딥링크 활용',
    icon: Icons.payments_outlined,
  ),
];

/// 앱 권한 설정 상태 모델
class AppPermissionsState {
  const AppPermissionsState({
    this.notification = false,
    this.photos = false,
    this.photosLimited = false,
    this.camera = false,
    this.calendar = false,
    this.settlement = false,
    this.marketing = false,
  });

  final bool notification;
  final bool photos;

  /// iOS 14+ 사진 라이브러리 '제한된 접근(선택 사진 허용)' 상태 여부
  final bool photosLimited;
  final bool camera;
  final bool calendar;
  final bool settlement;
  final bool marketing;

  bool get allAgreed =>
      notification && photos && camera && calendar && settlement;

  bool isEnabled(String key) {
    switch (key) {
      case 'notification':
        return notification;
      case 'photos':
        return photos;
      case 'camera':
        return camera;
      case 'calendar':
        return calendar;
      case 'settlement':
        return settlement;
      case 'marketing':
        return marketing;
      default:
        return false;
    }
  }

  AppPermissionsState copyWith({
    bool? notification,
    bool? photos,
    bool? photosLimited,
    bool? camera,
    bool? calendar,
    bool? settlement,
    bool? marketing,
  }) {
    return AppPermissionsState(
      notification: notification ?? this.notification,
      photos: photos ?? this.photos,
      photosLimited: photosLimited ?? this.photosLimited,
      camera: camera ?? this.camera,
      calendar: calendar ?? this.calendar,
      settlement: settlement ?? this.settlement,
      marketing: marketing ?? this.marketing,
    );
  }

  AppPermissionsState setAll(bool value) {
    return AppPermissionsState(
      notification: value,
      photos: value,
      camera: value,
      calendar: value,
      settlement: value,
      marketing: value,
    );
  }

  AppPermissionsState toggle(String key) {
    switch (key) {
      case 'notification':
        return copyWith(notification: !notification);
      case 'photos':
        return copyWith(photos: !photos);
      case 'camera':
        return copyWith(camera: !camera);
      case 'calendar':
        return copyWith(calendar: !calendar);
      case 'settlement':
        return copyWith(settlement: !settlement);
      case 'marketing':
        return copyWith(marketing: !marketing);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() => {
        'notification': notification,
        'photos': photos,
        'camera': camera,
        'calendar': calendar,
        'settlement': settlement,
        'marketing': marketing,
      };

  factory AppPermissionsState.fromJson(Map<String, dynamic> json) {
    return AppPermissionsState(
      notification: json['notification'] as bool? ?? false,
      photos: json['photos'] as bool? ?? false,
      camera: json['camera'] as bool? ?? false,
      calendar: json['calendar'] as bool? ?? false,
      settlement: json['settlement'] as bool? ?? false,
      marketing: json['marketing'] as bool? ?? false,
    );
  }
}
