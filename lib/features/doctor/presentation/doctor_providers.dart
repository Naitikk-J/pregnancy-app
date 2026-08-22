import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/di/providers.dart';
import '../../../shared/models/pregnancy.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../blood_pressure/domain/bp_reading.dart';
import '../../blood_sugar/domain/glucose_reading.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../../weight/domain/weight_entry.dart';
import '../data/doctor_repository.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(firestoreProvider));
});

/// Whether the signed-in user is a doctor (drives portal visibility).
final isDoctorProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRole.doctor;
});

/// The doctor's linked patients (pregnancies).
final doctorPatientsProvider = StreamProvider<List<Pregnancy>>((ref) {
  final ids = ref.watch(currentUserProvider)?.linkedPregnancies ?? const [];
  return ref.watch(doctorRepositoryProvider).watchPatients(ids);
});

/// A patient's medical profile (the pregnancy owner's).
final patientProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, ownerUid) {
  return ref.watch(profileRepositoryProvider).watchProfile(ownerUid);
});

final latestWeightProvider =
    StreamProvider.family<WeightEntry?, String>((ref, pid) {
  return ref
      .watch(doctorRepositoryProvider)
      .watchLatest(pid, 'weight')
      .map((m) => m == null ? null : WeightEntry.fromJson(m));
});

final latestBpProvider = StreamProvider.family<BpReading?, String>((ref, pid) {
  return ref
      .watch(doctorRepositoryProvider)
      .watchLatest(pid, 'blood_pressure')
      .map((m) => m == null ? null : BpReading.fromJson(m));
});

final latestGlucoseProvider =
    StreamProvider.family<GlucoseReading?, String>((ref, pid) {
  return ref
      .watch(doctorRepositoryProvider)
      .watchLatest(pid, 'blood_sugar')
      .map((m) => m == null ? null : GlucoseReading.fromJson(m));
});
