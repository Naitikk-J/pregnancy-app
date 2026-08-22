import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';

/// A single day's water intake, stored at `pregnancies/{pid}/water/{yyyy-MM-dd}`.
class WaterDay extends Equatable {
  const WaterDay({
    required this.dateKey,
    required this.consumedMl,
    required this.goalMl,
  });

  final String dateKey;
  final int consumedMl;
  final int goalMl;

  double get progress =>
      goalMl <= 0 ? 0 : (consumedMl / goalMl).clamp(0.0, 1.0);

  int get glasses => consumedMl ~/ AppConstants.glassMl;
  int get goalGlasses => goalMl ~/ AppConstants.glassMl;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'consumedMl': consumedMl,
        'goalMl': goalMl,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory WaterDay.fromJson(Map<String, dynamic> json) => WaterDay(
        dateKey: json['dateKey'] as String? ?? '',
        consumedMl: (json['consumedMl'] as num?)?.toInt() ?? 0,
        goalMl: (json['goalMl'] as num?)?.toInt() ??
            AppConstants.defaultWaterGoalMl,
      );

  @override
  List<Object?> get props => [dateKey, consumedMl, goalMl];
}
