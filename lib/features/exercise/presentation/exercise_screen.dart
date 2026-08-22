import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/exercise_guide.dart';

/// Exercise guide: safety tips plus pregnancy-safe exercises, filterable by
/// trimester (defaults to the mother's current trimester).
class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int? _trimester;
  bool _initialised = false;

  @override
  Widget build(BuildContext context) {
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    if (!_initialised && pregnancy != null) {
      _trimester = switch (pregnancy.trimester.name) {
        'first' => 1,
        'second' => 2,
        _ => 3,
      };
      _initialised = true;
    }

    final items = _trimester == null
        ? kExercises
        : kExercises.where((e) => e.suitsTrimester(_trimester!)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            color: context.colors.secondaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stay active, safely',
                    style: context.textStyles.titleMedium?.copyWith(
                        color: context.colors.onSecondaryContainer)),
                const SizedBox(height: AppSpacing.sm),
                for (final tip in kExerciseSafetyTips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check,
                            size: 16,
                            color: context.colors.onSecondaryContainer),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(tip,
                              style: context.textStyles.bodySmall?.copyWith(
                                  color:
                                      context.colors.onSecondaryContainer)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Exercises'),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _trimester == null,
                onSelected: (_) => setState(() => _trimester = null),
              ),
              for (var t = 1; t <= 3; t++)
                ChoiceChip(
                  label: Text('Trimester $t'),
                  selected: _trimester == t,
                  onSelected: (_) => setState(() => _trimester = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final e in items)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center,
                          size: 20, color: context.colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(e.name,
                              style: context.textStyles.titleSmall)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(e.description, style: context.textStyles.bodyMedium),
                  if (e.caution != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber,
                            size: 16, color: context.colors.tertiary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(e.caution!,
                              style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
