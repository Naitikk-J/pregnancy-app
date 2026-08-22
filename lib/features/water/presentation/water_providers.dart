import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_utils.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../data/water_repository.dart';
import '../domain/water_day.dart';

final waterRepositoryProvider = Provider<WaterRepository?>((ref) {
  final col = pregnancySubcollection(ref, 'water');
  return col == null ? null : WaterRepository(col);
});

/// The active daily water goal (from the profile, or the default).
final waterGoalProvider = Provider<int>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.waterGoalMl ??
      AppConstants.defaultWaterGoalMl;
});

/// Today's water intake, live.
final todayWaterProvider = StreamProvider<WaterDay>((ref) {
  final repo = ref.watch(waterRepositoryProvider);
  final goal = ref.watch(waterGoalProvider);
  final key = IdUtils.dateKey(DateTime.now());
  if (repo == null) {
    return Stream.value(WaterDay(dateKey: key, consumedMl: 0, goalMl: goal));
  }
  return repo.watchDay(key, goal);
});
