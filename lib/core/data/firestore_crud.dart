import 'package:cloud_firestore/cloud_firestore.dart';

/// A tiny generic CRUD/stream helper over a Firestore collection, so each
/// tracker repository stays a few lines. Documents are stored as JSON maps
/// (dates as ISO-8601 strings), which sort chronologically with `orderBy` and
/// round-trip through the offline cache.
class FirestoreCrud<T> {
  FirestoreCrud({
    required this.collection,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    this.orderByField,
    this.descending = true,
  });

  final CollectionReference<Map<String, dynamic>> collection;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;
  final String? orderByField;
  final bool descending;

  Stream<List<T>> watch({int? limit}) {
    Query<Map<String, dynamic>> query = collection;
    if (orderByField != null) {
      query = query.orderBy(orderByField!, descending: descending);
    }
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) => fromJson({...doc.data(), 'id': doc.id}))
              .toList(growable: false),
        );
  }

  Future<T?> getById(String id) async {
    final snap = await collection.doc(id).get();
    final data = snap.data();
    return data == null ? null : fromJson({...data, 'id': id});
  }

  Future<void> upsert(T item) =>
      collection.doc(idOf(item)).set(toJson(item), SetOptions(merge: true));

  Future<void> delete(String id) => collection.doc(id).delete();
}
