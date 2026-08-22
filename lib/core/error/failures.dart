import 'package:equatable/equatable.dart';

/// Base type for all recoverable errors surfaced to the domain/presentation
/// layers. Using a sealed hierarchy lets callers exhaustively handle failures.
///
/// Note: Dart forbids mixing optional-positional and named parameters in one
/// constructor, so subclasses expose `message`/`cause` as **named** parameters
/// (except [ValidationFailure], whose message is a required positional).
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

/// Network / connectivity problem.
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// A backend (Firestore / Functions / Storage) error.
class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Something went wrong on our side.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Authentication / authorization error.
class AuthFailure extends Failure {
  const AuthFailure({
    String message = 'Authentication failed.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Local cache / Hive error.
class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Could not read local data.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Input validation error (safe to show verbatim to the user).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// Permission / access-control error.
class PermissionFailure extends Failure {
  const PermissionFailure({
    String message = 'You do not have access to this.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Fallback for anything unclassified.
class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'An unexpected error occurred.',
    Object? cause,
  }) : super(message, cause: cause);
}
