import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/medicine/domain/medicine.dart';

void main() {
  group('defaultDoseTimes', () {
    test('spreads doses across the day by frequency', () {
      expect(defaultDoseTimes(1), ['09:00']);
      expect(defaultDoseTimes(2), ['09:00', '21:00']);
      expect(defaultDoseTimes(3).length, 3);
      expect(defaultDoseTimes(4).length, 4);
      expect(defaultDoseTimes(6).length, 6);
    });

    test('clamps low values to a single time', () {
      expect(defaultDoseTimes(0), ['09:00']);
    });
  });

  group('Medicine serialization', () {
    test('round-trips the new asNeeded + durationDays fields', () {
      final m = Medicine(
        id: 'm1',
        name: 'Iron',
        dosage: '1 tablet',
        timing: MedicineTiming.afterFood,
        times: const ['09:00', '21:00'],
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 1, 6),
        asNeeded: false,
        durationDays: 5,
      );
      final back = Medicine.fromJson(m.toJson());
      expect(back.durationDays, 5);
      expect(back.asNeeded, isFalse);
      expect(back.timesPerDay, 2);
    });

    test('SOS medicine has no times and no duration', () {
      final m = Medicine(
        id: 'm2',
        name: 'Paracetamol',
        dosage: '500 mg',
        times: const [],
        startDate: DateTime.utc(2026, 1, 1),
        asNeeded: true,
      );
      final back = Medicine.fromJson(m.toJson());
      expect(back.asNeeded, isTrue);
      expect(back.times, isEmpty);
      expect(back.durationDays, isNull);
    });

    test('defaults asNeeded to false for legacy docs without the field', () {
      final back = Medicine.fromJson({
        'id': 'old',
        'name': 'Calcium',
        'dosage': '1 tablet',
        'times': ['08:00'],
        'startDate': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      expect(back.asNeeded, isFalse);
      expect(back.durationDays, isNull);
      expect(back.times, ['08:00']);
    });
  });

  Medicine med({
    String dosage = '1 tablet',
    List<String> times = const ['09:00', '21:00'],
    int? durationDays = 30,
    DateTime? endDate,
    bool active = true,
    bool asNeeded = false,
  }) =>
      Medicine(
        id: 'm',
        name: 'Iron',
        dosage: dosage,
        times: times,
        startDate: DateTime(2026, 1, 1),
        endDate: endDate,
        durationDays: durationDays,
        active: active,
        asNeeded: asNeeded,
      );

  group('quantity to buy', () {
    test('unitsPerDose reads the leading number, defaulting to 1', () {
      expect(med(dosage: '2 tablets').unitsPerDose, 2);
      expect(med(dosage: 'tablet').unitsPerDose, 1);
      expect(med(dosage: '').unitsPerDose, 1);
    });

    test('courseUnits = units/dose × times/day × days', () {
      // 1 tablet × 2/day × 30 days = 60
      expect(med().courseUnits, 60);
      // 2 tablets × 3/day × 10 days = 60
      expect(
        med(dosage: '2 tablets', times: const ['08:00', '14:00', '20:00'], durationDays: 10)
            .courseUnits,
        60,
      );
    });

    test('courseUnits is null for ongoing or SOS meds', () {
      expect(med(durationDays: null).courseUnits, isNull);
      expect(med(asNeeded: true, times: const [], durationDays: null).courseUnits,
          isNull);
    });
  });

  group('course ending', () {
    test('daysUntilEnd counts whole days to the end date', () {
      final end = DateTime.now().add(const Duration(days: 2));
      expect(med(endDate: end).daysUntilEnd, 2);
    });

    test('endingSoon is true within the window and false outside it', () {
      final soon = DateTime.now().add(const Duration(days: 2));
      final far = DateTime.now().add(const Duration(days: 20));
      expect(med(endDate: soon).endingSoon(), isTrue);
      expect(med(endDate: far).endingSoon(), isFalse);
      expect(med(endDate: soon, active: false).endingSoon(), isFalse);
    });

    test('endingSoon is false for meds without an end date', () {
      expect(med(endDate: null).endingSoon(), isFalse);
    });
  });
}
