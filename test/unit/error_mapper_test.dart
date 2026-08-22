import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/error/error_mapper.dart';
import 'package:pregnancy_companion/core/error/failures.dart';

void main() {
  group('ErrorMapper', () {
    test('passes an existing Failure straight through', () {
      const original = ValidationFailure('Bad input');
      expect(ErrorMapper.map(original), same(original));
    });

    test('maps auth exceptions to a friendly AuthFailure', () {
      final failure = ErrorMapper.map(
        FirebaseAuthException(code: 'wrong-password'),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Incorrect email or password.');
    });

    test('maps permission-denied to PermissionFailure', () {
      final failure = ErrorMapper.map(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(failure, isA<PermissionFailure>());
    });

    test('maps unavailable to NetworkFailure', () {
      final failure = ErrorMapper.map(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(failure, isA<NetworkFailure>());
    });

    test('maps other Firebase exceptions to ServerFailure', () {
      final failure = ErrorMapper.map(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'aborted',
          message: 'Transaction aborted',
        ),
      );
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Transaction aborted');
    });

    test('falls back to UnknownFailure and keeps the cause', () {
      final cause = Exception('boom');
      final failure = ErrorMapper.map(cause);
      expect(failure, isA<UnknownFailure>());
      expect(failure.cause, same(cause));
    });
  });
}
