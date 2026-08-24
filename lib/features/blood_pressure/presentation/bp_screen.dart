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
import '../../../core/widgets/widgets.dart';
import '../domain/bp_reading.dart';
import 'bp_providers.dart';

/// Blood-pressure tracker: latest reading with category, a systolic/diastolic
/// trend chart, and history.
class BpScreen extends ConsumerWidget {
  const BpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(bpReadingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blood pressure')),
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
              icon: Icons.favorite_outline,
              title: 'No readings yet',
              message: 'Log your blood pressure to watch trends and spot '
                  'high readings early.',
              actionLabel: 'Log reading',
              onAction: () => _addReading(context, ref),
            );
          }
          final latest = readings.first;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _LatestCard(reading: latest),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Trend'),
              SizedBox(height: 220, child: _BpChart(readings: readings)),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'History'),
              for (final r in readings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle,
                      size: 14, color: _categoryColor(context, r.category)),
                  title: Text('${r.systolic}/${r.diastolic} mmHg'
                      '${r.pulse != null ? '  ·  ${r.pulse} bpm' : ''}'),
                  subtitle: Text(
                      '${r.category.label} · '
                      '${DateFormat('EEE, d MMM · HH:mm').format(r.loggedAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(bpCrudProvider)?.delete(r.id),
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
    final sys = TextEditingController();
    final dia = TextEditingController();
    final pulse = TextEditingController();
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
            children: [
              Text('Log blood pressure', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Systolic',
                      controller: sys,
                      prefixIcon: Icons.arrow_upward,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Diastolic',
                      controller: dia,
                      prefixIcon: Icons.arrow_downward,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Pulse (optional)',
                controller: pulse,
                prefixIcon: Icons.monitor_heart_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSpacing.md),
              _WhenPicker(
                value: loggedAt,
                onChanged: (v) => setState(() => loggedAt = v),
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
      final s = int.tryParse(sys.text.trim());
      final d = int.tryParse(dia.text.trim());
      if (s != null && d != null && s > 0 && d > 0) {
        await ref.read(bpCrudProvider)?.upsert(
              BpReading(
                id: const Uuid().v4(),
                systolic: s,
                diastolic: d,
                pulse: int.tryParse(pulse.text.trim()),
                loggedAt: loggedAt,
              ),
            );
      }
    }
    sys.dispose();
    dia.dispose();
    pulse.dispose();
  }
}

/// A labelled "When" row that opens a date + time picker, shared styling for the
/// vitals log sheets. Shows the chosen date/time and lets the user change it.
class _WhenPicker extends StatelessWidget {
  const _WhenPicker({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.event),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(52),
      ),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'When: ${DateFormat('EEE, d MMM · h:mm a').format(value)}',
        ),
      ),
      onPressed: () async {
        final picked = await pickDateTime(context, initial: value);
        if (picked != null) onChanged(picked);
      },
    );
  }
}

Color _categoryColor(BuildContext context, BpCategory category) =>
    switch (category) {
      BpCategory.normal => context.colors.secondary,
      BpCategory.elevated || BpCategory.stage1 => context.colors.tertiary,
      BpCategory.stage2 || BpCategory.crisis || BpCategory.low =>
        context.colors.error,
    };

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.reading});
  final BpReading reading;

  @override
  Widget build(BuildContext context) {
    final concern = reading.category.isConcern;
    final bg = concern
        ? context.colors.errorContainer
        : context.colors.secondaryContainer;
    final fg = concern
        ? context.colors.onErrorContainer
        : context.colors.onSecondaryContainer;
    return AppCard(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest',
              style: context.textStyles.bodySmall?.copyWith(color: fg)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${reading.systolic}/${reading.diastolic}',
                  style: context.textStyles.displaySmall?.copyWith(color: fg)),
              const SizedBox(width: AppSpacing.sm),
              Text('mmHg',
                  style: context.textStyles.titleMedium?.copyWith(color: fg)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(concern ? Icons.warning_amber : Icons.check_circle_outline,
                  size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  concern
                      ? '${reading.category.label} — mention this to your doctor.'
                      : '${reading.category.label} range.',
                  style: context.textStyles.bodyMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BpChart extends StatelessWidget {
  const _BpChart({required this.readings});
  final List<BpReading> readings;

  @override
  Widget build(BuildContext context) {
    final ordered = [...readings]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    List<FlSpot> spots(int Function(BpReading) sel) => [
          for (var i = 0; i < ordered.length; i++)
            FlSpot(i.toDouble(), sel(ordered[i]).toDouble()),
        ];

    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 200,
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
            spots: spots((r) => r.systolic),
            isCurved: true,
            barWidth: 3,
            color: context.colors.primary,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots((r) => r.diastolic),
            isCurved: true,
            barWidth: 3,
            color: context.colors.tertiary,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
