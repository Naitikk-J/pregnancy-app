import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';

/// A single timestamped drink within a day (e.g. "250 ml at 4:10 pm").
class WaterEntry extends Equatable {
  const WaterEntry({required this.id, required this.ml, required this.at});

  final String id;
  final int ml;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ml': ml,
        'at': at.toUtc().toIso8601String(),
      };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
        id: json['id'] as String? ?? '',
        ml: (json['ml'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse(json['at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id, ml, at];
}

/// A single day's water intake, stored at `pregnancies/{pid}/water/{yyyy-MM-dd}`.
class WaterDay extends Equatable {
  const WaterDay({
    required this.dateKey,
    required this.consumedMl,
    required this.goalMl,
    this.entries = const [],
  });

  final String dateKey;
  final int consumedMl;
  final int goalMl;

  /// Individual timestamped drinks, most recent first (sorted by [entries]).
  final List<WaterEntry> entries;

  double get progress =>
      goalMl <= 0 ? 0 : (consumedMl / goalMl).clamp(0.0, 1.0);

  int get glasses => consumedMl ~/ AppConstants.glassMl;
  int get goalGlasses => goalMl ~/ AppConstants.glassMl;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'consumedMl': consumedMl,
        'goalMl': goalMl,
        'entries': [for (final e in entries) e.toJson()],
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory WaterDay.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List<dynamic>?) ?? const [];
    final entries = [
      for (final e in rawEntries)
        WaterEntry.fromJson(Map<String, dynamic>.from(e as Map)),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return WaterDay(
      dateKey: json['dateKey'] as String? ?? '',
      consumedMl: (json['consumedMl'] as num?)?.toInt() ?? 0,
      goalMl: (json['goalMl'] as num?)?.toInt() ??
          AppConstants.defaultWaterGoalMl,
      entries: entries,
    );
  }

  @override
  List<Object?> get props => [dateKey, consumedMl, goalMl, entries];
}
