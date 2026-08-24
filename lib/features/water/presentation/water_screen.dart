import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/water_day.dart';
import 'water_providers.dart';

/// Water tracker: a circular progress ring with quick-add controls and a
/// timestamped log of each drink.
class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  /// Logs [ml] of water at [at] (defaults to now) as a timestamped entry.
  void _add(WidgetRef ref, int ml, {DateTime? at}) {
    final repo = ref.read(waterRepositoryProvider);
    if (repo == null) return;
    final now = DateTime.now();
    final when = at ?? now;
    repo.addEntry(
      IdUtils.dateKey(when),
      WaterEntry(id: const Uuid().v4(), ml: ml, at: when),
      ref.read(waterGoalProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(todayWaterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water'),
        actions: [
          IconButton(
            tooltip: 'Reset today',
            onPressed: () => ref.read(waterRepositoryProvider)?.reset(
                  IdUtils.dateKey(DateTime.now()),
                  ref.read(waterGoalProvider),
                ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: waterAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load water intake',
          message: '$e',
        ),
        data: (water) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: SizedBox(
                height: 220,
                width: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: CircularProgressIndicator(
                        value: water.progress,
                        strokeWidth: 16,
                        backgroundColor: context.colors.surfaceContainerHighest,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.water_drop,
                            color: context.colors.primary, size: 32),
                        Text('${water.consumedMl} ml',
                            style: context.textStyles.headlineMedium),
                        Text('of ${water.goalMl} ml',
                            style: context.textStyles.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                        Text('${water.glasses} / ${water.goalGlasses} glasses',
                            style: context.textStyles.labelMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AddChip(
                  label: '+1 glass',
                  sublabel: '${AppConstants.glassMl} ml',
                  icon: Icons.local_drink,
                  onTap: () => _add(ref, AppConstants.glassMl),
                ),
                _AddChip(
                  label: '+ Bottle',
                  sublabel: '500 ml',
                  icon: Icons.sports_bar,
                  onTap: () => _add(ref, 500),
                ),
                _AddChip(
                  label: '+ Custom',
                  sublabel: 'amount · time',
                  icon: Icons.add,
                  onTap: () => _addCustom(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (water.progress >= 1.0)
              AppCard(
                color: context.colors.secondaryContainer,
                child: Row(
                  children: [
                    Icon(Icons.celebration,
                        color: context.colors.onSecondaryContainer),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text('Goal reached — great job staying hydrated!',
                          style: context.textStyles.titleSmall?.copyWith(
                              color: context.colors.onSecondaryContainer)),
                    ),
                  ],
                ),
              ),
            if (water.entries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Today’s log'),
              for (final e in water.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.water_drop_outlined,
                      color: context.colors.primary),
                  title: Text('${e.ml} ml'),
                  subtitle: Text(DateFormat('h:mm a').format(e.at)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(waterRepositoryProvider)
                        ?.removeEntry(water, e, ref.read(waterGoalProvider)),
                  ),
                ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Sheet to log a custom amount at a specific time of day.
  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final amountCtrl = TextEditingController(text: '200');
    var time = TimeOfDay.fromDateTime(DateTime.now());

    final saved = await showModalBottomSheet<bool>(
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
              Text('Log water', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Amount (ml)',
                controller: amountCtrl,
                prefixIcon: Icons.water_drop_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(52),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('At: ${time.format(ctx)}'),
                ),
                onPressed: () async {
                  final picked =
                      await showTimePicker(context: ctx, initialTime: time);
                  if (picked != null) setState(() => time = picked);
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

    if (saved == true) {
      final ml = int.tryParse(amountCtrl.text.trim());
      if (ml != null && ml > 0) {
        final now = DateTime.now();
        _add(ref, ml,
            at: DateTime(now.year, now.month, now.day, time.hour, time.minute));
      }
    }
    amountCtrl.dispose();
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Icon(icon, color: context.colors.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: context.textStyles.labelLarge),
              Text(sublabel,
                  style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
