import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/water_day.dart';

/// Reads/writes the per-day water documents. Uses atomic increments so rapid
/// taps don't lose counts, and works offline via Firestore's cache.
class WaterRepository {
  WaterRepository(this._col);

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<WaterDay> watchDay(String dateKey, int goalMl) {
    return _col.doc(dateKey).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) {
        return WaterDay(dateKey: dateKey, consumedMl: 0, goalMl: goalMl);
      }
      return WaterDay.fromJson({...data, 'dateKey': dateKey});
    });
  }

  /// Appends a timestamped drink and atomically bumps the day total. Keeping the
  /// total as an increment preserves the offline-safe behaviour of rapid taps,
  /// while [WaterEntry] records exactly when each drink happened.
  Future<void> addEntry(String dateKey, WaterEntry entry, int goalMl) {
    return _col.doc(dateKey).set(
      {
        'dateKey': dateKey,
        'goalMl': goalMl,
        'consumedMl': FieldValue.increment(entry.ml),
        'entries': FieldValue.arrayUnion([entry.toJson()]),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes a single timestamped drink, recomputing the day total from the
  /// remaining entries so the ring and the log stay in sync.
  Future<void> removeEntry(WaterDay day, WaterEntry entry, int goalMl) {
    final remaining = day.entries.where((e) => e.id != entry.id).toList();
    final consumed = remaining.fold<int>(0, (acc, e) => acc + e.ml);
    return _col.doc(day.dateKey).set(
      {
        'dateKey': day.dateKey,
        'goalMl': goalMl,
        'consumedMl': consumed,
        'entries': [for (final e in remaining) e.toJson()],
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> reset(String dateKey, int goalMl) {
    return _col.doc(dateKey).set(
      WaterDay(dateKey: dateKey, consumedMl: 0, goalMl: goalMl).toJson(),
    );
  }
}
