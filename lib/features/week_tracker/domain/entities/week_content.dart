import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// A single question/answer shown in a week's FAQ section.
class FaqItem extends Equatable {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  Map<String, dynamic> toJson() => {'q': question, 'a': answer};

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        question: json['q'] as String? ?? json['question'] as String? ?? '',
        answer: json['a'] as String? ?? json['answer'] as String? ?? '',
      );

  @override
  List<Object?> get props => [question, answer];
}

/// All the educational content for one gestational week (1–40).
///
/// Mirrors `weekContent/{week}` in Firestore and the bundled
/// `assets/data/week_content.json`. Where detailed content is unavailable, the
/// repository synthesises a concise, trimester-appropriate entry so every week
/// 1–40 renders something useful — even fully offline.
class WeekContent extends Equatable {
  const WeekContent({
    required this.week,
    required this.trimester,
    required this.sizeComparison,
    required this.babyDevelopment,
    required this.motherChanges,
    this.babyLengthCm,
    this.babyWeightG,
    this.avoid = const [],
    this.advice = '',
    this.nutrition = const [],
    this.exercises = const [],
    this.yoga = const [],
    this.faqs = const [],
  });

  final int week;
  final Trimester trimester;
  final String sizeComparison;
  final double? babyLengthCm;
  final int? babyWeightG;
  final String babyDevelopment;
  final String motherChanges;
  final List<String> avoid;
  final String advice;
  final List<String> nutrition;
  final List<String> exercises;
  final List<String> yoga;
  final List<FaqItem> faqs;

  /// Human-friendly weight label (grams < 1kg, else kilograms).
  String? get weightLabel {
    final w = babyWeightG;
    if (w == null) return null;
    if (w < 1000) return '$w g';
    return '${(w / 1000).toStringAsFixed(2)} kg';
  }

  String? get lengthLabel =>
      babyLengthCm == null ? null : '${babyLengthCm!.toStringAsFixed(1)} cm';

  Map<String, dynamic> toJson() => {
        'week': week,
        'trimester': trimester.name,
        'sizeComparison': sizeComparison,
        'babyLengthCm': babyLengthCm,
        'babyWeightG': babyWeightG,
        'babyDevelopment': babyDevelopment,
        'motherChanges': motherChanges,
        'avoid': avoid,
        'advice': advice,
        'nutrition': nutrition,
        'exercises': exercises,
        'yoga': yoga,
        'faqs': faqs.map((f) => f.toJson()).toList(),
      };

  factory WeekContent.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [];

    return WeekContent(
      week: (json['week'] as num).toInt(),
      trimester: Trimester.values.firstWhere(
        (t) => t.name == json['trimester'],
        orElse: () => Trimester.first,
      ),
      sizeComparison: json['sizeComparison'] as String? ?? '',
      babyLengthCm: (json['babyLengthCm'] as num?)?.toDouble() ??
          ((json['babyLengthMm'] as num?)?.toDouble() != null
              ? (json['babyLengthMm'] as num).toDouble() / 10.0
              : null),
      babyWeightG: (json['babyWeightG'] as num?)?.toInt(),
      babyDevelopment: json['babyDevelopment'] as String? ?? '',
      motherChanges: json['motherChanges'] as String? ?? '',
      avoid: strings('avoid'),
      advice: json['advice'] as String? ?? '',
      nutrition: strings('nutrition'),
      exercises: strings('exercises'),
      yoga: strings('yoga'),
      faqs: (json['faqs'] as List<dynamic>?)
              ?.map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [week, sizeComparison, babyDevelopment];
}
