import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

/// The mother's medical & personal profile, mirroring
/// `users/{uid}/profile/main`. Collected during onboarding and editable later.
class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    this.bloodGroup,
    this.medicalConditions = const [],
    this.previousPregnancies = 0,
    this.foodPreferences = const [],
    this.waterGoalMl = AppConstants.defaultWaterGoalMl,
    this.sleepTime = '22:30',
    this.wakeTime = '06:30',
  });

  final String name;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? bloodGroup;
  final List<String> medicalConditions;
  final int previousPregnancies;
  final List<String> foodPreferences;
  final int waterGoalMl;

  /// Stored as "HH:mm" 24-hour strings — timezone-agnostic and JSON-safe.
  final String sleepTime;
  final String wakeTime;

  UserProfile copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    String? bloodGroup,
    List<String>? medicalConditions,
    int? previousPregnancies,
    List<String>? foodPreferences,
    int? waterGoalMl,
    String? sleepTime,
    String? wakeTime,
  }) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        medicalConditions: medicalConditions ?? this.medicalConditions,
        previousPregnancies: previousPregnancies ?? this.previousPregnancies,
        foodPreferences: foodPreferences ?? this.foodPreferences,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        sleepTime: sleepTime ?? this.sleepTime,
        wakeTime: wakeTime ?? this.wakeTime,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bloodGroup': bloodGroup,
        'medicalConditions': medicalConditions,
        'previousPregnancies': previousPregnancies,
        'foodPreferences': foodPreferences,
        'waterGoalMl': waterGoalMl,
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? '',
        age: (json['age'] as num?)?.toInt(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        bloodGroup: json['bloodGroup'] as String?,
        medicalConditions:
            (json['medicalConditions'] as List<dynamic>?)?.cast<String>() ??
                const [],
        previousPregnancies: (json['previousPregnancies'] as num?)?.toInt() ?? 0,
        foodPreferences:
            (json['foodPreferences'] as List<dynamic>?)?.cast<String>() ??
                const [],
        waterGoalMl: (json['waterGoalMl'] as num?)?.toInt() ??
            AppConstants.defaultWaterGoalMl,
        sleepTime: json['sleepTime'] as String? ?? '22:30',
        wakeTime: json['wakeTime'] as String? ?? '06:30',
      );

  @override
  List<Object?> get props => [
        name,
        age,
        weightKg,
        heightCm,
        bloodGroup,
        medicalConditions,
        previousPregnancies,
        foodPreferences,
        waterGoalMl,
        sleepTime,
        wakeTime,
      ];
}
