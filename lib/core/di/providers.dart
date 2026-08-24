import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../local/local_storage.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/crash_service.dart';
import '../services/notification_service.dart';
import '../services/push_messaging_service.dart';

/// Central dependency-injection wiring using Riverpod as the DI container.
///
/// Providers marked "override in bootstrap" are constructed asynchronously at
/// app start (in `bootstrap.dart`) and injected via `ProviderScope(overrides:)`.
/// This keeps `main()` the single composition root while every feature reads
/// dependencies through these providers — fully testable via overrides.

/// _Overridden in bootstrap._ The active build configuration.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Firebase instances (safe to read once Firebase.initializeApp has completed)
// ---------------------------------------------------------------------------

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseStorageProvider =
    Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final functionsProvider =
    Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);

// ---------------------------------------------------------------------------
// Platform / local
// ---------------------------------------------------------------------------

final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ));

/// _Overridden in bootstrap._ Named local storage boxes.
enum LocalBox { settings, cache, secure, syncQueue }

final localStorageProvider = Provider.family<LocalStorage, LocalBox>(
  (ref, box) =>
      throw UnimplementedError('localStorageProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Services (overridden in bootstrap after their async init completes)
// ---------------------------------------------------------------------------

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => throw UnimplementedError('analyticsServiceProvider override needed'),
);

final crashServiceProvider = Provider<CrashService>(
  (ref) => throw UnimplementedError('crashServiceProvider override needed'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) =>
      throw UnimplementedError('notificationServiceProvider override needed'),
);

/// Current notification/alarm readiness (permission + exact-alarm state), used
/// to warn the user in-app when reminders would be silently blocked. Invalidate
/// it after requesting permissions to refresh the banners.
final notificationStatusProvider =
    FutureProvider<NotificationStatus>((ref) async {
  return ref.read(notificationServiceProvider).status();
});

final pushMessagingServiceProvider = Provider<PushMessagingService>(
  (ref) =>
      throw UnimplementedError('pushMessagingServiceProvider override needed'),
);

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityService());

/// Reactive online/offline flag for the whole app.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onStatusChange;
});
