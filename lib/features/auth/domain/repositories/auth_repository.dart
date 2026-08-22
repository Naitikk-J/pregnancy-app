import '../../../../core/constants/enums.dart';
import '../../../../shared/models/app_user.dart';

/// Result of starting a phone-number verification. The [verificationId] is
/// needed to confirm the SMS code the user receives.
class PhoneVerification {
  const PhoneVerification({required this.verificationId, this.resendToken});
  final String verificationId;
  final int? resendToken;
}

/// Contract for all authentication operations. The presentation layer depends
/// only on this interface; the Firebase implementation lives in the data layer.
abstract interface class AuthRepository {
  /// Emits the current [AppUser] (with live profile-doc changes) or null when
  /// signed out. Drives router redirects.
  Stream<AppUser?> watchAuthUser();

  /// The current signed-in uid, or null.
  String? get currentUid;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signInAsGuest();

  /// Starts phone verification. On some platforms auto-retrieval may complete
  /// sign-in immediately; [onAutoVerified] is invoked in that case.
  Future<PhoneVerification> startPhoneVerification({
    required String phoneNumber,
    void Function()? onAutoVerified,
    int? resendToken,
  });

  /// Confirms the SMS [smsCode] against a prior [verificationId].
  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// The sign-in provider ids for the current user (e.g. 'google.com',
  /// 'password', 'phone'). Empty when signed out.
  List<String> get currentProviderIds;

  /// Permanently deletes the account and signs out (GDPR erasure). Re-authenticates
  /// first: [password] is required for email/password accounts; Google accounts
  /// re-consent interactively.
  Future<void> deleteAccount({String? password});
}
