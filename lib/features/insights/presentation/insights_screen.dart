import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../blood_pressure/domain/bp_reading.dart';
import '../../blood_pressure/presentation/bp_providers.dart';
import '../../blood_sugar/domain/glucose_reading.dart';
import '../../blood_sugar/presentation/glucose_providers.dart';
import '../../sleep/domain/sleep_entry.dart';
import '../../sleep/presentation/sleep_providers.dart';
import '../../weight/domain/weight_entry.dart';
import '../../weight/presentation/weight_providers.dart';

/// A visual health dashboard: trends for weight, blood pressure, blood sugar
/// and sleep, drawn from the data the mother has logged. Read-only.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const _maxPoints = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = _asc<WeightEntry>(
        ref.watch(weightEntriesProvider).valueOrNull ?? const [],
        (e) => e.loggedAt);
    final bp = _asc<BpReading>(
        ref.watch(bpReadingsProvider).valueOrNull ?? const [],
        (e) => e.loggedAt);
    final glucose = _asc<GlucoseReading>(
        ref.watch(glucoseReadingsProvider).valueOrNull ?? const [],
        (e) => e.loggedAt);
    final sleep = _asc<SleepEntry>(
        ref.watch(sleepEntriesProvider).valueOrNull ?? const [],
        (e) => e.loggedAt);

    final hasAny =
        weight.isNotEmpty || bp.isNotEmpty || glucose.isNotEmpty || sleep.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Health insights')),
      body: !hasAny
          ? const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No data to chart yet',
              message: 'Log your weight, blood pressure, blood sugar or sleep and '
                  'your trends will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SectionHeader(title: 'At a glance'),
                _summaryTiles(context, weight, bp, glucose, sleep),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Trends'),
                const SizedBox(height: AppSpacing.sm),
                if (weight.isNotEmpty)
                  _ChartCard(
                    title: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    subtitle: _range(weight.length),
                    chartBuilder: (t) => _line(
                      context,
                      _last(weight)
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
                          .toList(),
                      context.colors.primary,
                      t: t,
                    ),
                  ),
                if (bp.isNotEmpty)
                  _ChartCard(
                    title: 'Blood pressure (mmHg)',
                    icon: Icons.favorite_outline,
                    subtitle: 'Systolic (top) & diastolic (bottom)',
                    chartBuilder: (t) => _line(
                      context,
                      _last(bp)
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.systolic.toDouble()))
                          .toList(),
                      Colors.redAccent,
                      spots2: _last(bp)
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.diastolic.toDouble()))
                          .toList(),
                      color2: Colors.blueAccent,
                      t: t,
                    ),
                  ),
                if (glucose.isNotEmpty)
                  _ChartCard(
                    title: 'Blood sugar (mg/dL)',
                    icon: Icons.water_drop_outlined,
                    subtitle: _range(glucose.length),
                    chartBuilder: (t) => _line(
                      context,
                      _last(glucose)
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.mgDl))
                          .toList(),
                      Colors.deepPurpleAccent,
                      t: t,
                    ),
                  ),
                if (sleep.isNotEmpty)
                  _ChartCard(
                    title: 'Sleep (hours)',
                    icon: Icons.bedtime_outlined,
                    subtitle: _range(sleep.length),
                    chartBuilder: (t) => _bars(
                      context,
                      _last(sleep).map((e) => e.hours).toList(),
                      context.colors.tertiary,
                      t: t,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Charts show your most recent readings. Informational only — '
                  'discuss trends with your doctor.',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
    );
  }

  // ---- data helpers ----
  static List<T> _asc<T>(List<T> src, DateTime Function(T) at) =>
      [...src]..sort((a, b) => at(a).compareTo(at(b)));

  List<T> _last<T>(List<T> src) =>
      src.length <= _maxPoints ? src : src.sublist(src.length - _maxPoints);

  static String _range(int n) =>
      n == 1 ? '1 reading' : 'last ${n < _maxPoints ? n : _maxPoints} readings';

  Widget _summaryTiles(
    BuildContext context,
    List<WeightEntry> weight,
    List<BpReading> bp,
    List<GlucoseReading> glucose,
    List<SleepEntry> sleep,
  ) {
    final avgSleep = sleep.isEmpty
        ? null
        : (sleep.reversed.take(7).fold<double>(0, (s, e) => s + e.hours) /
            sleep.reversed.take(7).length);
    final tiles = <Widget>[
      if (weight.isNotEmpty)
        _StatTile(
          label: 'Latest weight',
          value: '${weight.last.weightKg.toStringAsFixed(1)} kg',
          icon: Icons.monitor_weight_outlined,
        ),
      if (bp.isNotEmpty)
        _StatTile(
          label: 'Latest BP',
          value: '${bp.last.systolic}/${bp.last.diastolic}',
          icon: Icons.favorite_outline,
        ),
      if (glucose.isNotEmpty)
        _StatTile(
          label: 'Latest sugar',
          value: '${glucose.last.mgDl.toStringAsFixed(0)} mg/dL',
          icon: Icons.water_drop_outlined,
        ),
      if (avgSleep != null)
        _StatTile(
          label: 'Avg sleep (7n)',
          value: '${avgSleep.toStringAsFixed(1)} h',
          icon: Icons.bedtime_outlined,
        ),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: tiles,
    );
  }

  // ---- charts ----
  Widget _line(
    BuildContext context,
    List<FlSpot> spots,
    Color color, {
    List<FlSpot>? spots2,
    Color? color2,
    double t = 1,
  }) {
    // Grow the lines in from the series baseline (their minimum) as t: 0→1.
    final all = [...spots, if (spots2 != null) ...spots2];
    final baseline =
        all.isEmpty ? 0.0 : all.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    List<FlSpot> grow(List<FlSpot> s) =>
        [for (final p in s) FlSpot(p.x, baseline + (p.y - baseline) * t)];
    spots = grow(spots);
    if (spots2 != null) spots2 = grow(spots2);
    LineChartBarData bar(List<FlSpot> s, Color c) => LineChartBarData(
          spots: s,
          isCurved: true,
          preventCurveOverShooting: true,
          color: c,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: spots2 == null,
            color: c.withValues(alpha: 0.12),
          ),
        );
    return LineChart(
      LineChartData(
        lineTouchData: const LineTouchData(enabled: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(0),
                style: context.textStyles.labelSmall,
              ),
            ),
          ),
        ),
        lineBarsData: [
          bar(spots, color),
          if (spots2 != null) bar(spots2, color2 ?? color),
        ],
      ),
    );
  }

  Widget _bars(BuildContext context, List<double> values, Color color,
      {double t = 1}) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(0),
                style: context.textStyles.labelSmall,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i] * t,
                color: color,
                width: 10,
                borderRadius: BorderRadius.circular(3),
              ),
            ]),
        ],
      ),
    );
  }
}

/// A chart card whose graph animates in — it "grows" from the baseline to the
/// real values once on mount via a 0→1 tween passed to [chartBuilder].
class _ChartCard extends StatefulWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.chartBuilder,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final Widget Function(double t) chartBuilder;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  double _t = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _t = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 18, color: context.colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(widget.title, style: context.textStyles.titleSmall),
                ),
                Text(widget.subtitle,
                    style: context.textStyles.labelSmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _t),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => widget.chartBuilder(t),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - AppSpacing.lg * 2 - AppSpacing.md) / 2;
    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: context.textStyles.titleLarge),
            Text(label,
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
