import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../theme/app_spacing.dart';

/// A slim, app-wide banner that appears whenever the device is offline.
///
/// The trackers keep working offline — Firestore's local persistence queues
/// writes and replays them on reconnect — so this banner is purely reassurance,
/// not an error. It animates its height in/out and assumes "online" until the
/// first connectivity event arrives, so it never flashes on a healthy launch.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityStatusProvider).valueOrNull ?? true;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      alignment: Alignment.topCenter,
      child: online ? const SizedBox(width: double.infinity) : const _Bar(),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.inverseSurface,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 18, color: colors.onInverseSurface),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    "You're offline. Changes save on this device and sync when "
                    'you reconnect.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onInverseSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
