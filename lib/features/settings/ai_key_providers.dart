import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';

const String _kGeminiKeyStoreKey = 'user_gemini_api_key';

/// The user's OWN (optional) Gemini API key, held in the device keystore
/// ([FlutterSecureStorage]). When set, the app sends it to the AI proxy so the
/// user's requests run on THEIR own free-tier quota instead of the shared one —
/// so heavy users never hit a shared limit. Empty/null → use the shared key.
final userGeminiKeyProvider =
    AsyncNotifierProvider<GeminiKeyController, String?>(GeminiKeyController.new);

class GeminiKeyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final store = ref.watch(secureStorageProvider);
    final v = await store.read(key: _kGeminiKeyStoreKey);
    return (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  /// Saves (or, if empty, clears) the user's key.
  Future<void> setKey(String key) async {
    final store = ref.read(secureStorageProvider);
    final k = key.trim();
    if (k.isEmpty) {
      await store.delete(key: _kGeminiKeyStoreKey);
      state = const AsyncData(null);
    } else {
      await store.write(key: _kGeminiKeyStoreKey, value: k);
      state = AsyncData(k);
    }
  }

  Future<void> clear() => setKey('');
}
