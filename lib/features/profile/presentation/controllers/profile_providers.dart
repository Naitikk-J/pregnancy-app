import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(firestoreProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

/// The current user's medical profile (live).
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream<UserProfile?>.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});

/// The current user's active pregnancy (live). Available to mothers and, once
/// invites are wired, to linked partners/family/doctors.
final activePregnancyProvider = StreamProvider<Pregnancy?>((ref) {
  final pid = ref.watch(currentUserProvider)?.activePregnancyId;
  if (pid == null) return Stream<Pregnancy?>.value(null);
  return ref.watch(profileRepositoryProvider).watchPregnancy(pid);
});
