import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/models/app_user.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Data source for the account document.
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(firestoreProvider));
});

/// The auth repository — the single seam the rest of the app uses for identity.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(firebaseAuthProvider),
    userDataSource: ref.watch(userRemoteDataSourceProvider),
  );
});

/// Live authenticated user (or null). Drives router redirects and greets the
/// user across the app. Emits again whenever the account document changes.
final authUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthUser();
});

/// Convenience: the current [AppUser] value or null (non-reactive read helper).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authUserProvider).valueOrNull;
});

/// Convenience: whether someone is signed in right now.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
