import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/week_content.dart';

/// Fetches week content from Firestore `weekContent/{week}`. Returns null when
/// the document doesn't exist so the repository can fall back to local content.
class WeekContentRemoteDataSource {
  WeekContentRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<WeekContent?> getWeek(int week) async {
    final snap =
        await _firestore.collection('weekContent').doc('$week').get();
    final data = snap.data();
    if (data == null) return null;
    return WeekContent.fromJson({...data, 'week': week});
  }
}
