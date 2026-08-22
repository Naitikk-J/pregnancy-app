import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Wraps Firebase Analytics so the rest of the app depends on our interface,
/// not the SDK directly (swappable, testable, and safely no-ops if disabled).
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics, this.enabled = true})
      : _analytics = analytics;

  final FirebaseAnalytics? _analytics;
  final bool enabled;

  FirebaseObserver get navigatorObserver => FirebaseObserver(this);

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (!enabled || _analytics == null) {
      if (kDebugMode) debugPrint('[analytics] $name $params');
      return;
    }
    await _analytics.logEvent(name: name, parameters: params);
  }

  Future<void> logScreenView(String screenName) async {
    if (!enabled || _analytics == null) return;
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> setUserId(String? id) async {
    if (!enabled || _analytics == null) return;
    await _analytics.setUserId(id: id);
  }

  Future<void> setUserProperty(String name, String? value) async {
    if (!enabled || _analytics == null) return;
    await _analytics.setUserProperty(name: name, value: value);
  }
}

/// Route observer that logs screen views. Lives here to keep analytics wiring
/// in one place; registered with GoRouter in the router config.
class FirebaseObserver extends NavigatorObserver {
  FirebaseObserver(this._service);
  final AnalyticsService _service;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) _service.logScreenView(name);
    super.didPush(route, previousRoute);
  }
}
