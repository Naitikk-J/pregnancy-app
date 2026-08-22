import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/pregnancy.dart';

/// Read access for a doctor over the pregnancies they are linked to. A doctor
/// joins a patient using the pregnancy's invite code (its id), which adds the
/// pregnancy to their `linkedPregnancies` — this repository reads those.
class DoctorRepository {
  DoctorRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _pregnancies =>
      _firestore.collection('pregnancies');

  /// Streams the doctor's patients (linked pregnancies). Firestore `whereIn`
  /// caps at 30 ids; a doctor with more patients would need paging (later).
  Stream<List<Pregnancy>> watchPatients(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const []);
    final chunk = ids.take(30).toList();
    return _pregnancies
        .where(FieldPath.documentId, whereIn: chunk)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Pregnancy.fromJson({...d.data(), 'id': d.id}))
            .toList(growable: false));
  }

  /// Latest document in a patient's tracker subcollection (or null if empty).
  Stream<Map<String, dynamic>?> watchLatest(String pid, String sub) {
    return _pregnancies
        .doc(pid)
        .collection(sub)
        .orderBy('loggedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : {...snap.docs.first.data(), 'id': snap.docs.first.id});
  }
}
