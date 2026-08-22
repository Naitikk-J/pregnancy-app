import 'package:equatable/equatable.dart';

/// A single weight measurement, stored at `pregnancies/{pid}/weight/{id}`.
class WeightEntry extends Equatable {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.loggedAt,
    this.note,
  });

  final String id;
  final double weightKg;
  final DateTime loggedAt;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        'note': note,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [id, weightKg, loggedAt, note];
}
