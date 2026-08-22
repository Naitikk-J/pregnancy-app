import '../../../../core/constants/enums.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../../shared/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<void> completeOnboarding({
    required String uid,
    required UserRole role,
    required UserProfile profile,
    required Pregnancy pregnancy,
  }) async {
    await _guard(() => _remote.completeOnboarding(
          uid: uid,
          roleName: role.name,
          profile: profile,
          pregnancy: pregnancy,
        ));
  }

  @override
  Future<void> createPregnancyForUser({
    required String uid,
    required Pregnancy pregnancy,
  }) =>
      _guard(() => _remote.createPregnancyForUser(uid: uid, pregnancy: pregnancy));

  @override
  Stream<UserProfile?> watchProfile(String uid) => _remote.watchProfile(uid);

  @override
  Future<void> updateProfile(String uid, UserProfile profile) =>
      _guard(() => _remote.updateProfile(uid, profile));

  @override
  Stream<Pregnancy?> watchPregnancy(String pregnancyId) =>
      _remote.watchPregnancy(pregnancyId);

  @override
  Future<void> updatePregnancy(Pregnancy pregnancy) =>
      _guard(() => _remote.updatePregnancy(pregnancy));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
