import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/food_guide.dart';

/// Nutrition guide: a filterable food-safety list plus key nutrients. Static
/// content — no account or network needed.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  FoodSafety? _filter;

  @override
  Widget build(BuildContext context) {
    final items = _filter == null
        ? kFoodGuide
        : kFoodGuide.where((f) => f.safety == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Key nutrients'),
          for (final n in kNutrientTips)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.nutrient, style: context.textStyles.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(n.why, style: context.textStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Sources: ${n.sources}',
                      style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Food safety'),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final s in FoodSafety.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _filter == s,
                  onSelected: (_) => setState(() => _filter = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final f in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icon(f.safety), color: _color(context, f.safety)),
              title: Text(f.name),
              subtitle: Text(f.reason),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'General guidance, not medical advice. Discuss your specific diet '
            'with your doctor or a dietitian.',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _icon(FoodSafety s) => switch (s) {
        FoodSafety.safe => Icons.check_circle,
        FoodSafety.limit => Icons.info,
        FoodSafety.avoid => Icons.cancel,
      };

  Color _color(BuildContext context, FoodSafety s) => switch (s) {
        FoodSafety.safe => context.colors.primary,
        FoodSafety.limit => context.colors.tertiary,
        FoodSafety.avoid => context.colors.error,
      };
}
