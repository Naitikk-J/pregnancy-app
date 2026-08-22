/// App-wide constant values (no configuration/secrets here — see [AppConfig]).
class AppConstants {
  AppConstants._();

  static const String appName = 'Pregnancy Companion';

  /// A full-term pregnancy is 40 weeks / 280 days from LMP.
  static const int fullTermWeeks = 40;
  static const int fullTermDays = 280;

  /// Default daily hydration goal in millilitres.
  static const int defaultWaterGoalMl = 2500;
  static const int glassMl = 250;

  /// Hive box names.
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
  static const String secureBox = 'secure_box';
  static const String syncQueueBox = 'sync_queue_box';

  /// Secure-storage key that holds the Hive encryption key.
  static const String hiveEncryptionKeyName = 'hive_encryption_key_v1';

  /// SharedPreferences / settings keys.
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyTextScale = 'text_scale';

  /// Support & legal. Legal pages are hosted on Firebase Hosting (see
  /// web/privacy.html, web/terms.html) — deploy with `firebase deploy --only hosting`.
  static const String supportEmail = 'mausam.chouksey11@gmail.com';
  static const String privacyPolicyUrl =
      'https://pregnancy-companion-ad7b7.web.app/privacy.html';
  static const String termsUrl =
      'https://pregnancy-companion-ad7b7.web.app/terms.html';
}
