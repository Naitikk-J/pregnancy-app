import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/sleep_entry.dart';

final sleepCrudProvider = Provider<FirestoreCrud<SleepEntry>?>((ref) {
  final col = pregnancySubcollection(ref, 'sleep');
  if (col == null) return null;
  return FirestoreCrud<SleepEntry>(
    collection: col,
    fromJson: SleepEntry.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'loggedAt',
    descending: true,
  );
});

/// All sleep entries, newest first.
final sleepEntriesProvider = StreamProvider<List<SleepEntry>>((ref) {
  final crud = ref.watch(sleepCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 90);
});

/// Average hours over the most recent [days] entries (0 if none).
final sleepAverageProvider = Provider<double>((ref) {
  final entries = ref.watch(sleepEntriesProvider).valueOrNull ?? const [];
  if (entries.isEmpty) return 0;
  final recent = entries.take(7).toList();
  final total = recent.fold<double>(0, (sum, e) => sum + e.hours);
  return total / recent.length;
});
