import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/kick_session.dart';

final kickCrudProvider = Provider<FirestoreCrud<KickSession>?>((ref) {
  final col = pregnancySubcollection(ref, 'kick_sessions');
  if (col == null) return null;
  return FirestoreCrud<KickSession>(
    collection: col,
    fromJson: KickSession.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'startedAt',
    descending: true,
  );
});

/// Completed & in-progress kick sessions that were persisted, newest first.
final kickSessionsProvider = StreamProvider<List<KickSession>>((ref) {
  final crud = ref.watch(kickCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 60);
});

/// The session currently being counted, held in memory until it's finished (or
/// discarded) so rapid taps stay snappy and offline. It's persisted to
/// Firestore when the target is reached or the mother taps "finish".
class ActiveKickSessionController extends Notifier<KickSession?> {
  @override
  KickSession? build() => null;

  void start({int target = KickSession.defaultTarget}) {
    state = KickSession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      kickCount: 0,
      targetKicks: target,
    );
  }

  /// Records one movement. When the target is reached the session auto-completes
  /// and is persisted, but stays on screen so the mother sees the result.
  void addKick() {
    final current = state;
    if (current == null || current.isComplete) return;
    final next = current.copyWith(kickCount: current.kickCount + 1);
    if (next.kickCount >= next.targetKicks) {
      final done = next.copyWith(endedAt: DateTime.now());
      state = done;
      _persist(done);
    } else {
      state = next;
    }
  }

  /// Stops and saves the current session (even if the target wasn't reached).
  Future<void> finish() async {
    final current = state;
    if (current == null) return;
    final done =
        current.isComplete ? current : current.copyWith(endedAt: DateTime.now());
    await _persist(done);
    state = null;
  }

  /// Throws away the in-progress session without saving.
  void discard() => state = null;

  Future<void> _persist(KickSession session) =>
      ref.read(kickCrudProvider)?.upsert(session) ?? Future.value();
}

final activeKickSessionProvider =
    NotifierProvider<ActiveKickSessionController, KickSession?>(
        ActiveKickSessionController.new);
