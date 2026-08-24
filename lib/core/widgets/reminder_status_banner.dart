import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Warns when the OS is blocking on-device reminders (notifications turned off,
/// or exact alarms disabled), with a tap to fix it. Shown on the Medicines and
/// Reminders screens so "my reminders never fire" becomes something the user can
/// act on instead of a silent mystery.
///
/// Renders nothing when reminders are fully ready.
class ReminderStatusBanner extends ConsumerWidget {
  const ReminderStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationStatusProvider).valueOrNull;
    if (status == null || status.ready && status.exactAlarmsAllowed) {
      return const SizedBox.shrink();
    }
    final blocked = !status.notificationsEnabled;
    final color = blocked
        ? context.colors.errorContainer
        : context.colors.tertiaryContainer;
    final onColor = blocked
        ? context.colors.onErrorContainer
        : context.colors.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        color: color,
        onTap: () async {
          await ref.read(notificationServiceProvider).requestPermissions();
          ref.invalidate(notificationStatusProvider);
          if (context.mounted) {
            context.showSnack(
              blocked
                  ? 'If nothing changed, enable notifications in Settings → Apps '
                      '→ Pregnancy Companion, and turn off battery optimization.'
                  : 'Exact-alarm settings opened — allow it so reminders are on '
                      'time.',
            );
          }
        },
        child: Row(
          children: [
            Icon(blocked ? Icons.notifications_off_outlined : Icons.alarm_off,
                color: onColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blocked
                        ? 'Reminders are blocked'
                        : 'Reminders may be delayed',
                    style: context.textStyles.titleSmall?.copyWith(
                        color: onColor, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    blocked
                        ? 'Notifications are off for this app — tap to turn them '
                            'on so alarms can fire.'
                        : 'Exact alarms are off. Tap to allow precise reminder '
                            'times.',
                    style: context.textStyles.bodySmall?.copyWith(color: onColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: onColor),
          ],
        ),
      ),
    );
  }
}
