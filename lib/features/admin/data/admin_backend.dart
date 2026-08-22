import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Calls the privileged admin endpoints on the AI proxy Worker (which uses a
/// Firebase service account to delete/disable login accounts). The admin's
/// Firebase ID token authenticates the request; the Worker re-checks that the
/// caller's Firestore role is `admin`.
class AdminBackend {
  AdminBackend(
    this._auth, {
    required this.endpoint,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final String endpoint;
  final http.Client _client;

  Future<void> deleteUser(String uid) =>
      _post({'task': 'admin_delete_user', 'uid': uid});

  Future<void> disableUser(String uid, {required bool disabled}) =>
      _post({'task': 'admin_disable_user', 'uid': uid, 'disabled': disabled});

  Future<void> _post(Map<String, dynamic> body) async {
    if (endpoint.isEmpty || endpoint.contains('REPLACE_ME')) {
      throw StateError('Admin backend is not configured.');
    }
    final user = _auth.currentUser;
    final token = await user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in again to continue.');
    }
    final res = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      String msg = 'Action failed (${res.statusCode}).';
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['error'] is String) msg = data['error'] as String;
      } catch (_) {}
      throw StateError(msg);
    }
  }
}
