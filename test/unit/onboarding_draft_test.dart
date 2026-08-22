import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/onboarding/presentation/controllers/onboarding_controller.dart';

void main() {
  group('OnboardingDraft', () {
    test('dueDate and currentWeek are null until LMP is set', () {
      const draft = OnboardingDraft(name: 'A');
      expect(draft.dueDate, isNull);
      expect(draft.currentWeek, isNull);
    });

    test('computes due date and week once LMP is set', () {
      final lmp = DateTime.now().subtract(const Duration(days: 14));
      final draft = OnboardingDraft(name: 'A', lmpDate: lmp);
      expect(draft.dueDate, isNotNull);
      expect(draft.currentWeek, 3); // 14 days -> week 3
    });

    test('toProfile carries fields and trims name', () {
      final draft = OnboardingDraft(
        name: '  Aisha  ',
        age: 30,
        weightKg: 60,
        heightCm: 164,
        bloodGroup: 'B+',
        medicalConditions: const ['Anemia'],
        foodPreferences: const ['Vegetarian'],
        waterGoalMl: 3000,
        lmpDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      final profile = draft.toProfile();
      expect(profile.name, 'Aisha');
      expect(profile.age, 30);
      expect(profile.waterGoalMl, 3000);
      expect(profile.medicalConditions, ['Anemia']);
    });

    test('toPregnancy builds owner membership and matching dates', () {
      final lmp = DateTime.now().subtract(const Duration(days: 50));
      final draft = OnboardingDraft(
        name: 'A',
        riskCategory: RiskCategory.high,
        lmpDate: lmp,
      );
      final preg = draft.toPregnancy(id: 'preg1', ownerUid: 'user1');
      final expectedLmp = DateTime(lmp.year, lmp.month, lmp.day);
      expect(preg.id, 'preg1');
      expect(preg.ownerUserId, 'user1');
      expect(preg.riskCategory, RiskCategory.high);
      expect(preg.isMember('user1'), isTrue);
      expect(preg.members['user1']['role'], UserRole.mother.name);
      // LMP is normalized to date-only; due date is LMP + 280 days.
      expect(preg.lmpDate, expectedLmp);
      expect(preg.dueDate, expectedLmp.add(const Duration(days: 280)));
    });
  });
}
