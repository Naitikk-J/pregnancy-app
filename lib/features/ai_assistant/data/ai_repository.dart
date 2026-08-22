import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/chat_message.dart';

/// Talks to the "Ask Mira" AI proxy — a small serverless endpoint (a Cloudflare
/// Worker on the free tier; see `worker/`) that holds the Claude API key
/// server-side. The key never reaches the client.
///
/// Auth: the caller's Firebase ID token is sent as a Bearer token and verified
/// by the Worker, so only signed-in app users can use it. Sends the running
/// conversation plus lightweight pregnancy context and returns the reply text.
class AiRepository {
  AiRepository(
    this._auth, {
    required this.endpoint,
    this.lang = 'en',
    this.userKey = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final FirebaseAuth _auth;

  /// The Worker's HTTPS URL (from [AppConfig.aiEndpoint]).
  final String endpoint;

  /// The user's language code ('en'/'hi'); the Worker replies in this language.
  final String lang;

  /// The user's OWN Gemini API key (optional). When non-empty it's sent so the
  /// request runs on the user's own free-tier quota.
  final String userKey;

  final http.Client _client;

  Future<String> send({
    required List<ChatMessage> history,
    Map<String, dynamic> context = const {},
  }) async {
    if (endpoint.isEmpty || endpoint.contains('REPLACE_ME')) {
      throw StateError('AI endpoint is not configured (see worker/README.md).');
    }
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to use the assistant.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not obtain an auth token.');
    }

    final messages = history
        .where((m) => !m.pending && !m.isError && m.text.trim().isNotEmpty)
        .map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList(growable: false);

    final res = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'messages': messages,
            'context': context,
            'lang': lang,
            if (userKey.isNotEmpty) 'userKey': userKey,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw StateError('Assistant error (${res.statusCode}).');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final reply = data['reply'];
    if (reply is String && reply.trim().isNotEmpty) return reply.trim();
    throw StateError('Empty assistant reply.');
  }
}
