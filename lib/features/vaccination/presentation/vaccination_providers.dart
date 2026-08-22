import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/vaccine.dart';

final vaccineCrudProvider = Provider<FirestoreCrud<Vaccine>?>((ref) {
  final col = pregnancySubcollection(ref, 'vaccinations');
  if (col == null) return null;
  return FirestoreCrud<Vaccine>(
    collection: col,
    fromJson: Vaccine.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
  );
});

/// Stored vaccine records (only those the mother has acted on).
final storedVaccinesProvider = StreamProvider<List<Vaccine>>((ref) {
  final crud = ref.watch(vaccineCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// The full catalog with each mother's stored status merged in.
final vaccineListProvider = Provider<List<Vaccine>>((ref) {
  final stored = ref.watch(storedVaccinesProvider).valueOrNull ?? const [];
  final byId = {for (final v in stored) v.id: v};
  return [for (final v in kDefaultVaccines) byId[v.id] ?? v];
});
