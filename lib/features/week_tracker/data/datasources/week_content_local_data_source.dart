import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/constants/asset_paths.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/pregnancy_calculator.dart';
import '../../domain/entities/week_content.dart';
import '../baby_size_data.dart';

/// Offline source of week content. Reads the bundled `week_content.json` (parsed
/// once and memoised) for detailed weeks, and synthesises a concise,
/// trimester-appropriate entry for any week without bundled detail — so every
/// week 1–40 always renders, with zero network.
class WeekContentLocalDataSource {
  Map<int, WeekContent>? _bundled;

  Future<Map<int, WeekContent>> _loadBundle() async {
    if (_bundled != null) return _bundled!;
    final raw = await rootBundle.loadString(AssetPaths.weekContentJson);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final weeks = (json['weeks'] as List<dynamic>? ?? const [])
        .map((e) => WeekContent.fromJson(e as Map<String, dynamic>));
    _bundled = {for (final w in weeks) w.week: w};
    return _bundled!;
  }

  /// Always returns content: bundled detail when present, else synthesised.
  Future<WeekContent> getWeek(int week) async {
    final clamped = week.clamp(1, 40);
    final bundle = await _loadBundle();
    return bundle[clamped] ?? _synthesize(clamped);
  }

  WeekContent _synthesize(int week) {
    final tri = PregnancyCalculator.trimesterForWeek(week);
    final size = BabySizeData.forWeek(week);
    return WeekContent(
      week: week,
      trimester: tri,
      sizeComparison: size?.fruit ?? 'Tiny',
      babyLengthCm: size?.lengthCm,
      babyWeightG: (size == null || size.weightG == 0) ? null : size.weightG,
      babyDevelopment: _development(tri),
      motherChanges: _motherChanges(tri),
      avoid: _avoid(tri),
      advice: _advice(tri),
      nutrition: const ['Folic acid', 'Iron', 'Calcium', 'Protein', 'Water'],
      exercises: const ['Walking', 'Prenatal stretching', 'Pelvic floor (Kegel)'],
      yoga: const ['Gentle breathing (pranayama)', 'Cat–cow stretch'],
      faqs: const [],
    );
  }

  String _development(Trimester t) => switch (t) {
        Trimester.first =>
          'Your baby’s major organs and neural tube are forming this trimester. '
              'The heart begins to beat and tiny limb buds appear.',
        Trimester.second =>
          'Your baby is growing quickly — developing muscles, bones and senses. '
              'Movements become stronger and more coordinated.',
        Trimester.third =>
          'Your baby is putting on weight, and the lungs and brain are maturing '
              'in preparation for birth.',
      };

  String _motherChanges(Trimester t) => switch (t) {
        Trimester.first =>
          'You may feel tired or nauseous as hormones rise. Tender breasts and '
              'food aversions are common.',
        Trimester.second =>
          'Often the most comfortable stage — energy returns and your bump '
              'becomes visible. You may feel the first kicks.',
        Trimester.third =>
          'You may feel heavier and more short of breath, with more frequent '
              'trips to the bathroom and occasional Braxton Hicks contractions.',
      };

  List<String> _avoid(Trimester t) => const [
        'Alcohol and smoking',
        'Raw or undercooked meat, fish and eggs',
        'Unpasteurized dairy',
        'Excess caffeine',
        'High-mercury fish',
      ];

  String _advice(Trimester t) => switch (t) {
        Trimester.first =>
          'Take your prenatal vitamin daily and stay hydrated. Book your first '
              'antenatal appointment.',
        Trimester.second =>
          'Keep up gentle activity and don’t miss your mid-pregnancy scan and '
              'check-ups.',
        Trimester.third =>
          'Monitor your baby’s movements daily, prepare your hospital bag, and '
              'discuss your birth plan with your doctor.',
      };
}
