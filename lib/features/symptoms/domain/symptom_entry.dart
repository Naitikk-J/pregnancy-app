import 'package:equatable/equatable.dart';

/// A logged symptom, stored at `pregnancies/{pid}/symptoms/{id}`.
class SymptomEntry extends Equatable {
  const SymptomEntry({
    required this.id,
    required this.type,
    required this.severity,
    required this.loggedAt,
    this.note,
  });

  final String id;
  final String type;
  final int severity; // 1–10
  final DateTime loggedAt;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'severity': severity,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        'note': note,
      };

  factory SymptomEntry.fromJson(Map<String, dynamic> json) => SymptomEntry(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'Other',
        severity: (json['severity'] as num?)?.toInt() ?? 1,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [id, type, severity, loggedAt, note];
}

/// The symptoms users can quickly log.
const kCommonSymptoms = <String>[
  'Nausea',
  'Vomiting',
  'Back pain',
  'Headache',
  'Swelling',
  'Cramps',
  'Fatigue',
  'Heartburn',
  'Constipation',
  'Dizziness',
  'Mood swings',
  'Trouble sleeping',
];
