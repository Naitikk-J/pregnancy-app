import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/enums.dart';
import '../../../shared/models/pregnancy.dart';
import '../../auth/data/datasources/user_remote_data_source.dart';

/// Client-side partner/family linking: a member joins a pregnancy using its id
/// as an invite code. Full invite/accept + tightened rules land with Cloud
/// Functions in a later phase; this keeps the whole flow on the client for now.
class PartnerRepository {
  PartnerRepository(this._firestore, this._users);

  final FirebaseFirestore _firestore;
  final UserRemoteDataSource _users;

  DocumentReference<Map<String, dynamic>> _ref(String id) =>
      _firestore.collection('pregnancies').doc(id);

  /// Looks up a pregnancy by its invite code (its document id).
  Future<Pregnancy?> findPregnancy(String code) async {
    final snap = await _ref(code.trim()).get();
    final data = snap.data();
    return data == null ? null : Pregnancy.fromJson({...data, 'id': snap.id});
  }

  /// Adds [uid] to the pregnancy's members and points their account at it.
  /// Returns the joined pregnancy. Throws [StateError] if the code is invalid.
  Future<Pregnancy> join({
    required String code,
    required String uid,
    required UserRole role,
  }) async {
    final pregnancy = await findPregnancy(code);
    if (pregnancy == null) {
      throw StateError('No pregnancy found for that code.');
    }
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final members = {
      ...pregnancy.members,
      uid: {'role': role.name, 'joinedAt': nowIso},
    };

    await _ref(pregnancy.id)
        .set({'members': members, 'updatedAt': nowIso}, SetOptions(merge: true));

    await _users.updateUser(uid, {
      'activePregnancyId': pregnancy.id,
      'role': role.name,
      'onboardingComplete': true,
      'linkedPregnancies': FieldValue.arrayUnion([pregnancy.id]),
    });

    return pregnancy;
  }

  /// Removes [uid] from a pregnancy's members (used to revoke access).
  Future<void> removeMember({
    required String pregnancyId,
    required String uid,
  }) async {
    final pregnancy = await findPregnancy(pregnancyId);
    if (pregnancy == null) return;
    final members = {...pregnancy.members}..remove(uid);
    await _ref(pregnancyId).set(
      {'members': members, 'updatedAt': DateTime.now().toUtc().toIso8601String()},
      SetOptions(merge: true),
    );
  }
}
