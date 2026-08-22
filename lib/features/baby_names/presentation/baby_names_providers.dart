import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/baby_name.dart';

final favoriteNamesCrudProvider = Provider<FirestoreCrud<FavoriteName>?>((ref) {
  final col = pregnancySubcollection(ref, 'favoriteNames');
  if (col == null) return null;
  return FirestoreCrud<FavoriteName>(
    collection: col,
    fromJson: FavoriteName.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'savedAt',
    descending: true,
  );
});

/// The mother's saved names, newest first.
final favoriteNamesProvider = StreamProvider<List<FavoriteName>>((ref) {
  final crud = ref.watch(favoriteNamesCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// Fast membership set of favourited slugs, for toggling hearts in the list.
final favoriteSlugsProvider = Provider<Set<String>>((ref) {
  final favs = ref.watch(favoriteNamesProvider).valueOrNull ?? const [];
  return favs.map((f) => f.id).toSet();
});
