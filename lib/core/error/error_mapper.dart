import 'package:firebase_auth/firebase_auth.dart';

import 'failures.dart';

/// Converts low-level exceptions into user-safe [Failure]s.
///
/// Keep raw error details in [Failure.cause] for logging/Crashlytics, but only
/// surface the friendly [Failure.message] to users.
class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error, [StackTrace? _]) {
    if (error is Failure) return error;

    if (error is FirebaseAuthException) {
      return AuthFailure(message: _authMessage(error.code), cause: error);
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return PermissionFailure(cause: error);
      }
      if (error.code == 'unavailable') {
        return const NetworkFailure();
      }
      return ServerFailure(message: error.message ?? 'Server error.', cause: error);
    }
    return UnknownFailure(cause: error);
  }

  static String _authMessage(String code) => switch (code) {
        'invalid-email' => 'That email address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Please choose a stronger password.',
        'operation-not-allowed' => 'This sign-in method is not enabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Network error. Check your connection.',
        'invalid-verification-code' => 'That verification code is incorrect.',
        _ => 'Authentication failed. Please try again.',
      };
}
