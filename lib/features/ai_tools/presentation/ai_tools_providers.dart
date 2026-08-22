import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/controllers/profile_providers.dart';

/// Lightweight, non-identifying pregnancy context passed to the AI tools so
/// suggestions can be tailored to the trimester and any health conditions.
final aiContextProvider = Provider<Map<String, dynamic>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
  final ctx = <String, dynamic>{};
  if (pregnancy != null) {
    ctx['currentWeek'] = pregnancy.currentWeek;
    ctx['trimester'] = pregnancy.trimester.label;
    ctx['risk'] = pregnancy.riskCategory.label;
  }
  final conditions = profile?.medicalConditions
          .where((c) => c.isNotEmpty && c.toLowerCase() != 'none')
          .toList() ??
      const [];
  if (conditions.isNotEmpty) ctx['conditions'] = conditions;
  return ctx;
});

/// The user's diet preference (for the meal planner), inferred from the profile.
final dietPreferenceProvider = Provider<String>((ref) {
  final prefs = ref.watch(userProfileProvider).valueOrNull?.foodPreferences ??
      const <String>[];
  final lower = prefs.map((p) => p.toLowerCase()).toList();
  if (lower.any((p) => p.contains('vegan'))) return 'vegan';
  if (lower.any((p) => p.contains('non-veg') || p.contains('nonveg'))) {
    return 'non-vegetarian';
  }
  if (lower.any((p) => p.contains('egg'))) return 'eggetarian';
  return 'vegetarian';
});
