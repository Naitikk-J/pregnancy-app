/// Build flavors for the app. Selected in `main_*.dart` entrypoints (added when
/// flavors are wired natively) or defaulted to [Flavor.production].
enum Flavor { development, staging, production }

/// Immutable runtime configuration. Holds environment-specific values only —
/// never secrets (those come from Firebase / Remote Config / Functions).
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.enableCrashlytics,
    required this.enableAnalytics,
    required this.aiEndpoint,
  });

  final Flavor flavor;
  final bool enableCrashlytics;
  final bool enableAnalytics;

  /// HTTPS URL of the "Ask Mira" AI proxy (a Cloudflare Worker on the free tier —
  /// see `worker/README.md`). The Claude API key lives on that server only, never
  /// in the client. After deploying the Worker, replace the `REPLACE_ME`
  /// placeholder below with its URL, or pass `--dart-define=AI_ENDPOINT=...` at
  /// build time (the dart-define wins).
  final String aiEndpoint;

  /// Worker URL. Edit the default after deploying, or override with
  /// `--dart-define=AI_ENDPOINT=https://pregnancy-ai.<subdomain>.workers.dev`.
  static const String _aiEndpoint = String.fromEnvironment(
    'AI_ENDPOINT',
    defaultValue: 'https://pregnancy-ai.mausam-chouksey11.workers.dev',
  );

  bool get isProduction => flavor == Flavor.production;
  bool get isDevelopment => flavor == Flavor.development;

  static const AppConfig development = AppConfig(
    flavor: Flavor.development,
    enableCrashlytics: false,
    enableAnalytics: false,
    aiEndpoint: _aiEndpoint,
  );

  static const AppConfig staging = AppConfig(
    flavor: Flavor.staging,
    enableCrashlytics: true,
    enableAnalytics: true,
    aiEndpoint: _aiEndpoint,
  );

  static const AppConfig production = AppConfig(
    flavor: Flavor.production,
    enableCrashlytics: true,
    enableAnalytics: true,
    aiEndpoint: _aiEndpoint,
  );
}
