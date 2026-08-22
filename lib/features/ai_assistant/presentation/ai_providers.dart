import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/pregnancy_calculator.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../../settings/ai_key_providers.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return AiRepository(
    ref.watch(firebaseAuthProvider),
    endpoint: config.aiEndpoint,
    lang: ref.watch(appSettingsProvider).localeCode,
    userKey: ref.watch(userGeminiKeyProvider).valueOrNull ?? '',
  );
});

/// Holds the in-memory chat transcript and drives sending.
class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._ref) : super(const []);

  final Ref _ref;
  static const _uuid = Uuid();

  bool get isBusy => state.any((m) => m.pending);

  void reset() => state = const [];

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isBusy) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: trimmed,
    );
    final pendingId = _uuid.v4();
    final pending = ChatMessage(
      id: pendingId,
      role: ChatRole.assistant,
      text: '',
      pending: true,
    );
    state = [...state, userMsg, pending];

    try {
      final reply = await _ref.read(aiRepositoryProvider).send(
            history: state,
            context: _buildContext(),
          );
      _replace(pendingId, (m) => m.copyWith(text: reply, pending: false));
    } catch (_) {
      _replace(
        pendingId,
        (m) => m.copyWith(
          text: 'Sorry, I couldn’t reach the assistant. Please check your '
              'connection and try again.',
          pending: false,
          isError: true,
        ),
      );
    }
  }

  void _replace(String id, ChatMessage Function(ChatMessage) update) {
    state = [
      for (final m in state)
        if (m.id == id) update(m) else m,
    ];
  }

  /// Lightweight, non-identifying pregnancy context passed to the model so
  /// answers can be tailored to how far along the mother is.
  Map<String, dynamic> _buildContext() {
    final profile = _ref.read(userProfileProvider).valueOrNull;
    final pregnancy = _ref.read(activePregnancyProvider).valueOrNull;
    final ctx = <String, dynamic>{};
    if (profile != null && profile.name.isNotEmpty) {
      ctx['name'] = profile.name;
    }
    if (pregnancy != null) {
      final week = PregnancyCalculator.currentWeek(pregnancy.lmpDate);
      ctx['currentWeek'] = week;
      ctx['trimester'] =
          PregnancyCalculator.trimesterForWeek(week).label;
      ctx['dueDate'] =
          pregnancy.dueDate.toIso8601String().split('T').first;
    }
    return ctx;
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>(
  (ref) => ChatController(ref),
);
