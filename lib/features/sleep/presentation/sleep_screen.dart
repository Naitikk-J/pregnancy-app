import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/sleep_entry.dart';
import 'sleep_providers.dart';

/// Sleep tracker: last night, 7-night average, a trend chart, and history.
class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(sleepEntriesProvider);
    final avg = ref.watch(sleepAverageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log sleep'),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load sleep',
          message: '$e',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.bedtime_outlined,
              title: 'No sleep logged yet',
              message: 'Track how long and how well you sleep — rest matters '
                  'more than ever now.',
              actionLabel: 'Log sleep',
              onAction: () => _addEntry(context, ref),
            );
          }
          final last = entries.first;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                        child: _stat(context, 'Last night',
                            '${last.hours.toStringAsFixed(1)} h')),
                    Expanded(
                        child: _stat(context, '7-night avg',
                            '${avg.toStringAsFixed(1)} h')),
                    Expanded(
                        child: _stat(
                            context, 'Quality', '${last.quality}/5')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Trend'),
              SizedBox(height: 200, child: _SleepChart(entries: entries)),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'History'),
              for (final e in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text('${e.hours.toStringAsFixed(1)} hours'),
                  subtitle: Text('Quality ${e.quality}/5 · '
                      '${DateFormat('EEE, d MMM').format(e.loggedAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(sleepCrudProvider)?.delete(e.id),
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
    final hours = TextEditingController();
    var quality = 3;
    var date = DateTime.now();

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
              Text('Log sleep', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Hours slept',
                controller: hours,
                prefixIcon: Icons.bedtime_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Quality', style: ctx.textStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => quality = i),
                      icon: Icon(
                        i <= quality ? Icons.star : Icons.star_border,
                        color: ctx.colors.primary,
                      ),
                    ),
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
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 120)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => date = picked);
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
      final h = double.tryParse(hours.text.trim());
      if (h != null && h > 0 && h <= 24) {
        await ref.read(sleepCrudProvider)?.upsert(
              SleepEntry(
                id: const Uuid().v4(),
                hours: h,
                quality: quality,
                loggedAt: date,
              ),
            );
      }
    }
    hours.dispose();
  }
}

class _SleepChart extends StatelessWidget {
  const _SleepChart({required this.entries});
  final List<SleepEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ordered = [...entries]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return BarChart(
      BarChartData(
        maxY: 12,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < ordered.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: ordered[i].hours,
                color: context.colors.primary,
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }
}
