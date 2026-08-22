import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/birth_plan.dart';

/// Reference to the single birth-plan document under the active pregnancy.
final _birthPlanDocProvider =
    Provider<DocumentReference<Map<String, dynamic>>?>((ref) {
  final col = pregnancySubcollection(ref, 'birthPlan');
  return col?.doc('plan');
});

/// The saved birth plan (defaults to a blank plan when none exists yet).
final birthPlanProvider = StreamProvider<BirthPlan>((ref) {
  final doc = ref.watch(_birthPlanDocProvider);
  if (doc == null) return Stream.value(const BirthPlan());
  return doc.snapshots().map((snap) {
    final data = snap.data();
    if (data == null) return const BirthPlan();
    return BirthPlan.fromJson({...data, 'id': snap.id});
  });
});

/// Persists the whole plan (merge write).
final saveBirthPlanProvider =
    Provider<Future<void> Function(BirthPlan)>((ref) {
  final doc = ref.watch(_birthPlanDocProvider);
  return (plan) async {
    if (doc == null) throw StateError('No active pregnancy.');
    await doc.set(
      plan.copyWith(updatedAt: DateTime.now()).toJson(),
      SetOptions(merge: true),
    );
  };
});
