import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/health_calculator.dart';

/// A single blood-sugar reading (mg/dL), stored at
/// `pregnancies/{pid}/blood_sugar/{id}`.
class GlucoseReading extends Equatable {
  const GlucoseReading({
    required this.id,
    required this.mgDl,
    required this.context,
    required this.loggedAt,
    this.note,
    this.insulinUnits,
    this.insulinAt,
  });

  final String id;
  final double mgDl;
  final GlucoseContext context;
  final DateTime loggedAt;
  final String? note;

  /// Insulin dose taken with this reading, in units. `null` when no insulin
  /// was recorded.
  final double? insulinUnits;

  /// When the insulin was taken. Defaults to [loggedAt] when units are recorded
  /// without a distinct time; `null` when no insulin was recorded.
  final DateTime? insulinAt;

  /// True when an insulin dose is attached to this reading.
  bool get hasInsulin => insulinUnits != null && insulinUnits! > 0;

  bool get inRange => HealthCalculator.glucoseInRange(mgDl, context);
  String get status => HealthCalculator.glucoseStatus(mgDl, context);

  Map<String, dynamic> toJson() => {
        'id': id,
        'mgDl': mgDl,
        'context': context.name,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        'note': note,
        'insulinUnits': insulinUnits,
        'insulinAt': insulinAt?.toUtc().toIso8601String(),
      };

  factory GlucoseReading.fromJson(Map<String, dynamic> json) => GlucoseReading(
        id: json['id'] as String,
        mgDl: (json['mgDl'] as num).toDouble(),
        context: GlucoseContext.fromName(json['context'] as String?),
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        note: json['note'] as String?,
        insulinUnits: (json['insulinUnits'] as num?)?.toDouble(),
        insulinAt: json['insulinAt'] == null
            ? null
            : DateTime.parse(json['insulinAt'] as String),
      );

  @override
  List<Object?> get props =>
      [id, mgDl, context, loggedAt, note, insulinUnits, insulinAt];
}
