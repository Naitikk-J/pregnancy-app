import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles **push** notifications via Firebase Cloud Messaging: community
/// activity, doctor messages, admin broadcasts. Token registration is persisted
/// to the user document (done in the auth/profile phase).
class PushMessagingService {
  PushMessagingService({FirebaseMessaging? messaging}) : _injected = messaging;

  final FirebaseMessaging? _injected;

  // Resolved lazily: `FirebaseMessaging.instance` throws when there's no default
  // Firebase app, so touching it in the constructor would crash startup on
  // builds without a Firebase config. Only the messaging methods (called only
  // when Firebase is ready) resolve it.
  FirebaseMessaging get _messaging => _injected ?? FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (kDebugMode) {
      // getToken() hangs indefinitely when Firebase is only partially
      // configured (e.g. no google-services.json), so never block startup on it.
      try {
        final token =
            await _messaging.getToken().timeout(const Duration(seconds: 5));
        debugPrint('[fcm] token: $token');
      } catch (e) {
        debugPrint('[fcm] token unavailable: $e');
      }
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}

/// Top-level background handler required by FCM. Registered in bootstrap.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep minimal; heavy work belongs in Cloud Functions. Data is persisted when
  // the app next opens and reads the `notifications` collection.
  if (kDebugMode) debugPrint('[fcm-bg] ${message.messageId}');
}
