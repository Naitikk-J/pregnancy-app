import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/diagnostics.dart' as diag;
import 'core/di/providers.dart';
import 'core/local/hive_initializer.dart';
import 'core/local/local_storage.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_messaging_service.dart';

/// Composition root. Performs all async initialization, builds the top-level
/// dependency overrides, and launches the app. Called from `main.dart`.
///
/// Firebase init is guarded so the UI still boots during local development
/// before `flutterfire configure` has been run.
Future<void> bootstrap({AppConfig config = AppConfig.production}) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // TEMP boot probe (diag-2): paint a bright, unmistakably-not-green frame
      // after each milestone. Whatever stage label is frozen on the device tells
      // us exactly where startup dies; if the screen stays green, Dart/the engine
      // never painted at all (a native/install problem). Remove once diagnosed.
      _bootStage('1 · binding ready');

      final firebaseReady = await _initFirebase();
      _bootStage('2 · firebase=$firebaseReady');

      // If Firebase could not initialize, the whole app tree is unusable: the
      // router builds `_RouterNotifier`, which listens to `authUserProvider` →
      // `firebaseAuthProvider` (`FirebaseAuth.instance`), and that throws
      // `[core/no-app]` when there is no default Firebase app. That throw lands
      // in the root widget's *synchronous build*, so every frame throws and
      // none ever rasterizes — leaving the app frozen on the native launch
      // (green) screen forever. Worse, the `firebaseInitError` diagnostic on the
      // splash can never show, because the crash is upstream of `MaterialApp`.
      // So when Firebase is down, skip the Firebase-dependent tree entirely and
      // show the real reason instead of a silent green screen.
      if (!firebaseReady) {
        if (kDebugMode) {
          debugPrint('[bootstrap] Firebase not ready — showing startup error '
              'instead of the (Firebase-dependent) app: '
              '${diag.firebaseInitError}');
        }
        runApp(_StartupErrorApp(
          message: diag.firebaseInitError ??
              'Firebase could not start on this device.',
          onRetry: () => bootstrap(config: config),
        ));
        return;
      }

      // --- Local storage (Hive, encrypted) ---
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      // Storage init is self-healing (see HiveInitializer), but bound it with a
      // timeout too: a wedged keystore call must never leave the app frozen on
      // the native launch (green) screen. If it still fails, show a real error
      // screen instead of hanging — `runApp` must always be reached.
      try {
        await HiveInitializer(secureStorage)
            .init()
            .timeout(const Duration(seconds: 15));
      } catch (e, st) {
        diag.firebaseInitError ??= 'Local storage failed to open: $e';
        if (kDebugMode) debugPrint('[bootstrap] storage init failed: $e\n$st');
        runApp(_StartupErrorApp(
          message: '$e',
          onRetry: () => bootstrap(config: config),
        ));
        return;
      }

      _bootStage('3 · storage open');

      final settingsBox = Hive.box<String>(AppConstants.settingsBox);
      final cacheBox = Hive.box<String>(AppConstants.cacheBox);
      final secureBox = Hive.box<String>(AppConstants.secureBox);
      final syncQueueBox = Hive.box<String>(AppConstants.syncQueueBox);

      // --- Services ---
      final crash = CrashService(
        enabled: firebaseReady && config.enableCrashlytics,
      );
      await crash.install();

      final analytics = AnalyticsService(
        analytics: firebaseReady ? FirebaseAnalytics.instance : null,
        enabled: firebaseReady && config.enableAnalytics,
      );

      final notifications = NotificationService();
      await _guardedInit('notifications', notifications.init);

      final push = PushMessagingService();
      if (firebaseReady) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await _guardedInit('push', push.init);
      }

      _bootStage('4 · services ready — building app');

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            analyticsServiceProvider.overrideWithValue(analytics),
            crashServiceProvider.overrideWithValue(crash),
            notificationServiceProvider.overrideWithValue(notifications),
            pushMessagingServiceProvider.overrideWithValue(push),
            localStorageProvider.overrideWith((ref, box) {
              return LocalStorage(switch (box) {
                LocalBox.settings => settingsBox,
                LocalBox.cache => cacheBox,
                LocalBox.secure => secureBox,
                LocalBox.syncQueue => syncQueueBox,
              });
            }),
          ],
          child: const PregnancyCompanionApp(),
        ),
      );
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught zone error: $error\n$stack');
      }
    },
  );
}

