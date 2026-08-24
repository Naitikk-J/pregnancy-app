import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_time_picker.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/glucose_reading.dart';
import 'glucose_providers.dart';

/// Blood-sugar tracker: latest reading with in-range status, target guidance
/// per context, a trend chart, and history.
class GlucoseScreen extends ConsumerWidget {
  const GlucoseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(glucoseReadingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blood sugar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReading(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log reading'),
      ),
      body: readingsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load readings',
          message: '$e',
        ),
        data: (readings) {
          if (readings.isEmpty) {
            return EmptyState(
              icon: Icons.bloodtype_outlined,
              title: 'No readings yet',
              message: 'Log your blood sugar (mg/dL) with its context to track '
                  'against healthy pregnancy targets.',
              actionLabel: 'Log reading',
              onAction: () => _addReading(context, ref),
            );
          }
          final latest = readings.first;
          final high = latest.status == 'High';
          final low = latest.status == 'Low';
          final concern = high || low;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                color: concern
                    ? context.colors.errorContainer
                    : context.colors.secondaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latest (${latest.context.label.toLowerCase()})',
                        style: context.textStyles.bodySmall?.copyWith(
                            color: concern
                                ? context.colors.onErrorContainer
                                : context.colors.onSecondaryContainer)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${latest.mgDl.toStringAsFixed(0)} mg/dL · ${latest.status}',
                        style: context.textStyles.headlineMedium?.copyWith(
                            color: concern
                                ? context.colors.onErrorContainer
                                : context.colors.onSecondaryContainer)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Target ${latest.context.label.toLowerCase()}: ≤ '
                      '${HealthCalculator.glucoseUpperTarget(latest.context).toStringAsFixed(0)} mg/dL',
                      style: context.textStyles.bodyMedium?.copyWith(
                          color: concern
                              ? context.colors.onErrorContainer
                              : context.colors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Trend'),
              SizedBox(height: 220, child: _GlucoseChart(readings: readings)),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'History'),
              for (final r in readings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    r.inRange ? Icons.check_circle : Icons.warning_amber,
                    color: r.inRange
                        ? context.colors.secondary
                        : context.colors.error,
                  ),
                  title: Text('${r.mgDl.toStringAsFixed(0)} mg/dL · ${r.status}'),
                  subtitle: Text('${r.context.label} · '
                      '${DateFormat('EEE, d MMM · HH:mm').format(r.loggedAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(glucoseCrudProvider)?.delete(r.id),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addReading(BuildContext context, WidgetRef ref) async {
    final value = TextEditingController();
    var glucoseContext = GlucoseContext.fasting;
    var loggedAt = DateTime.now();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log blood sugar', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Reading (mg/dL)',
                controller: value,
                prefixIcon: Icons.bloodtype_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('When', style: ctx.textStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final c in GlucoseContext.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: glucoseContext == c,
                      onSelected: (_) => setState(() => glucoseContext = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(52),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('When: '
                      '${DateFormat('EEE, d MMM · h:mm a').format(loggedAt)}'),
                ),
                onPressed: () async {
                  final picked = await pickDateTime(ctx, initial: loggedAt);
                  if (picked != null) setState(() => loggedAt = picked);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                  label: 'Save', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      final v = double.tryParse(value.text.trim());
      if (v != null && v > 0) {
        await ref.read(glucoseCrudProvider)?.upsert(
              GlucoseReading(
                id: const Uuid().v4(),
                mgDl: v,
                context: glucoseContext,
                loggedAt: loggedAt,
              ),
            );
      }
    }
    value.dispose();
  }
}

class _GlucoseChart extends StatelessWidget {
  const _GlucoseChart({required this.readings});
  final List<GlucoseReading> readings;

  @override
  Widget build(BuildContext context) {
    final ordered = [...readings]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final spots = <FlSpot>[
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), ordered[i].mgDl),
    ];
    final maxY = ordered.map((e) => e.mgDl).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 50,
        maxY: (maxY + 20).ceilToDouble(),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: context.colors.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: context.colors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
