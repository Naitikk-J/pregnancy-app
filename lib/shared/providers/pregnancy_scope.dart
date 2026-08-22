import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';

/// The active pregnancy id for the signed-in user, or null. Every tracker is
/// scoped under `pregnancies/{pid}`, so features watch this to know where to
/// read/write.
final currentPregnancyIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.activePregnancyId;
});

/// A reference to a subcollection under the active pregnancy, e.g.
/// `pregnancies/{pid}/medicines`. Null when there is no active pregnancy.
CollectionReference<Map<String, dynamic>>? pregnancySubcollection(
  Ref ref,
  String name,
) {
  final pid = ref.watch(currentPregnancyIdProvider);
  if (pid == null) return null;
  return ref
      .watch(firestoreProvider)
      .collection('pregnancies')
      .doc(pid)
      .collection(name);
}
