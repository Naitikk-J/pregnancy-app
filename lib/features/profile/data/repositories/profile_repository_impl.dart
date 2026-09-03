import '../../../../core/constants/enums.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../../shared/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;
  final Map<String, UserProfile> _profileCache = {};
  final Map<String, Pregnancy> _pregnancyCache = {};

  @override
  Future<void> completeOnboarding({
    required String uid,
    required UserRole role,
    required UserProfile profile,
    required Pregnancy pregnancy,
  }) async {
    _profileCache[uid] = profile;
    _pregnancyCache[pregnancy.id] = pregnancy;

    try {
      await _remote
          .completeOnboarding(
            uid: uid,
            roleName: role.name,
            profile: profile,
            pregnancy: pregnancy,
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // In guest / offline mode or when Firebase is unconfigured,
      // the local cache preserves the session so the user can continue.
    }
  }

  @override
  Future<void> createPregnancyForUser({
    required String uid,
    required Pregnancy pregnancy,
  }) async {
    _pregnancyCache[pregnancy.id] = pregnancy;
    try {
      await _remote
          .createPregnancyForUser(uid: uid, pregnancy: pregnancy)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Fallback to local
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _remote
        .watchProfile(uid)
        .map<UserProfile?>((p) => p ?? _profileCache[uid])
        .handleError((_) {})
        .map((p) => p ?? _profileCache[uid]);
  }

  @override
  Future<void> updateProfile(String uid, UserProfile profile) async {
    _profileCache[uid] = profile;
    try {
      await _remote.updateProfile(uid, profile);
    } catch (_) {
      // Fallback to local
    }
  }

  @override
  Stream<Pregnancy?> watchPregnancy(String pregnancyId) {
    return _remote
        .watchPregnancy(pregnancyId)
        .map<Pregnancy?>((p) => p ?? _pregnancyCache[pregnancyId])
        .handleError((_) {})
        .map((p) => p ?? _pregnancyCache[pregnancyId]);
  }

  @override
  Future<void> updatePregnancy(Pregnancy pregnancy) async {
    _pregnancyCache[pregnancy.id] = pregnancy;
    try {
      await _remote.updatePregnancy(pregnancy);
    } catch (_) {
      // Fallback to local
    }
  }


}
