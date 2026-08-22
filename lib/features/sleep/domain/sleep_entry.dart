import 'package:equatable/equatable.dart';

/// A single night's sleep, stored at `pregnancies/{pid}/sleep/{id}`.
class SleepEntry extends Equatable {
  const SleepEntry({
    required this.id,
    required this.hours,
    required this.loggedAt,
    this.quality = 3,
    this.note,
  });

  final String id;
  final double hours;

  /// Subjective sleep quality, 1 (poor) – 5 (great).
  final int quality;
  final DateTime loggedAt;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'hours': hours,
        'quality': quality,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        'note': note,
      };

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
        id: json['id'] as String,
        hours: (json['hours'] as num).toDouble(),
        quality: (json['quality'] as num?)?.toInt() ?? 3,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [id, hours, quality, loggedAt, note];
}
