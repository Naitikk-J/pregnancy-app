import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/features/calendar/domain/calendar_event.dart';
import 'package:pregnancy_companion/features/exercise/domain/exercise_guide.dart';
import 'package:pregnancy_companion/features/journal/domain/journal_entry.dart';
import 'package:pregnancy_companion/features/nutrition/domain/food_guide.dart';

void main() {
  group('pregnancyMilestones', () {
    final lmp = DateTime(2026, 1, 1);
    final due = DateTime(2026, 10, 8); // ~280 days
    final events = pregnancyMilestones(lmp, due);

    test('is chronologically ordered', () {
      for (var i = 1; i < events.length; i++) {
        expect(events[i].date.isBefore(events[i - 1].date), isFalse);
      }
    });

    test('starts at LMP and ends at the due date', () {
      expect(events.first.date, DateTime(2026, 1, 1));
      expect(events.last.title, 'Estimated due date');
      expect(events.last.date, DateTime(2026, 10, 8));
    });

    test('all events are milestones', () {
      expect(events.every((e) => e.kind == CalendarEventKind.milestone), isTrue);
    });

    test('second trimester milestone is 13 weeks after LMP', () {
      final second =
          events.firstWhere((e) => e.title == 'Second trimester begins');
      expect(second.date, DateTime(2026, 1, 1).add(const Duration(days: 91)));
    });
  });

  group('JournalEntry', () {
    test('round-trips through JSON with mood', () {
      final e = JournalEntry(
        id: 'j1',
        loggedAt: DateTime.utc(2026, 5, 1, 9),
        text: 'Felt the baby kick today!',
        mood: JournalMood.great,
        title: 'A good day',
      );
      final restored = JournalEntry.fromJson(e.toJson());
      expect(restored, e);
      expect(restored.mood, JournalMood.great);
    });

    test('mood fromName falls back to okay', () {
      expect(JournalMood.fromName('great'), JournalMood.great);
      expect(JournalMood.fromName('nonsense'), JournalMood.okay);
    });
  });

  group('Food guide', () {
    test('covers every safety level', () {
      for (final s in FoodSafety.values) {
        expect(kFoodGuide.any((f) => f.safety == s), isTrue,
            reason: 'missing foods for ${s.name}');
      }
    });

    test('alcohol is marked avoid', () {
      final alcohol = kFoodGuide.firstWhere((f) => f.name == 'Alcohol');
      expect(alcohol.safety, FoodSafety.avoid);
    });

    test('nutrient tips are non-empty', () {
      expect(kNutrientTips, isNotEmpty);
      expect(kNutrientTips.every((n) => n.nutrient.isNotEmpty), isTrue);
    });
  });

  group('Exercise guide', () {
    test('every exercise lists at least one valid trimester', () {
      for (final e in kExercises) {
        expect(e.trimesters, isNotEmpty);
        expect(e.trimesters.every((t) => t >= 1 && t <= 3), isTrue);
      }
    });

    test('suitsTrimester filters correctly', () {
      final walking = kExercises.firstWhere((e) => e.name == 'Walking');
      expect(walking.suitsTrimester(1), isTrue);
      expect(walking.suitsTrimester(3), isTrue);
      final catCow = kExercises.firstWhere((e) => e.name.startsWith('Cat'));
      expect(catCow.suitsTrimester(1), isFalse);
      expect(catCow.suitsTrimester(3), isTrue);
    });

    test('safety tips are provided', () {
      expect(kExerciseSafetyTips.length, greaterThanOrEqualTo(3));
    });
  });
}
