import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/error/failures.dart';
import 'package:pregnancy_companion/core/error/result.dart';

void main() {
  group('Result', () {
    const success = Result<int>.success(21);
    const failure = Result<int>.failure(NetworkFailure());

    test('exposes success/failure flags and values', () {
      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);
      expect(success.valueOrNull, 21);
      expect(success.failureOrNull, isNull);

      expect(failure.isFailure, isTrue);
      expect(failure.isSuccess, isFalse);
      expect(failure.valueOrNull, isNull);
      expect(failure.failureOrNull, isA<NetworkFailure>());
    });

    test('when() routes to the correct branch', () {
      expect(
        success.when(onSuccess: (v) => 'ok $v', onFailure: (_) => 'err'),
        'ok 21',
      );
      expect(
        failure.when(onSuccess: (_) => 'ok', onFailure: (f) => f.message),
        'No internet connection.',
      );
    });

    test('map transforms success and preserves failure', () {
      final doubled = success.map((v) => v * 2);
      expect(doubled.valueOrNull, 42);

      final mappedFailure = failure.map((v) => v * 2);
      expect(mappedFailure.isFailure, isTrue);
      expect(mappedFailure.failureOrNull, isA<NetworkFailure>());
    });
  });
}
