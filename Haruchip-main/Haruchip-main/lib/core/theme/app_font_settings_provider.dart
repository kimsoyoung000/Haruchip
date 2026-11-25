import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../services/storage/local_store.dart';

/// 앱 전역 글꼴 종류 프리셋
enum AppFontFamilyOption {
  system(labelKo: '기본 시스템', fontFamily: null),
  pretendard(labelKo: '프리텐다드', fontFamily: 'Pretendard'),
  nanumSquareRound(labelKo: '나눔스퀘어라운드', fontFamily: 'NanumSquareRound'),
  maruBuri(labelKo: '마루부리', fontFamily: 'MaruBuri'),
  cookieRun(labelKo: '쿠키런', fontFamily: 'CookieRun'),
  gmarketSans(labelKo: '지마켓산스', fontFamily: 'GmarketSans');

  const AppFontFamilyOption({
    required this.labelKo,
    required this.fontFamily,
  });

  final String labelKo;
  final String? fontFamily;

  static AppFontFamilyOption fromName(String? name) {
    for (final opt in values) {
      if (opt.name == name) return opt;
    }
    return AppFontFamilyOption.system;
  }
}

/// 앱 전역 글자 크기 배율 프리셋
enum AppFontSizeOption {
  small(labelKo: '작게', scale: 0.92),
  normal(labelKo: '보통', scale: 1.0),
  large(labelKo: '크게', scale: 1.08),
  extraLarge(labelKo: '아주 크게', scale: 1.16);

  const AppFontSizeOption({
    required this.labelKo,
    required this.scale,
  });

  final String labelKo;
  final double scale;

  static AppFontSizeOption fromName(String? name) {
    for (final opt in values) {
      if (opt.name == name) return opt;
    }
    return AppFontSizeOption.normal;
  }
}

/// 앱 전역 폰트 설정 상태 ([프로필 & 설정] > [앱 환경설정] 관리)
@immutable
class AppFontSettings {
  const AppFontSettings({
    this.fontFamily = AppFontFamilyOption.system,
    this.fontSize = AppFontSizeOption.normal,
  });

  final AppFontFamilyOption fontFamily;
  final AppFontSizeOption fontSize;

  AppFontSettings copyWith({
    AppFontFamilyOption? fontFamily,
    AppFontSizeOption? fontSize,
  }) {
    return AppFontSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fontFamily': fontFamily.name,
        'fontSize': fontSize.name,
      };

  factory AppFontSettings.fromJson(Map<String, dynamic> json) {
    return AppFontSettings(
      fontFamily: AppFontFamilyOption.fromName(json['fontFamily'] as String?),
      fontSize: AppFontSizeOption.fromName(json['fontSize'] as String?),
    );
  }
}

class AppFontSettingsNotifier extends Notifier<AppFontSettings> {
  @override
  AppFontSettings build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) {
      store.writeString(
        LocalStoreKeys.appFontSettings,
        jsonEncode(next.toJson()),
      );
    });

    final raw = store.readString(LocalStoreKeys.appFontSettings);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          return AppFontSettings.fromJson(map);
        }
      } catch (_) {}
    }
    return const AppFontSettings();
  }

  void setFontFamily(AppFontFamilyOption option) {
    state = state.copyWith(fontFamily: option);
  }

  void setFontSize(AppFontSizeOption option) {
    state = state.copyWith(fontSize: option);
  }
}

final appFontSettingsProvider =
    NotifierProvider<AppFontSettingsNotifier, AppFontSettings>(
  AppFontSettingsNotifier.new,
);

/// [프로필 & 설정] > [앱 환경설정] > [글꼴 및 글자 크기 설정] 바텀시트
Future<void> showAppFontSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AppFontSettingsSheet(),
  );
}

class _AppFontSettingsSheet extends ConsumerWidget {
  const _AppFontSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appFontSettingsProvider);
    final notifier = ref.read(appFontSettingsProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      '글꼴 및 글자 크기 설정',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.protoSubtitle,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 실시간 미리보기 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cleanCanvasBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '하루의 소중한 조각들을 담아봐요',
                        style: TextStyle(
                          fontFamily: settings.fontFamily.fontFamily,
                          fontSize: 15.5 * settings.fontSize.scale,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '선택한 글꼴과 크기가 칩 데이, 캘린더, 모임 화면에 일관되게 적용됩니다.',
                        style: TextStyle(
                          fontFamily: settings.fontFamily.fontFamily,
                          fontSize: 12.5 * settings.fontSize.scale,
                          color: AppColors.protoSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 1. 글꼴 종류 선택
                const Text(
                  '글꼴 스타일',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.protoHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppFontFamilyOption.values.map((opt) {
                    final isSelected = settings.fontFamily == opt;
                    return InkWell(
                      onTap: () => notifier.setFontFamily(opt),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.chipYellowBg
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.chipGoldOutline
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          opt.labelKo,
                          style: TextStyle(
                            fontFamily: opt.fontFamily,
                            fontSize: 13.5,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.chipYellowText
                                : AppColors.protoCardText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 2. 글자 크기 선택
                const Text(
                  '글자 크기',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.protoHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: AppFontSizeOption.values.map((opt) {
                    final isSelected = settings.fontSize == opt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => notifier.setFontSize(opt),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.chipYellowBg
                                  : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.chipGoldOutline
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              opt.labelKo,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.chipYellowText
                                    : AppColors.protoCardText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chipYellowBg,
                      foregroundColor: AppColors.chipYellowText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '적용 완료',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
