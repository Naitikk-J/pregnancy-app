import '../../../shared/models/pregnancy.dart';

/// Whether the signed-in account can actually reach the data under its active
/// pregnancy. Trackers live in `pregnancies/{pid}/…` and are gated on ownership
/// or membership, so a mismatch here is exactly what produces the
/// `permission-denied` errors on the tracker screens.
enum PregnancyAccess {
  /// Still resolving the account or the pregnancy document.
  loading,

  /// The account has no active pregnancy at all.
  none,

  /// The account owns or is a member of its active pregnancy — all good.
  ok,

  /// The active pregnancy exists but belongs to a *different* account
  /// (neither owner nor member) — typically after an account switch.
  foreign,

  /// The active pregnancy id points at a document that no longer exists.
  missing,
}

extension PregnancyAccessX on PregnancyAccess {
  /// True when tracker data cannot be read and recovery should be offered.
  bool get needsRecovery =>
      this == PregnancyAccess.foreign ||
      this == PregnancyAccess.missing ||
      this == PregnancyAccess.none;
}

/// Pure decision for [PregnancyAccess]. Pregnancy documents are world-readable
/// to any signed-in user (the invite-code model), so the client can inspect the
/// doc itself and tell an inaccessible active pregnancy apart from a healthy one
/// without hitting a denied tracker read.
///
/// [pregnancyLoaded] is false while the pregnancy stream is still loading;
/// [pregnancy] is null when the referenced document does not exist.
PregnancyAccess resolvePregnancyAccess({
  required String uid,
  required String? activePregnancyId,
  required bool pregnancyLoaded,
  required Pregnancy? pregnancy,
}) {
  if (activePregnancyId == null || activePregnancyId.isEmpty) {
    return PregnancyAccess.none;
  }
  if (!pregnancyLoaded) return PregnancyAccess.loading;
  if (pregnancy == null) return PregnancyAccess.missing;
  final canAccess =
      pregnancy.ownerUserId == uid || pregnancy.members.containsKey(uid);
  return canAccess ? PregnancyAccess.ok : PregnancyAccess.foreign;
}
