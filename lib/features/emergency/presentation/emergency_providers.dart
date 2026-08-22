import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/emergency_contact.dart';

final emergencyContactsCrudProvider =
    Provider<FirestoreCrud<EmergencyContact>?>((ref) {
  final col = pregnancySubcollection(ref, 'emergency_contacts');
  if (col == null) return null;
  return FirestoreCrud<EmergencyContact>(
    collection: col,
    fromJson: EmergencyContact.fromJson,
    toJson: (c) => c.toJson(),
    idOf: (c) => c.id,
    orderByField: 'createdAt',
    descending: false,
  );
});

final emergencyContactsProvider =
    StreamProvider<List<EmergencyContact>>((ref) {
  final crud = ref.watch(emergencyContactsCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// The contact to call first for SOS (the primary, else the first added).
final primaryContactProvider = Provider<EmergencyContact?>((ref) {
  final contacts = ref.watch(emergencyContactsProvider).valueOrNull ?? const [];
  if (contacts.isEmpty) return null;
  return contacts.firstWhere((c) => c.isPrimary, orElse: () => contacts.first);
});

/// Writes an SOS alert under the pregnancy so members (partner/family) can see
/// it in-app. Also returns nothing; calling/SMS is handled in the UI.
final sosCollectionProvider =
    Provider<CollectionReference<Map<String, dynamic>>?>((ref) {
  return pregnancySubcollection(ref, 'sos_alerts');
});

/// Active (unresolved) SOS alerts, newest first — shown to members as a banner.
final activeSosProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final col = ref.watch(sosCollectionProvider);
  if (col == null) return Stream.value(const []);
  return col
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
});
