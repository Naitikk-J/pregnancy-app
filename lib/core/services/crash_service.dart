import 'dart:async';

import 'package:flutter/foundation.dart';

/// Central crash & error reporting.
///
/// NOTE (2026-08-09): Firebase Crashlytics was removed because its native
/// component failed to initialize in **release** builds
/// ("FirebaseCrashlytics component is not present"), which made
/// `Firebase.initializeApp()` throw and the app hang on the splash on real
/// devices. This now routes errors to the console; re-introduce a crash reporter
/// later (Crashlytics with aligned Firebase versions, or Sentry) if desired. The
/// public API is unchanged so callers need no edits.
class CrashService {
  CrashService({this.enabled = true});

  final bool enabled;

  /// Wire the global Flutter error handler. Call once at boot.
  Future<void> install() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) debugPrint('[crash] ${details.exceptionAsString()}');
    };
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (kDebugMode) debugPrint('[crash] $reason $error\n$stack');
  }

  Future<void> setUserId(String? id) async {}

  Future<void> log(String message) async {
    if (kDebugMode) debugPrint('[crash] $message');
  }
}
