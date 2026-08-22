import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_utils.dart';
import '../../../core/widgets/widgets.dart';
import 'water_providers.dart';

/// Water tracker: a circular progress ring with quick-add controls.
class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  void _add(WidgetRef ref, int ml) {
    final repo = ref.read(waterRepositoryProvider);
    if (repo == null) return;
    repo.addMl(IdUtils.dateKey(DateTime.now()), ml, ref.read(waterGoalProvider));
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
                  sublabel: '100 ml',
                  icon: Icons.add,
                  onTap: () => _add(ref, 100),
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
          ],
        ),
      ),
    );
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
