import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/weight_entry.dart';
import 'weight_providers.dart';

/// Weight tracker: latest weight, BMI, recommended gain, and a trend chart.
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final heightCm = profile?.heightCm;

    return Scaffold(
      appBar: AppBar(title: const Text('Weight')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load weights',
          message: '$e',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'No weight logged yet',
              message: 'Track your weight to see trends and healthy-gain '
                  'guidance.',
              actionLabel: 'Log weight',
              onAction: () => _addEntry(context, ref),
            );
          }
          final latest = entries.first;
          final bmi = heightCm == null
              ? 0.0
              : HealthCalculator.bmi(
                  weightKg: latest.weightKg, heightCm: heightCm);
          final gain = HealthCalculator.recommendedTotalGainKg(bmi);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _stat(context, 'Current',
                          '${latest.weightKg.toStringAsFixed(1)} kg'),
                    ),
                    if (bmi > 0)
                      Expanded(
                        child: _stat(context, 'BMI',
                            '${bmi.toStringAsFixed(1)} · ${HealthCalculator.bmiCategory(bmi)}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (bmi > 0)
                AppCard(
                  color: context.colors.secondaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: context.colors.onSecondaryContainer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Recommended total gain: '
                          '${gain.min.toStringAsFixed(1)}–${gain.max.toStringAsFixed(1)} kg '
                          'for your pre-pregnancy BMI.',
                          style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Trend'),
              SizedBox(height: 220, child: _WeightChart(entries: entries)),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'History'),
              for (final e in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                  subtitle:
                      Text(DateFormat('EEE, d MMM yyyy').format(e.loggedAt)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(weightCrudProvider)?.delete(e.id),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: context.textStyles.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          Text(value, style: context.textStyles.titleLarge),
        ],
      );

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var date = DateTime.now();

    final result = await showModalBottomSheet<bool>(
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
            children: [
              Text('Log weight', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Weight (kg)',
                controller: controller,
                prefixIcon: Icons.monitor_weight_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('EEE, d MMM yyyy').format(date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 400)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Save',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final kg = double.tryParse(controller.text.trim());
      if (kg != null && kg > 0) {
        await ref.read(weightCrudProvider)?.upsert(
              WeightEntry(
                id: const Uuid().v4(),
                weightKg: kg,
                loggedAt: date,
              ),
            );
      }
    }
    controller.dispose();
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries});
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Chronological ascending for the x-axis.
    final ordered = [...entries]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final spots = <FlSpot>[
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), ordered[i].weightKg),
    ];
    final minY = ordered.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxY = ordered.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: (minY - 2).floorToDouble(),
        maxY: (maxY + 2).ceilToDouble(),
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
