import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/week_tracker/data/baby_size_data.dart';
import 'package:pregnancy_companion/features/week_tracker/domain/entities/week_content.dart';

void main() {
  group('BabySizeData', () {
    test('covers every week from 4 to 40', () {
      for (var w = 4; w <= 40; w++) {
        expect(BabySizeData.forWeek(w), isNotNull, reason: 'missing week $w');
      }
    });

    test('length grows monotonically across weeks', () {
      double? previous;
      for (var w = 4; w <= 40; w++) {
        final size = BabySizeData.forWeek(w)!;
        if (previous != null) {
          expect(size.lengthCm, greaterThanOrEqualTo(previous));
        }
        previous = size.lengthCm;
      }
    });
  });

  group('WeekContent', () {
    test('parses bundled-style JSON with babyLengthMm fallback', () {
      final json = {
        'week': 12,
        'trimester': 'first',
        'sizeComparison': 'Lime',
        'babyLengthMm': 54,
        'babyDevelopment': 'Reflexes developing.',
        'motherChanges': 'Nausea easing.',
        'avoid': ['Caffeine'],
        'nutrition': ['Iron', 'Protein'],
        'faqs': [
          {'q': 'When will I show?', 'a': 'Weeks 12–16.'},
        ],
      };
      final content = WeekContent.fromJson(json);
      expect(content.week, 12);
      expect(content.trimester, Trimester.first);
      expect(content.babyLengthCm, 5.4); // 54mm -> 5.4cm
      expect(content.avoid, ['Caffeine']);
      expect(content.faqs.single.question, 'When will I show?');
    });

    test('weight and length labels format correctly', () {
      const grams = WeekContent(
        week: 20,
        trimester: Trimester.second,
        sizeComparison: 'Banana',
        babyDevelopment: '',
        motherChanges: '',
        babyLengthCm: 25.6,
        babyWeightG: 300,
      );
      expect(grams.weightLabel, '300 g');
      expect(grams.lengthLabel, '25.6 cm');

      const kilos = WeekContent(
        week: 40,
        trimester: Trimester.third,
        sizeComparison: 'Pumpkin',
        babyDevelopment: '',
        motherChanges: '',
        babyWeightG: 3462,
      );
      expect(kilos.weightLabel, '3.46 kg');
    });
  });
}
