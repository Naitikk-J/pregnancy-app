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
import '../domain/contraction.dart';
import '../domain/contraction_analysis.dart';
import 'contraction_providers.dart';

/// Contraction timer: one big start/stop control, a live 5-1-1 read-out, and a
/// history of each contraction's length and interval.
class ContractionTimerScreen extends ConsumerWidget {
  const ContractionTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeContractionProvider);
    final analysis = ref.watch(contractionAnalysisProvider);
    final contractionsAsync = ref.watch(contractionsProvider);
    // Ticks the running timer & rolls the analysis window.
    ref.watch(tickerProvider);

    final controller = ref.read(activeContractionProvider.notifier);
    final running = active != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contraction timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Report',
            onPressed: () => context.pushNamed(AppRoutes.movementReportName),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _GuidanceCard(meets511: analysis.meets511, guidance: analysis.guidance),
          const SizedBox(height: AppSpacing.lg),
          _StatsRow(analysis: analysis),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: _StartStopButton(
              running: running,
              elapsedLabel: running
                  ? DurationFormat.clock(active.duration())
                  : null,
              onPressed: () => running ? controller.stop() : controller.start(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'History'),
          contractionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: LoadingView(),
            ),
            error: (e, _) => Text('Could not load contractions: $e',
                style: context.textStyles.bodyMedium),
            data: (contractions) {
              final completed =
                  contractions.where((c) => c.isComplete).toList();
              if (completed.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text('No contractions timed yet.',
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < completed.length; i++)
                    _ContractionTile(
                      contraction: completed[i],
                      // completed is newest-first, so the next item is older.
                      previous: i + 1 < completed.length
                          ? completed[i + 1]
                          : null,
                      onDelete: () => ref
                          .read(contractionCrudProvider)
                          ?.delete(completed[i].id),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.meets511, required this.guidance});
  final bool meets511;
  final String guidance;

  @override
  Widget build(BuildContext context) {
    final color =
        meets511 ? context.colors.errorContainer : context.colors.secondaryContainer;
    final onColor = meets511
        ? context.colors.onErrorContainer
        : context.colors.onSecondaryContainer;
    return AppCard(
      color: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meets511 ? Icons.local_hospital : Icons.info_outline,
              color: onColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(guidance,
                style: context.textStyles.bodyMedium?.copyWith(color: onColor)),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.analysis});
  final ContractionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: context.textStyles.titleLarge),
              Text(label,
                  style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant)),
            ],
          ),
        );
    final interval = analysis.averageInterval;
    final duration = analysis.averageDuration;
    return AppCard(
      child: Row(
        children: [
          stat('last hour', '${analysis.recentCount}'),
          stat('avg interval',
              interval == null ? '—' : DurationFormat.compact(interval)),
          stat('avg length',
              duration == null ? '—' : DurationFormat.compact(duration)),
        ],
      ),
    );
  }
}

class _StartStopButton extends StatelessWidget {
  const _StartStopButton({
    required this.running,
    required this.onPressed,
    this.elapsedLabel,
  });
  final bool running;
  final String? elapsedLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = running ? context.colors.error : context.colors.primary;
    final onColor =
        running ? context.colors.onError : context.colors.onPrimary;
    return Semantics(
      button: true,
      label: running ? 'Stop contraction' : 'Start contraction',
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(running ? Icons.stop : Icons.play_arrow,
                    size: 56, color: onColor),
                const SizedBox(height: AppSpacing.sm),
                Text(running ? (elapsedLabel ?? '') : 'Start',
                    style: context.textStyles.headlineSmall
                        ?.copyWith(color: onColor)),
                if (running)
                  Text('tap to stop',
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: onColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractionTile extends StatelessWidget {
  const _ContractionTile({
    required this.contraction,
    required this.previous,
    required this.onDelete,
  });
  final Contraction contraction;
  final Contraction? previous;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final interval = previous == null
        ? null
        : contraction.startedAt.difference(previous!.startedAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timelapse),
      title: Text('Lasted ${DurationFormat.compact(contraction.duration())}'),
      subtitle: Text(
        '${DateFormat('d MMM · HH:mm').format(contraction.startedAt)}'
        '${interval == null ? '' : '  ·  ${DurationFormat.compact(interval)} apart'}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
