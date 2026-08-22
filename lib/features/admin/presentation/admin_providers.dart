import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/di/providers.dart';
import '../../../shared/models/app_user.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../community/data/community_repository.dart';
import '../../community/presentation/community_providers.dart';
import '../data/admin_backend.dart';

/// Whether the signed-in user is an admin. The `admin` role can only be set
/// server-side / via the Firebase console (never self-assigned — see
/// firestore.rules), so trusting the user-doc role here is safe.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRole.admin;
});

/// All user accounts (admin-only; the live rules let admins read every user
/// doc). Sorted newest-first client-side.
final adminUsersProvider = StreamProvider<List<AppUser>>((ref) {
  if (!ref.watch(isAdminProvider)) return Stream.value(const []);
  final fs = ref.watch(firestoreProvider);
  return fs.collection('users').limit(500).snapshots().map((snap) {
    final users = snap.docs
        .map((d) => AppUser.fromJson({...d.data(), 'uid': d.id}))
        .toList();
    users.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return users;
  });
});

/// Simple platform stats for the admin overview.
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  if (!ref.watch(isAdminProvider)) return const AdminStats();
  final fs = ref.watch(firestoreProvider);
  Future<int> count(Query q) async {
    try {
      final r = await q.count().get();
      return r.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  final users = await count(fs.collection('users'));
  final posts = await count(fs.collection('community_posts'));
  final doctors =
      await count(fs.collection('users').where('role', isEqualTo: 'doctor'));
  final pregnancies = await count(fs.collection('pregnancies'));
  return AdminStats(
    users: users,
    posts: posts,
    doctors: doctors,
    pregnancies: pregnancies,
  );
});

class AdminStats {
  const AdminStats({
    this.users = 0,
    this.posts = 0,
    this.doctors = 0,
    this.pregnancies = 0,
  });
  final int users;
  final int posts;
  final int doctors;
  final int pregnancies;
}

final adminActionsProvider = Provider<AdminActions>((ref) {
  return AdminActions(
    ref.watch(firestoreProvider),
    ref.watch(communityRepositoryProvider),
  );
});

/// Privileged admin backend (delete/disable login accounts) via the Worker.
final adminBackendProvider = Provider<AdminBackend>((ref) {
  return AdminBackend(
    ref.watch(firebaseAuthProvider),
    endpoint: ref.watch(appConfigProvider).aiEndpoint,
  );
});

class AdminActions {
  AdminActions(this._fs, this._community);
  final FirebaseFirestore _fs;
  final CommunityRepository _community;

  /// Sets a user's role (used to provision or revoke doctors). Admin-only;
  /// enforced by firestore.rules `isAdmin()`.
  Future<void> setUserRole(String uid, UserRole role) {
    return _fs.collection('users').doc(uid).set(
      {'role': role.name, 'updatedAt': DateTime.now().toUtc().toIso8601String()},
      SetOptions(merge: true),
    );
  }

  /// Removes an inappropriate community post.
  Future<void> deletePost(String id) => _community.deletePost(id);
}
