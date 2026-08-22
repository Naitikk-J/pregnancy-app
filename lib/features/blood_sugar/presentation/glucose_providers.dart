import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/glucose_reading.dart';

final glucoseCrudProvider = Provider<FirestoreCrud<GlucoseReading>?>((ref) {
  final col = pregnancySubcollection(ref, 'blood_sugar');
  if (col == null) return null;
  return FirestoreCrud<GlucoseReading>(
    collection: col,
    fromJson: GlucoseReading.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'loggedAt',
    descending: true,
  );
});

/// All blood-sugar readings, newest first.
final glucoseReadingsProvider = StreamProvider<List<GlucoseReading>>((ref) {
  final crud = ref.watch(glucoseCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 120);
});
