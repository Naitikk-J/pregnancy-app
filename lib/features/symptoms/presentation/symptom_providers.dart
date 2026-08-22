import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/symptom_entry.dart';

final symptomCrudProvider = Provider<FirestoreCrud<SymptomEntry>?>((ref) {
  final col = pregnancySubcollection(ref, 'symptoms');
  if (col == null) return null;
  return FirestoreCrud<SymptomEntry>(
    collection: col,
    fromJson: SymptomEntry.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'loggedAt',
    descending: true,
  );
});

final symptomEntriesProvider = StreamProvider<List<SymptomEntry>>((ref) {
  final crud = ref.watch(symptomCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 100);
});
