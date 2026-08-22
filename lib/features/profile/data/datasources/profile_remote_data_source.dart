import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/pregnancy.dart';
import '../../../../shared/models/user_profile.dart';

/// Firestore access for the profile & pregnancy documents.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('profile').doc('main');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _pregnancyRef(String id) =>
      _firestore.collection('pregnancies').doc(id);

  /// Atomic onboarding completion using a batched write.
  Future<void> completeOnboarding({
    required String uid,
    required String roleName,
    required UserProfile profile,
    required Pregnancy pregnancy,
  }) async {
    final batch = _firestore.batch();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    batch.set(_profileRef(uid), profile.toJson());
    batch.set(_pregnancyRef(pregnancy.id), pregnancy.toJson());
    batch.set(
      _userRef(uid),
      {
        'onboardingComplete': true,
        'activePregnancyId': pregnancy.id,
        'role': roleName,
        'displayName': profile.name,
        'linkedPregnancies': FieldValue.arrayUnion([pregnancy.id]),
        'updatedAt': nowIso,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Creates a fresh pregnancy owned by [uid] and repoints the account at it.
  ///
  /// Used by data recovery when the account's `activePregnancyId` became
  /// inaccessible (e.g. it belongs to a *different* account after an account
  /// switch, or the pregnancy doc was deleted) so tracker reads were denied.
  /// Unlike [completeOnboarding], this preserves the existing profile document.
  Future<void> createPregnancyForUser({
    required String uid,
    required Pregnancy pregnancy,
  }) async {
    final batch = _firestore.batch();
    batch.set(_pregnancyRef(pregnancy.id), pregnancy.toJson());
    batch.set(
      _userRef(uid),
      {
        'onboardingComplete': true,
        'activePregnancyId': pregnancy.id,
        'linkedPregnancies': FieldValue.arrayUnion([pregnancy.id]),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _profileRef(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : UserProfile.fromJson(data);
    });
  }

  Future<void> updateProfile(String uid, UserProfile profile) {
    return _profileRef(uid).set(profile.toJson(), SetOptions(merge: true));
  }

  Stream<Pregnancy?> watchPregnancy(String id) {
    return _pregnancyRef(id).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : Pregnancy.fromJson({...data, 'id': id});
    });
  }

  Future<void> updatePregnancy(Pregnancy pregnancy) {
    return _pregnancyRef(pregnancy.id).set(
      {
        ...pregnancy.toJson(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}
