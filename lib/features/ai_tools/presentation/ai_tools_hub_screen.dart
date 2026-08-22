import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// Hub for the AI-powered helpers: Mira chat, symptom "is this normal?" check,
/// meal planner, yoga & movement, and a weekly summary of your logged data.
class AiToolsHubScreen extends StatelessWidget {
  const AiToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <(IconData, String, String, String)>[
      (Icons.auto_awesome, 'Ask Mira', 'Chat about anything pregnancy',
          AppRoutes.aiAssistantName),
      (Icons.health_and_safety_outlined, 'Is this normal?',
          'Check a symptom for reassurance & red flags', AppRoutes.symptomCheckerName),
      (Icons.restaurant_menu, 'Weekly meal plan',
          'A balanced 7-day plan for your diet', AppRoutes.mealPlannerName),
      (Icons.self_improvement, 'Yoga & movement',
          'Safe poses & light exercise for you', AppRoutes.wellnessPlanName),
      (Icons.insights_outlined, 'Weekly summary',
          'AI recap of what you logged this week', AppRoutes.weeklySummaryName),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AI health tools')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            color: context.colors.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: context.colors.onPrimaryContainer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Smart, gentle guidance — educational, never a diagnosis.',
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.colors.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (icon, title, subtitle, route) in tools)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                onTap: () => context.pushNamed(route),
                child: Row(
                  children: [
                    Icon(icon, size: 28, color: context.colors.primary),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.textStyles.titleMedium),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
