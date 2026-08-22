import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/shared/models/app_user.dart';
import 'package:pregnancy_companion/shared/models/pregnancy.dart';
import 'package:pregnancy_companion/shared/models/user_profile.dart';

void main() {
  group('AppUser JSON', () {
    test('round-trips through toJson/fromJson', () {
      final user = AppUser(
        uid: 'u1',
        role: UserRole.doctor,
        email: 'doc@example.com',
        onboardingComplete: true,
        activePregnancyId: 'p1',
        linkedPregnancies: const ['p1', 'p2'],
        isPremium: true,
        createdAt: DateTime.utc(2025, 1, 1),
      );
      final restored = AppUser.fromJson(user.toJson());
      expect(restored, user);
      expect(restored.role, UserRole.doctor);
      expect(restored.linkedPregnancies, ['p1', 'p2']);
    });

    test('initial user defaults to mother, not onboarded', () {
      final u = AppUser.initial(uid: 'x');
      expect(u.role, UserRole.mother);
      expect(u.onboardingComplete, isFalse);
    });
  });

  group('UserProfile JSON', () {
    test('round-trips and defaults water goal', () {
      const profile = UserProfile(
        name: 'Aisha',
        age: 29,
        weightKg: 62.5,
        heightCm: 165,
        bloodGroup: 'O+',
        medicalConditions: ['Thyroid'],
        foodPreferences: ['Vegetarian'],
      );
      final restored = UserProfile.fromJson(profile.toJson());
      expect(restored, profile);
      expect(restored.waterGoalMl, greaterThan(0));
    });
  });

  group('Pregnancy JSON', () {
    test('round-trips and computes derived week', () {
      final lmp = DateTime.now().subtract(const Duration(days: 70)); // ~week 11
      final preg = Pregnancy(
        id: 'p1',
        ownerUserId: 'u1',
        lmpDate: lmp,
        dueDate: lmp.add(const Duration(days: 280)),
        riskCategory: RiskCategory.medium,
        members: const {
          'u1': {'role': 'mother', 'permissions': ['owner']},
        },
      );
      final json = preg.toJson();
      // Denormalized fields are present for cheap reads.
      expect(json['currentWeek'], preg.currentWeek);
      expect(json['trimester'], preg.trimester.name);

      final restored = Pregnancy.fromJson(json);
      expect(restored.id, 'p1');
      expect(restored.riskCategory, RiskCategory.medium);
      expect(restored.isMember('u1'), isTrue);
      expect(restored.currentWeek, inInclusiveRange(10, 12));
    });
  });
}
