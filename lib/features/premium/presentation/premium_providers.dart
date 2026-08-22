import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/controllers/auth_providers.dart';

/// Local, in-memory demo override for Premium. Per-session and never persisted.
///
/// Real entitlements live on the server (`users/{uid}.isPremium`, set by a
/// Cloud Function after verified billing) and are NOT client-writable — the
/// Firestore rules block the client from changing that field. This flag only
/// exists so the paywall can be demonstrated in a build without real billing.
final demoPremiumProvider = StateProvider<bool>((ref) => false);

/// Whether the signed-in user currently has Premium — true if the server
/// granted a real entitlement OR the local demo toggle is on.
final isPremiumProvider = Provider<bool>((ref) {
  final serverPremium = ref.watch(currentUserProvider)?.isPremium ?? false;
  final demoPremium = ref.watch(demoPremiumProvider);
  return serverPremium || demoPremium;
});

/// Flips the *demo* premium override.
///
/// NOTE: this is a placeholder for real billing. Production must integrate
/// Google Play Billing / Razorpay and verify purchases server-side (a Cloud
/// Function) before setting `users/{uid}.isPremium` — the client is never the
/// source of truth for entitlements, and the Firestore rules enforce that by
/// rejecting any client write to `isPremium`. So this toggle only flips a
/// local, in-memory flag for the paywall demo.
class PremiumController {
  PremiumController(this._ref);
  final Ref _ref;

  Future<void> setPremium(bool value) async {
    _ref.read(demoPremiumProvider.notifier).state = value;
  }
}

final premiumControllerProvider =
    Provider<PremiumController>((ref) => PremiumController(ref));
