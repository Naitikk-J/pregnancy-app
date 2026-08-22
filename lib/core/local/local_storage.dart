import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Thin, JSON-based wrapper over Hive boxes.
///
/// We deliberately store JSON maps (encoded strings) rather than generating
/// Hive `TypeAdapter`s. This keeps the offline layer codegen-free and lets every
/// feature reuse the same box mechanics: a document is `{id: json}`.
class LocalStorage {
  LocalStorage(this._box);

  final Box<String> _box;

  /// Upsert a single document keyed by [id].
  Future<void> put(String id, Map<String, dynamic> data) =>
      _box.put(id, jsonEncode(data));

  /// Read a single document, or null if absent.
  Map<String, dynamic>? get(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// All documents in insertion order.
  List<Map<String, dynamic>> getAll() => _box.values
      .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
      .toList(growable: false);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  bool containsKey(String id) => _box.containsKey(id);

  /// Emits on any change so Riverpod providers can re-read reactively.
  Stream<BoxEvent> watch() => _box.watch();
}
