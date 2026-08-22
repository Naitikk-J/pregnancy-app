import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/di/providers.dart';

/// Immutable app-wide UI settings.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localeCode = 'en',
    this.textScale = 1.0,
  });

  final AppThemeMode themeMode;
  final String localeCode;
  final double textScale;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Locale get locale => Locale(localeCode);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? localeCode,
    double? textScale,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
        textScale: textScale ?? this.textScale,
      );

  Map<String, dynamic> toJson() => {
        AppConstants.keyThemeMode: themeMode.name,
        AppConstants.keyLocale: localeCode,
        AppConstants.keyTextScale: textScale,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == json[AppConstants.keyThemeMode],
          orElse: () => AppThemeMode.system,
        ),
        localeCode: json[AppConstants.keyLocale] as String? ?? 'en',
        textScale: (json[AppConstants.keyTextScale] as num?)?.toDouble() ?? 1.0,
      );
}

/// Persists and exposes [AppSettings]. Backed by the settings Hive box so
/// preferences survive restarts and are available offline.
class AppSettingsNotifier extends Notifier<AppSettings> {
  static const String _docId = 'app_settings';

  @override
  AppSettings build() {
    final store = ref.watch(localStorageProvider(LocalBox.settings));
    final json = store.get(_docId);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<void> _persist(AppSettings next) async {
    state = next;
    await ref
        .read(localStorageProvider(LocalBox.settings))
        .put(_docId, next.toJson());
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  Future<void> setLocale(String code) =>
      _persist(state.copyWith(localeCode: code));

  Future<void> setTextScale(double scale) =>
      _persist(state.copyWith(textScale: scale.clamp(0.8, 1.6)));
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
