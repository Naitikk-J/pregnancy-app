import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/weight_entry.dart';

final weightCrudProvider = Provider<FirestoreCrud<WeightEntry>?>((ref) {
  final col = pregnancySubcollection(ref, 'weight');
  if (col == null) return null;
  return FirestoreCrud<WeightEntry>(
    collection: col,
    fromJson: WeightEntry.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'loggedAt',
    descending: true,
  );
});

/// All weight entries, newest first.
final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  final crud = ref.watch(weightCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});
