import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/presentation/controllers/profile_providers.dart';
import '../controllers/week_content_providers.dart';
import '../widgets/week_content_widgets.dart';

/// Currently selected week in the tracker. Null means "follow the mother's
/// current pregnancy week".
final selectedWeekProvider = StateProvider<int?>((ref) => null);

/// The 40-week pregnancy tracker: a week selector plus rich, collapsible
/// content sections. Defaults to the user's current week.
class WeekTrackerScreen extends ConsumerWidget {
  const WeekTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final currentWeek = pregnancy?.currentWeek ?? 1;
    final selected = ref.watch(selectedWeekProvider) ?? currentWeek;
    final contentAsync = ref.watch(weekContentProvider(selected));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Week tracker'),
        actions: [
          if (selected != currentWeek)
            TextButton(
              onPressed: () =>
                  ref.read(selectedWeekProvider.notifier).state = null,
              child: const Text('Today'),
            ),
        ],
      ),
      body: Column(
        children: [
          _WeekSelector(
            selected: selected,
            currentWeek: currentWeek,
            onSelected: (w) =>
                ref.read(selectedWeekProvider.notifier).state = w,
          ),
          const Divider(height: 1),
          Expanded(
            child: contentAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => EmptyState(
                icon: Icons.cloud_off,
                title: 'Could not load week $selected',
                message: '$e',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(weekContentProvider(selected)),
              ),
              data: (content) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Week ${content.week} · ${content.trimester.label}',
                    style: context.textStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BabySizeCard(content: content),
                  const SizedBox(height: AppSpacing.lg),
                  WeekSectionCard(
                    title: 'Baby development',
                    icon: Icons.child_care,
                    body: content.babyDevelopment,
                    imageAsset: 'assets/images/baby.png',
                    initiallyExpanded: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Your body',
                    icon: Icons.pregnant_woman,
                    body: content.motherChanges,
                    imageAsset: 'assets/images/mom.png',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Things to avoid',
                    icon: Icons.do_not_disturb_on_outlined,
                    items: content.avoid,
                    imageAsset: 'assets/images/sec_avoid.png',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Doctor’s advice',
                    icon: Icons.medical_information_outlined,
                    body: content.advice,
                    imageAsset: 'assets/images/sec_doctor.png',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Nutrition',
                    icon: Icons.restaurant_outlined,
                    items: content.nutrition,
                    imageAsset: 'assets/images/sec_nutrition.png',
                    actionLabel: 'Get an AI weekly meal plan',
                    actionIcon: Icons.restaurant_menu,
                    onAction: () => context.pushNamed(AppRoutes.mealPlannerName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Exercise',
                    icon: Icons.directions_walk,
                    items: content.exercises,
                    imageAsset: 'assets/images/sec_exercise.png',
                    actionLabel: 'Get an AI movement plan',
                    actionIcon: Icons.self_improvement,
                    onAction: () => context.pushNamed(AppRoutes.wellnessPlanName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Yoga',
                    icon: Icons.self_improvement,
                    items: content.yoga,
                    imageAsset: 'assets/images/sec_yoga.png',
                    actionLabel: 'Get an AI yoga & movement plan',
                    actionIcon: Icons.auto_awesome,
                    onAction: () => context.pushNamed(AppRoutes.wellnessPlanName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekFaqSection(faqs: content.faqs),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${AppConstants.appName} provides general information and is '
                    'not a substitute for professional medical advice.',
                    style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal, scrollable 1–40 week selector with prev/next controls.
class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.selected,
    required this.currentWeek,
    required this.onSelected,
  });

  final int selected;
  final int currentWeek;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController(
      initialScrollOffset: ((selected - 1) * 56.0 - 100).clamp(0, 40 * 56.0),
    );
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          IconButton(
            onPressed: selected > 1 ? () => onSelected(selected - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.fullTermWeeks,
              itemBuilder: (context, i) {
                final week = i + 1;
                final isSelected = week == selected;
                final isCurrent = week == currentWeek;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: AppSpacing.md),
                  child: ChoiceChip(
                    label: Text('$week'),
                    selected: isSelected,
                    avatar: isCurrent && !isSelected
                        ? Icon(Icons.circle,
                            size: 8, color: context.colors.primary)
                        : null,
                    onSelected: (_) => onSelected(week),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: selected < AppConstants.fullTermWeeks
                ? () => onSelected(selected + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
