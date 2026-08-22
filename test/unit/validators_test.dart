import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
    test('accepts valid', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('requires length and mix', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('allletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('abcd1234'), isNull);
    });
  });

  group('Validators.phone', () {
    test('validates digits with optional +', () {
      expect(Validators.phone('+919876543210'), isNull);
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('98765'), isNotNull); // too short (< 7 digits)
      expect(Validators.phone('abc'), isNotNull);
    });
  });
}