/// TEMP diagnostic (diag-2): paints a bright orange full-screen frame labelled
/// with the current boot [stage]. Because each stage repaints, the *last* stage
/// reached stays on screen if bootstrap then hangs or crashes — turning the
/// silent green screen into a precise "it died here" marker. Remove once fixed.
void _bootStage(String stage) {
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFFF6D00), // deep orange — never the brand green
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Text(
          'Starting…\n$stage\n(build: diag-2)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    ),
  );
}

/// Last-resort UI shown when local storage cannot be opened even after the
/// self-healing reset. It replaces the frozen native launch screen with a clear
/// message and a close action, so the app is never a silent green screen.
class _StartupErrorApp extends StatefulWidget {
  const _StartupErrorApp({required this.message, this.onRetry});
  final String message;

  /// Re-attempts startup. When it succeeds it calls `runApp` and replaces this
  /// whole tree; when it fails it re-shows an error app. Either way this widget
  /// is torn down, so the callback needs no return value.
  final Future<void> Function()? onRetry;

  @override
  State<_StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<_StartupErrorApp> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    final onRetry = widget.onRetry;
    if (onRetry == null) return;
    setState(() => _retrying = true);
    try {
      await onRetry();
    } catch (_) {
      // `bootstrap` guards itself and always ends by calling `runApp`; if it
      // somehow returns without relaunching, drop the spinner so the button is
      // usable again.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      "We couldn't start the app on this device.",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your internet connection, then close the '
                      'app fully and reopen it. If it keeps happening, '
                      'reinstall the app to reset local data.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message.length > 1500
                          ? message.substring(0, 1500)
                          : message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (widget.onRetry != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _retrying ? null : _handleRetry,
                        icon: _retrying
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(_retrying ? 'Retrying…' : 'Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs an optional service initializer without letting it block app startup:
/// failures are logged and a hung plugin (e.g. FCM `getToken` with no valid
/// Firebase config) is bounded by a timeout so `runApp` is always reached.
Future<void> _guardedInit(String name, Future<void> Function() init) async {
  try {
    await init().timeout(const Duration(seconds: 10));
  } catch (e) {
    if (kDebugMode) debugPrint('[bootstrap] "$name" init skipped: $e');
  }
}

/// Attempts to initialize Firebase. Returns false (and logs) if native config
/// is missing, so the app can still run for UI development.
Future<bool> _initFirebase() async {
  try {
    // Bound native init with a timeout: on some devices (bad Play-Services
    // state, no network at boot) `initializeApp` can hang, which would freeze
    // the app on the native launch screen. Timing out lets the UI still load.
    //
    // Guard against re-initialization: a "Try again" retry (or a timed-out init
    // that actually completed in the background) can leave a default app already
    // present — calling `initializeApp` again would throw `[core/duplicate-app]`.
    // Reuse the existing app in that case.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
    }
    // Enable offline persistence so all Firestore-backed trackers work offline
    // and sync automatically on reconnect.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    diag.firebaseInitError = null; // clear any stale error from a failed attempt
    return true;
  } catch (e, st) {
    diag.firebaseInitError = '$e\n\n$st'; // TEMP: surface real cause on splash
    if (kDebugMode) {
      debugPrint(
        'Firebase not initialized ($e). Run `flutterfire configure`. '
        'UI will still load; auth/data features require Firebase.',
      );
    }
    return false;
  }
}
