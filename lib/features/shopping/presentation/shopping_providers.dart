import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/shopping_item.dart';

final shoppingCrudProvider = Provider<FirestoreCrud<ShoppingItem>?>((ref) {
  final col = pregnancySubcollection(ref, 'shopping');
  if (col == null) return null;
  return FirestoreCrud<ShoppingItem>(
    collection: col,
    fromJson: ShoppingItem.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
  );
});

/// Items the mother has toggled or added (custom).
final storedShoppingProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final crud = ref.watch(shoppingCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// Full list: catalog (with stored bought-state merged) plus custom items.
final shoppingItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final stored = ref.watch(storedShoppingProvider).valueOrNull ?? const [];
  final byId = {for (final i in stored) i.id: i};
  final catalog = [for (final i in kDefaultShoppingItems) byId[i.id] ?? i];
  final customs = stored.where((i) => i.custom).toList();
  return [...catalog, ...customs];
});
