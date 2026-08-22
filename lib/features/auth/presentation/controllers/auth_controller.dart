import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Action controller for authentication. Its [AsyncValue] state represents the
/// progress of the *last triggered action* (idle/loading/error) so screens can
/// show spinners and error messages without managing their own flags.
class AuthController extends AsyncNotifier<void> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  FutureOr<void> build() {
    // No initial async work; starts synchronously in the idle (data) state so
    // buttons don't briefly show a loading spinner on first render.
  }

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) =>
      _run(() => _repo.registerWithEmail(
            email: email,
            password: password,
            name: name,
            role: role,
          ));

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<bool> signInWithApple() => _run(_repo.signInWithApple);

  Future<bool> signInAsGuest() => _run(_repo.signInAsGuest);

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<bool> signOut() async {
    final ok = await _run(_repo.signOut);
    // Force the auth-state stream to re-read now, so the router's redirect
    // reacts to sign-out immediately (avoids a lag where it still sees the old
    // user and bounces back to Home — seen on web).
    ref.invalidate(authUserProvider);
    return ok;
  }

  /// Provider ids for the current user (e.g. 'google.com', 'password').
  List<String> get providerIds => _repo.currentProviderIds;

  Future<bool> deleteAccount({String? password}) =>
      _run(() => _repo.deleteAccount(password: password));

  /// Runs [action], reflecting progress in [state]. Returns true on success so
  /// callers can navigate / show confirmation.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    state = result;
    return !result.hasError;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
