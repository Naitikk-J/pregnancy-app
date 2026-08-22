import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/core/utils/id_utils.dart';
import 'package:pregnancy_companion/features/appointments/domain/appointment.dart';
import 'package:pregnancy_companion/features/medicine/domain/medicine.dart';
import 'package:pregnancy_companion/features/water/domain/water_day.dart';

void main() {
  group('WaterDay', () {
    test('progress clamps to 1.0 and computes glasses', () {
      const day = WaterDay(dateKey: '2026-01-01', consumedMl: 3000, goalMl: 2500);
      expect(day.progress, 1.0);
      expect(day.glasses, 12); // 3000 / 250
      expect(day.goalGlasses, 10);
    });

    test('round-trips through JSON', () {
      const day = WaterDay(dateKey: '2026-01-02', consumedMl: 750, goalMl: 2000);
      final restored = WaterDay.fromJson(day.toJson());
      expect(restored, day);
    });
  });

  group('Medicine', () {
    final med = Medicine(
      id: 'm1',
      name: 'Iron',
      dosage: '1 tablet',
      times: const ['09:00', '21:00'],
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      timing: MedicineTiming.afterFood,
    );

    test('isActiveOn respects date range and active flag', () {
      expect(med.isActiveOn(DateTime(2026, 1, 15)), isTrue);
      expect(med.isActiveOn(DateTime(2025, 12, 31)), isFalse);
      expect(med.isActiveOn(DateTime(2026, 2, 1)), isFalse);
      expect(med.copyWith(active: false).isActiveOn(DateTime(2026, 1, 15)),
          isFalse);
    });

    test('needsRefillSoon flags within 3 days', () {
      final soon = Medicine(
        id: 'm2',
        name: 'Calcium',
        dosage: '1',
        times: const ['08:00'],
        startDate: DateTime.now(),
        refillDate: DateTime.now().add(const Duration(days: 2)),
      );
      expect(soon.needsRefillSoon, isTrue);
      expect(med.needsRefillSoon, isFalse); // no refill date
    });

    test('serializes and restores', () {
      final restored = Medicine.fromJson(med.toJson());
      expect(restored.name, 'Iron');
      expect(restored.times, ['09:00', '21:00']);
      expect(restored.timing, MedicineTiming.afterFood);
    });
  });

  group('Appointment', () {
    test('reminderTime subtracts the lead minutes', () {
      final appt = Appointment(
        id: 'a1',
        title: 'Scan',
        dateTime: DateTime(2026, 5, 1, 10, 0),
        reminderMinutesBefore: 120,
      );
      expect(appt.reminderTime, DateTime(2026, 5, 1, 8, 0));
    });

    test('isUpcoming reflects status and future date', () {
      final future = Appointment(
        id: 'a2',
        title: 'Check-up',
        dateTime: DateTime.now().add(const Duration(days: 2)),
      );
      final past = Appointment(
        id: 'a3',
        title: 'Old',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(future.isUpcoming, isTrue);
      expect(past.isUpcoming, isFalse);
      expect(future.copyWith(status: 'cancelled').isUpcoming, isFalse);
    });
  });

  group('IdUtils', () {
    test('stableNotificationId is deterministic and non-negative', () {
      final a = IdUtils.stableNotificationId('med_m1_09:00');
      final b = IdUtils.stableNotificationId('med_m1_09:00');
      final c = IdUtils.stableNotificationId('med_m1_21:00');
      expect(a, b);
      expect(a, isNot(c));
      expect(a, greaterThanOrEqualTo(0));
      expect(a, lessThanOrEqualTo(0x7fffffff));
    });

    test('dateKey formats yyyy-MM-dd', () {
      expect(IdUtils.dateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });
}
