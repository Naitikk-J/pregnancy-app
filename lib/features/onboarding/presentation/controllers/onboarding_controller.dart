import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/pregnancy_calculator.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../profile/presentation/controllers/profile_providers.dart';

/// The in-progress onboarding form, accumulated across wizard steps. Immutable;
/// each edit produces a new value so the UI rebuilds predictably.
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.name = '',
    this.role = UserRole.mother,
    this.age,
    this.weightKg,
    this.heightCm,
    this.bloodGroup,
    this.medicalConditions = const [],
    this.previousPregnancies = 0,
    this.riskCategory = RiskCategory.low,
    this.lmpDate,
    this.doctorName,
    this.hospital,
    this.foodPreferences = const [],
    this.waterGoalMl = AppConstants.defaultWaterGoalMl,
    this.sleepTime = '22:30',
    this.wakeTime = '06:30',
  });

  final String name;
  final UserRole role;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? bloodGroup;
  final List<String> medicalConditions;
  final int previousPregnancies;
  final RiskCategory riskCategory;
  final DateTime? lmpDate;
  final String? doctorName;
  final String? hospital;
  final List<String> foodPreferences;
  final int waterGoalMl;
  final String sleepTime;
  final String wakeTime;

  /// Estimated due date from the entered LMP (null until an LMP is chosen).
  DateTime? get dueDate =>
      lmpDate == null ? null : PregnancyCalculator.dueDateFromLmp(lmpDate!);

  int? get currentWeek =>
      lmpDate == null ? null : PregnancyCalculator.currentWeek(lmpDate!);

  OnboardingDraft copyWith({
    String? name,
    UserRole? role,
    int? age,
    double? weightKg,
    double? heightCm,
    String? bloodGroup,
    List<String>? medicalConditions,
    int? previousPregnancies,
    RiskCategory? riskCategory,
    DateTime? lmpDate,
    String? doctorName,
    String? hospital,
    List<String>? foodPreferences,
    int? waterGoalMl,
    String? sleepTime,
    String? wakeTime,
  }) =>
      OnboardingDraft(
        name: name ?? this.name,
        role: role ?? this.role,
        age: age ?? this.age,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        medicalConditions: medicalConditions ?? this.medicalConditions,
        previousPregnancies: previousPregnancies ?? this.previousPregnancies,
        riskCategory: riskCategory ?? this.riskCategory,
        lmpDate: lmpDate ?? this.lmpDate,
        doctorName: doctorName ?? this.doctorName,
        hospital: hospital ?? this.hospital,
        foodPreferences: foodPreferences ?? this.foodPreferences,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        sleepTime: sleepTime ?? this.sleepTime,
        wakeTime: wakeTime ?? this.wakeTime,
      );

  UserProfile toProfile() => UserProfile(
        name: name.trim(),
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        bloodGroup: bloodGroup,
        medicalConditions: medicalConditions,
        previousPregnancies: previousPregnancies,
        foodPreferences: foodPreferences,
        waterGoalMl: waterGoalMl,
        sleepTime: sleepTime,
        wakeTime: wakeTime,
      );

  Pregnancy toPregnancy({required String id, required String ownerUid}) {
    // Normalize to date-only so LMP and the derived due date stay consistent.
    final lmp = DateTime(lmpDate!.year, lmpDate!.month, lmpDate!.day);
    final now = DateTime.now().toUtc();
    return Pregnancy(
      id: id,
      ownerUserId: ownerUid,
      lmpDate: lmp,
      dueDate: PregnancyCalculator.dueDateFromLmp(lmp),
      riskCategory: riskCategory,
      doctorName: doctorName,
      hospital: hospital,
      status: 'active',
      members: {
        ownerUid: {
          'role': UserRole.mother.name,
          'permissions': ['owner'],
          'invitedAt': now.toIso8601String(),
          'acceptedAt': now.toIso8601String(),
        },
      },
      createdAt: now,
      updatedAt: now,
    );
  }
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() {
    // Pre-fill the name from the signed-in account when available.
    final user = ref.read(currentUserProvider);
    return OnboardingDraft(
      name: user?.displayName ?? '',
      role: user?.role ?? UserRole.mother,
    );
  }

  void update(OnboardingDraft Function(OnboardingDraft) transform) =>
      state = transform(state);

  void toggleCondition(String condition) {
    final list = [...state.medicalConditions];
    list.contains(condition) ? list.remove(condition) : list.add(condition);
    state = state.copyWith(medicalConditions: list);
  }

  /// Single-select diet preference — selecting a new one replaces the old, and
  /// tapping the selected one clears it.
  void setFoodPreference(String pref) {
    final current = state.foodPreferences;
    final next = current.contains(pref) ? <String>[] : <String>[pref];
    state = state.copyWith(foodPreferences: next);
  }

  /// Persists the draft. Returns true on success. Throws a mapped Failure the
  /// caller can surface if the write fails.
  Future<bool> submit() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null || state.lmpDate == null) return false;

    final pregnancyId = const Uuid().v4();
    await ref.read(profileRepositoryProvider).completeOnboarding(
          uid: uid,
          role: state.role,
          profile: state.toProfile(),
          pregnancy: state.toPregnancy(id: pregnancyId, ownerUid: uid),
        );
    return true;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
        OnboardingController.new);
