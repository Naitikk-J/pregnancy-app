import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/user_remote_data_source.dart';

/// Firebase-backed implementation of [AuthRepository].
///
/// Orchestrates FirebaseAuth (identity) with [UserRemoteDataSource] (the
/// account document). All thrown platform exceptions are mapped to [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required UserRemoteDataSource userDataSource,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _users = userDataSource,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final UserRemoteDataSource _users;
  final GoogleSignIn _google;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<AppUser?> watchAuthUser() {
    return _auth.authStateChanges().asyncExpand((fbUser) {
      if (fbUser == null) return Stream<AppUser?>.value(null);
      // Merge FirebaseAuth identity with the live account document so the router
      // reacts to onboarding completion (a doc change) as well as sign-in/out.
      return _users
          .watchUser(fbUser.uid)
          .map((doc) => doc ?? _fromFirebase(fbUser))
          // A transient Firestore error — e.g. permission-denied the instant
          // auth is revoked on sign-out — must NOT put the whole auth stream
          // into an error state (that traps the router on the splash and blocks
          // the redirect to login). Fall back to the FirebaseAuth identity.
          .handleError((_) {}, test: (_) => true);
    });
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    await _guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const AuthFailure();
      await user.updateDisplayName(name.trim());
      await _users.createUserIfAbsent(
        AppUser.initial(
          uid: user.uid,
          email: user.email,
          displayName: name.trim(),
          role: role,
        ),
      );
    });
  }

  @override
  Future<void> signInWithGoogle() async {
    await _guard(() async {
      // On web, the google_sign_in plugin can't return a usable ID token, so use
      // Firebase's OAuth popup flow directly (this is the recommended web path).
      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(GoogleAuthProvider());
        await _ensureUserDoc(cred.user);
        return;
      }
      final account = await _google.signIn();
      if (account == null) {
        throw const AuthFailure(message: 'Sign-in was cancelled.');
      }
      final gAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      await _ensureUserDoc(cred.user);
    });
  }

  @override
  Future<void> signInWithApple() async {
    await _guard(() async {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauth);

      // Apple only returns the name on first authorization — capture it then.
      final name = [apple.givenName, apple.familyName]
          .where((p) => p != null && p.isNotEmpty)
          .join(' ')
          .trim();
      await _ensureUserDoc(cred.user, fallbackName: name.isEmpty ? null : name);
    });
  }

  @override
  Future<void> signInAsGuest() async {
    await _guard(() async {
      final cred = await _auth.signInAnonymously();
      await _ensureUserDoc(cred.user, isAnonymous: true);
    });
  }

  @override
  Future<PhoneVerification> startPhoneVerification({
    required String phoneNumber,
    void Function()? onAutoVerified,
    int? resendToken,
  }) async {
    final completer = _PhoneCompleter();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        // Android auto-retrieval: sign in immediately.
        final cred = await _auth.signInWithCredential(credential);
        await _ensureUserDoc(cred.user);
        onAutoVerified?.call();
      },
      verificationFailed: (e) {
        completer.completeError(ErrorMapper.map(e));
      },
      codeSent: (verificationId, token) {
        completer.complete(
          PhoneVerification(verificationId: verificationId, resendToken: token),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        completer.completeIfPending(
          PhoneVerification(verificationId: verificationId),
        );
      },
    );
    return completer.future;
  }

  @override
  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    await _guard(() async {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final cred = await _auth.signInWithCredential(credential);
      await _ensureUserDoc(cred.user);
    });
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  List<String> get currentProviderIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];

  @override
  Future<void> signOut() async {
    await _guard(() async {
      // Sign out of Firebase FIRST — this is what clears the session and drives
      // the router back to login. Google's plugin signOut is best-effort (it can
      // throw on some devices / when the user didn't sign in with Google), and
      // must never block the actual sign-out.
      await _auth.signOut();
      try {
        await _google.signOut();
      } catch (_) {/* best-effort */}
    });
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    await _guard(() async {
      final user = _auth.currentUser;
      if (user == null) return;
      // Firebase requires a *recent* login to delete an account. Re-authenticate
      // first (before touching data) so we never orphan the user document.
      await _reauthenticate(user, password: password);
      await _users.deleteUserDoc(user.uid);
      await user.delete();
      try {
        await _google.signOut();
      } catch (_) {/* best-effort */}
    });
  }

  /// Re-authenticates [user] so a sensitive operation (account deletion) is
  /// allowed. Google users get an interactive re-consent; password users must
  /// supply their [password]; other providers fall through and, if the login is
  /// too old, surface Firebase's `requires-recent-login` with a clear message.
  Future<void> _reauthenticate(User user, {String? password}) async {
    final ids = user.providerData.map((p) => p.providerId).toSet();
    if (ids.contains('google.com')) {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(GoogleAuthProvider());
      } else {
        await _google.signOut();
        final g = await _google.signIn();
        if (g == null) {
          throw const AuthFailure(
              message: 'Verification cancelled — account not deleted.');
        }
        final ga = await g.authentication;
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(
              accessToken: ga.accessToken, idToken: ga.idToken),
        );
      }
    } else if (ids.contains('password')) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw const AuthFailure(
            message: 'Enter your password to delete your account.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    }
    // phone / apple / anonymous: no interactive re-auth here; user.delete() will
    // throw requires-recent-login if the session is stale (mapped for display).
  }

  // --- helpers ---

  Future<void> _ensureUserDoc(
    User? user, {
    String? fallbackName,
    bool isAnonymous = false,
  }) async {
    if (user == null) throw const AuthFailure();
    await _users.createUserIfAbsent(
      AppUser.initial(
        uid: user.uid,
        email: user.email,
        phone: user.phoneNumber,
        displayName: user.displayName ?? fallbackName,
        photoUrl: user.photoURL,
        isAnonymous: isAnonymous,
      ),
    );
  }

  AppUser _fromFirebase(User user) => AppUser.initial(
        uid: user.uid,
        email: user.email,
        phone: user.phoneNumber,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );

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

/// Small completer that ignores late completions from the auto-retrieval
/// timeout callback once [codeSent] has already resolved the future.
class _PhoneCompleter {
  final _completer = _SafeCompleter<PhoneVerification>();
  Future<PhoneVerification> get future => _completer.future;
  void complete(PhoneVerification v) => _completer.complete(v);
  void completeError(Object e) => _completer.completeError(e);
  void completeIfPending(PhoneVerification v) => _completer.complete(v);
}

class _SafeCompleter<T> {
  final _c = Completer<T>();
  Future<T> get future => _c.future;
  void complete(T value) {
    if (!_c.isCompleted) _c.complete(value);
  }

  void completeError(Object e) {
    if (!_c.isCompleted) _c.completeError(e);
  }
}
