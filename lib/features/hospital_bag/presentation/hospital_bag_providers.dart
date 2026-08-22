import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/hospital_bag_item.dart';

final hospitalBagCrudProvider = Provider<FirestoreCrud<HospitalBagItem>?>((ref) {
  final col = pregnancySubcollection(ref, 'hospital_bag');
  if (col == null) return null;
  return FirestoreCrud<HospitalBagItem>(
    collection: col,
    fromJson: HospitalBagItem.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
  );
});

/// Items the mother has toggled or added (custom).
final storedBagItemsProvider = StreamProvider<List<HospitalBagItem>>((ref) {
  final crud = ref.watch(hospitalBagCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// Full checklist: catalog (with stored packed-state merged) plus custom items.
final hospitalBagItemsProvider = Provider<List<HospitalBagItem>>((ref) {
  final stored = ref.watch(storedBagItemsProvider).valueOrNull ?? const [];
  final byId = {for (final i in stored) i.id: i};
  final catalog = [for (final i in kDefaultBagItems) byId[i.id] ?? i];
  final customs = stored.where((i) => i.custom).toList();
  return [...catalog, ...customs];
});
