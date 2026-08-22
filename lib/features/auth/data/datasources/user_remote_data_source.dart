import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/app_user.dart';

/// Data source for the `users/{uid}` account document. Kept separate from
/// FirebaseAuth so account-doc concerns (create-if-absent, live watch, updates)
/// are reusable and independently testable.
class UserRemoteDataSource {
  UserRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users');

  /// Live stream of the account document, mapped to [AppUser]. If the document
  /// does not exist yet (just after first sign-in), null is returned so callers
  /// can treat the user as "needs a document / onboarding".
  Stream<AppUser?> watchUser(String uid) {
    return _col.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return AppUser.fromJson({...data, 'uid': uid});
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _col.doc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return AppUser.fromJson({...data, 'uid': uid});
  }

  /// Creates the account document only if it does not already exist. Used on
  /// first sign-in via any provider so we never clobber an existing profile.
  Future<void> createUserIfAbsent(AppUser user) async {
    final ref = _col.doc(user.uid);
    final now = DateTime.now().toUtc();
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (snap.exists) return;
      txn.set(
        ref,
        user.copyWith(createdAt: now, updatedAt: now).toJson(),
      );
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> patch) {
    return _col.doc(uid).set(
      {...patch, 'updatedAt': DateTime.now().toUtc().toIso8601String()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteUserDoc(String uid) => _col.doc(uid).delete();
}
