import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../../../shared/providers/ticker_provider.dart';
import '../domain/contraction.dart';
import '../domain/contraction_analysis.dart';

final contractionCrudProvider = Provider<FirestoreCrud<Contraction>?>((ref) {
  final col = pregnancySubcollection(ref, 'contractions');
  if (col == null) return null;
  return FirestoreCrud<Contraction>(
    collection: col,
    fromJson: Contraction.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'startedAt',
    descending: true,
  );
});

/// All recorded contractions, newest first.
final contractionsProvider = StreamProvider<List<Contraction>>((ref) {
  final crud = ref.watch(contractionCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 200);
});

/// Live 5-1-1 analysis of recent contractions. Re-runs each second (via the
/// ticker) so the rolling 1-hour window stays current even when nothing new is
/// logged. Auto-disposes with the screen so the ticker stops.
final contractionAnalysisProvider =
    Provider.autoDispose<ContractionAnalysis>((ref) {
  ref.watch(tickerProvider);
  final contractions = ref.watch(contractionsProvider).valueOrNull ?? const [];
  return ContractionAnalyzer.analyze(contractions);
});

/// The contraction currently in progress (in memory), persisted when stopped.
class ActiveContractionController extends Notifier<Contraction?> {
  @override
  Contraction? build() => null;

  void start() {
    if (state != null) return;
    state = Contraction(id: const Uuid().v4(), startedAt: DateTime.now());
  }

  Future<void> stop() async {
    final current = state;
    if (current == null) return;
    final done = current.copyWith(endedAt: DateTime.now());
    state = null;
    await ref.read(contractionCrudProvider)?.upsert(done);
  }

  void discard() => state = null;
}

final activeContractionProvider =
    NotifierProvider<ActiveContractionController, Contraction?>(
        ActiveContractionController.new);
