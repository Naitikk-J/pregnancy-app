import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/pregnancy_calculator.dart';
import '../../../shared/models/pregnancy.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/pregnancy_access.dart';

/// Live assessment of whether the signed-in account can reach its active
/// pregnancy's data. Watched by the dashboard (to surface a recovery banner) and
/// by the recovery screen itself.
final pregnancyAccessProvider = Provider<PregnancyAccess>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return PregnancyAccess.loading;

  final pid = user.activePregnancyId;
  if (pid == null || pid.isEmpty) return PregnancyAccess.none;

  final async = ref.watch(activePregnancyProvider);
  return async.when(
    loading: () => PregnancyAccess.loading,
    // A failed read of a world-readable pregnancy doc still means the user can't
    // use their trackers — treat it as recoverable rather than a dead spinner.
    error: (_, __) => PregnancyAccess.missing,
    data: (pregnancy) => resolvePregnancyAccess(
      uid: user.uid,
      activePregnancyId: pid,
      pregnancyLoaded: true,
      pregnancy: pregnancy,
    ),
  );
});

/// Drives the "fix data access" recovery flow: creates a fresh pregnancy owned
/// by the current account and repoints the account document at it, so tracker
/// reads/writes succeed again.
class RecoveryController extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Creates a new pregnancy owned by the signed-in user from the given [lmp].
  /// Returns true on success. The existing profile is preserved.
  Future<bool> createFreshPregnancy({
    required DateTime lmp,
    RiskCategory risk = RiskCategory.low,
    String? doctorName,
    String? hospital,
  }) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return false;

    final lmpDateOnly = DateTime(lmp.year, lmp.month, lmp.day);
    final now = DateTime.now().toUtc();
    final pregnancy = Pregnancy(
      id: const Uuid().v4(),
      ownerUserId: uid,
      lmpDate: lmpDateOnly,
      dueDate: PregnancyCalculator.dueDateFromLmp(lmpDateOnly),
      riskCategory: risk,
      doctorName: doctorName,
      hospital: hospital,
      status: 'active',
      members: {
        uid: {
          'role': UserRole.mother.name,
          'permissions': ['owner'],
          'invitedAt': now.toIso8601String(),
          'acceptedAt': now.toIso8601String(),
        },
      },
      createdAt: now,
      updatedAt: now,
    );

    state = const AsyncLoading();
    try {
      await ref
          .read(profileRepositoryProvider)
          .createPregnancyForUser(uid: uid, pregnancy: pregnancy);
      // Nudge the streams so the app repoints immediately.
      ref.invalidate(activePregnancyProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }
}

final recoveryControllerProvider =
    AsyncNotifierProvider<RecoveryController, void>(RecoveryController.new);
