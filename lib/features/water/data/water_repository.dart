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

  Future<void> addMl(String dateKey, int deltaMl, int goalMl) {
    return _col.doc(dateKey).set(
      {
        'dateKey': dateKey,
        'goalMl': goalMl,
        'consumedMl': FieldValue.increment(deltaMl),
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
