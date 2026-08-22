import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../auth/presentation/controllers/auth_providers.dart';

/// Wires Firebase Cloud Messaging to the signed-in account:
/// - saves the device FCM token to `users/{uid}.fcmTokens` (so the backend can
///   target this device once Cloud Functions land),
/// - shows foreground messages as local notifications.
///
/// Fully guarded: if Firebase/FCM isn't available (e.g. no config) it no-ops so
/// it can never break the app shell.
class PushController {
  PushController(this._ref);

  final Ref _ref;
  StreamSubscription<dynamic>? _foregroundSub;
  StreamSubscription<String>? _tokenSub;
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final push = _ref.read(pushMessagingServiceProvider);
    final notifications = _ref.read(notificationServiceProvider);

    try {
      final token =
          await push.getToken().timeout(const Duration(seconds: 5));
      if (token != null) await _saveToken(user.uid, token);

      _tokenSub ??= push.onTokenRefresh.listen((token) {
        final current = _ref.read(currentUserProvider);
        if (current != null) _saveToken(current.uid, token);
      });

      _foregroundSub ??= push.onForegroundMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        notifications.show(
          id: message.hashCode & 0x7fffffff,
          title: n.title ?? 'Pregnancy Companion',
          body: n.body ?? '',
        );
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[push] setup skipped: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await _ref.read(userRemoteDataSourceProvider).updateUser(uid, {
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[push] token save skipped: $e');
    }
  }

  void dispose() {
    _foregroundSub?.cancel();
    _tokenSub?.cancel();
  }
}

final pushControllerProvider = Provider<PushController>((ref) {
  final controller = PushController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
