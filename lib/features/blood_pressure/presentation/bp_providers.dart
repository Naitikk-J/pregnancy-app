import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/bp_reading.dart';

final bpCrudProvider = Provider<FirestoreCrud<BpReading>?>((ref) {
  final col = pregnancySubcollection(ref, 'blood_pressure');
  if (col == null) return null;
  return FirestoreCrud<BpReading>(
    collection: col,
    fromJson: BpReading.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'loggedAt',
    descending: true,
  );
});

/// All blood-pressure readings, newest first.
final bpReadingsProvider = StreamProvider<List<BpReading>>((ref) {
  final crud = ref.watch(bpCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 120);
});
