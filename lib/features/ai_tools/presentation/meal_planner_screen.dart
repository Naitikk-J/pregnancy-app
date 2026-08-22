import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../document_scan/presentation/scan_providers.dart';
import '../domain/ai_models.dart';
import 'ai_tools_providers.dart';
import 'widgets/ai_disclaimer.dart';

/// Generates a personalised, India-first 7-day pregnancy meal plan based on the
/// mother's diet preference, trimester and any health conditions.
class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  bool _busy = false;
  String? _error;
  MealPlan? _plan;

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final plan = await ref.read(documentAiRepositoryProvider).mealPlan(
            diet: ref.read(dietPreferenceProvider),
            context: ref.read(aiContextProvider),
          );
      if (mounted) setState(() => _plan = plan);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is StateError
            ? e.message
            : 'Could not create the plan. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diet = ref.watch(dietPreferenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly meal plan')),
      body: _busy
          ? const LoadingView(message: 'Cooking up your week…')
          : _plan == null
              ? _intro(diet)
              : _result(_plan!),
    );
  }

  Widget _intro(String diet) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            color: context.colors.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant_menu,
                    size: 40, color: context.colors.onPrimaryContainer),
                const SizedBox(height: AppSpacing.sm),
                Text('A week of balanced meals',
                    style: context.textStyles.titleLarge
                        ?.copyWith(color: context.colors.onPrimaryContainer)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tailored to your $diet preference and this stage of pregnancy, '
                  'with everyday Indian foods.',
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null) ...[
            AppCard(
              color: context.colors.errorContainer,
              child: Text(_error!,
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.colors.onErrorContainer)),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppButton(
            label: 'Generate my plan',
            icon: Icons.auto_awesome,
            onPressed: _generate,
          ),
        ],
      );

  Widget _result(MealPlan p) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (p.keyNutrients.isNotEmpty)
            AppCard(
              color: context.colors.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Focus nutrients',
                      style: context.textStyles.titleSmall?.copyWith(
                          color: context.colors.onSecondaryContainer)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final n in p.keyNutrients)
                        Chip(
                          label: Text(n),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          for (final d in p.days) _dayCard(d),
          if (p.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Tips', style: context.textStyles.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            for (final t in p.tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text('• $t', style: context.textStyles.bodyMedium),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          AiDisclaimer(p.disclaimer),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Regenerate',
            icon: Icons.refresh,
            variant: AppButtonVariant.tonal,
            onPressed: _generate,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );

  Widget _dayCard(MealDay d) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.day, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              _meal('Breakfast', d.breakfast),
              _meal('Lunch', d.lunch),
              _meal('Snack', d.snack),
              _meal('Dinner', d.dinner),
            ],
          ),
        ),
      );

  Widget _meal(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: context.textStyles.bodyMedium,
          children: [
            TextSpan(
                text: '$label: ',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: context.colors.primary)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
