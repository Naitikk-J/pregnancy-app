import 'package:equatable/equatable.dart';

/// A single timed contraction, stored at
/// `pregnancies/{pid}/contractions/{id}`.
///
/// [duration] is how long the contraction lasted; the *interval* (frequency)
/// between contractions is start-to-start and is derived across a list — see
/// [ContractionAnalyzer].
class Contraction extends Equatable {
  const Contraction({
    required this.id,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isComplete => endedAt != null;

  /// Length of the contraction. While running (no [endedAt]) callers pass [now]
  /// so the value ticks.
  Duration duration([DateTime? now]) =>
      (endedAt ?? now ?? DateTime.now()).difference(startedAt);

  Contraction copyWith({DateTime? endedAt}) => Contraction(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt?.toUtc().toIso8601String(),
      };

  factory Contraction.fromJson(Map<String, dynamic> json) => Contraction(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt'] as String),
      );

  @override
  List<Object?> get props => [id, startedAt, endedAt];
}
