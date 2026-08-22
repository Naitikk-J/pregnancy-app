import 'package:equatable/equatable.dart';

/// A pregnancy-safe exercise with which trimesters it suits and a caution note.
class ExerciseItem extends Equatable {
  const ExerciseItem({
    required this.name,
    required this.description,
    required this.trimesters,
    this.caution,
  });

  final String name;
  final String description;

  /// Trimesters (1, 2, 3) this exercise generally suits.
  final List<int> trimesters;
  final String? caution;

  bool suitsTrimester(int t) => trimesters.contains(t);

  @override
  List<Object?> get props => [name, description, trimesters, caution];
}

/// General safety points shown at the top of the exercise guide.
const List<String> kExerciseSafetyTips = [
  'Warm up, stay hydrated, and don’t exercise to exhaustion.',
  'Avoid lying flat on your back after the first trimester.',
  'Avoid contact sports, and anything with a fall risk.',
  'Stop and call your doctor if you feel pain, dizziness, bleeding or '
      'contractions.',
  'Aim for about 30 minutes of moderate activity on most days, if your doctor '
      'agrees.',
];

/// Curated pregnancy-safe exercises. Static content (no I/O).
const List<ExerciseItem> kExercises = [
  ExerciseItem(
    name: 'Walking',
    description: 'Low-impact cardio you can do anywhere; keeps you active safely.',
    trimesters: [1, 2, 3],
  ),
  ExerciseItem(
    name: 'Prenatal yoga',
    description: 'Gentle stretching and breathing for flexibility and calm.',
    trimesters: [1, 2, 3],
    caution: 'Skip deep twists and lying flat on your back later on.',
  ),
  ExerciseItem(
    name: 'Swimming / water aerobics',
    description: 'Supports your weight and eases joint and back strain.',
    trimesters: [1, 2, 3],
  ),
  ExerciseItem(
    name: 'Pelvic floor (Kegels)',
    description: 'Strengthens muscles for labour and recovery.',
    trimesters: [1, 2, 3],
  ),
  ExerciseItem(
    name: 'Stationary cycling',
    description: 'Cardio without the fall risk of a road bike.',
    trimesters: [1, 2],
    caution: 'Comfort drops as the bump grows; switch to walking if needed.',
  ),
  ExerciseItem(
    name: 'Light strength training',
    description: 'Light weights/bands maintain muscle tone.',
    trimesters: [1, 2, 3],
    caution: 'Avoid heavy lifting and holding your breath (Valsalva).',
  ),
  ExerciseItem(
    name: 'Cat–cow & pelvic tilts',
    description: 'Eases back pain and improves posture.',
    trimesters: [2, 3],
  ),
];
