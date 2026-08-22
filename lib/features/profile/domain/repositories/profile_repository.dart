import '../../../../core/constants/enums.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../../shared/models/user_profile.dart';

/// Contract for reading/writing the medical profile and the active pregnancy.
abstract interface class ProfileRepository {
  /// Finalizes onboarding atomically: writes the profile, creates the
  /// pregnancy, and flips `onboardingComplete` on the account document.
  Future<void> completeOnboarding({
    required String uid,
    required UserRole role,
    required UserProfile profile,
    required Pregnancy pregnancy,
  });

  /// Creates a fresh pregnancy owned by [uid] and points the account at it,
  /// preserving the existing profile. Used to recover from an inaccessible
  /// (foreign or deleted) active pregnancy.
  Future<void> createPregnancyForUser({
    required String uid,
    required Pregnancy pregnancy,
  });

  Stream<UserProfile?> watchProfile(String uid);

  Future<void> updateProfile(String uid, UserProfile profile);

  Stream<Pregnancy?> watchPregnancy(String pregnancyId);

  Future<void> updatePregnancy(Pregnancy pregnancy);
}
