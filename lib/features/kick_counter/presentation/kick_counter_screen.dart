import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/ticker_provider.dart';
import '../domain/kick_session.dart';
import 'kick_counter_providers.dart';

/// Baby kick counter: start a session and tap for each movement. Reaching the
/// target (10) completes and saves the session automatically.
class KickCounterScreen extends ConsumerWidget {
  const KickCounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeKickSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kick counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Report',
            onPressed: () => context.pushNamed(AppRoutes.movementReportName),
          ),
        ],
      ),
      body: active == null
          ? const _KickHistoryView()
          : _ActiveSessionView(session: active),
    );
  }
}

class _ActiveSessionView extends ConsumerWidget {
  const _ActiveSessionView({required this.session});
  final KickSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ticks the elapsed label while the session runs.
    ref.watch(tickerProvider);
    final controller = ref.read(activeKickSessionProvider.notifier);
    final elapsed = session.elapsed();
    final done = session.isComplete;

    return SafeArea(
      // Spread the content out when there's room, but scroll instead of
      // overflowing on short screens (the big tap target is intentionally large).
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    AppCard(
                      color: done
                          ? context.colors.primaryContainer
                          : context.colors.surfaceContainerHighest,
                      child: Column(
                        children: [
                          Text(
                            done
                                ? 'Great — you felt ${session.targetKicks} kicks!'
                                : 'Counting movements',
                            style: context.textStyles.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(DurationFormat.clock(elapsed),
                              style: context.textStyles.displaySmall),
                          Text('elapsed',
                              style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('${session.kickCount}',
                        style: context.textStyles.displayLarge
                            ?.copyWith(color: context.colors.primary)),
                    Text('of ${session.targetKicks} kicks',
                        style: context.textStyles.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(
                      value: (session.kickCount / session.targetKicks)
                          .clamp(0.0, 1.0),
                      minHeight: 8,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    const Spacer(),
                    if (!done)
                      _TapButton(onTap: controller.addKick)
                    else
                      Icon(Icons.check_circle,
                          size: 96, color: context.colors.primary),
                    const Spacer(),
                    AppButton(
                      label: done ? 'Done' : 'Stop & save',
                      icon: done ? Icons.check : Icons.stop,
                      onPressed: () => controller.finish(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Discard',
                      variant: AppButtonVariant.text,
                      onPressed: controller.discard,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The big circular "I felt a kick" target.
class _TapButton extends StatelessWidget {
  const _TapButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Record a kick',
      child: Material(
        color: context.colors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.child_care,
                    size: 56, color: context.colors.onPrimary),
                const SizedBox(height: AppSpacing.sm),
                Text('I felt a kick',
                    style: context.textStyles.titleMedium
                        ?.copyWith(color: context.colors.onPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KickHistoryView extends ConsumerWidget {
  const _KickHistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(kickSessionsProvider);

    return sessionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load sessions',
        message: '$e',
      ),
      data: (all) {
        final sessions = all.where((s) => s.isComplete).toList();
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              color: context.colors.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Count the kicks',
                      style: context.textStyles.titleMedium?.copyWith(
                          color: context.colors.onSecondaryContainer)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pick a time your baby is usually active, get comfortable, '
                    'and tap for each movement. Most babies reach 10 kicks '
                    'within about 2 hours. Tell your doctor if movements slow '
                    'down or change.',
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.colors.onSecondaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Start counting',
              icon: Icons.play_arrow,
              onPressed: () =>
                  ref.read(activeKickSessionProvider.notifier).start(),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'History'),
            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text('No sessions yet.',
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              )
            else
              for (final s in sessions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.reachedTarget
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: s.reachedTarget
                        ? context.colors.primary
                        : context.colors.outline,
                  ),
                  title: Text('${s.kickCount} kicks in '
                      '${DurationFormat.compact(s.elapsed())}'),
                  subtitle: Text(
                      DateFormat('EEE, d MMM · HH:mm').format(s.startedAt)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(kickCrudProvider)?.delete(s.id),
                  ),
                ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}
