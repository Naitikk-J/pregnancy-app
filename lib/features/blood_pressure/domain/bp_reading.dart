import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/health_calculator.dart';

/// A single blood-pressure reading, stored at
/// `pregnancies/{pid}/blood_pressure/{id}`.
class BpReading extends Equatable {
  const BpReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.loggedAt,
    this.pulse,
    this.note,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final DateTime loggedAt;
  final String? note;

  BpCategory get category =>
      HealthCalculator.bpCategory(systolic, diastolic);

  Map<String, dynamic> toJson() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        'note': note,
      };

  factory BpReading.fromJson(Map<String, dynamic> json) => BpReading(
        id: json['id'] as String,
        systolic: (json['systolic'] as num).toInt(),
        diastolic: (json['diastolic'] as num).toInt(),
        pulse: (json['pulse'] as num?)?.toInt(),
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [id, systolic, diastolic, pulse, loggedAt, note];
}
