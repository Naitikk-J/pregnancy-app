import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cute_doodles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/presentation/controllers/profile_providers.dart';
import '../controllers/week_content_providers.dart';
import '../widgets/week_content_widgets.dart';

/// Currently selected week in the tracker. Null means "follow the mother's
/// current pregnancy week".
final selectedWeekProvider = StateProvider<int?>((ref) => null);

/// The 40-week pregnancy tracker: a week selector plus rich, collapsible
/// content sections ("Serene Bloom"). Defaults to the user's current week.
class WeekTrackerScreen extends ConsumerWidget {
  const WeekTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final currentWeek = pregnancy?.currentWeek ?? 1;
    final selected = ref.watch(selectedWeekProvider) ?? currentWeek;
    final contentAsync = ref.watch(weekContentProvider(selected));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Week Tracker',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            CuteSparkle(size: 16, color: scheme.primary),
          ],
        ),
        actions: [
          if (selected != currentWeek)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(selectedWeekProvider.notifier).state = null;
              },
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text(
                'Today',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _WeekSelector(
            selected: selected,
            currentWeek: currentWeek,
            onSelected: (w) {
              HapticFeedback.selectionClick();
              ref.read(selectedWeekProvider.notifier).state = w;
            },
          ),
          Expanded(
            child: contentAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => EmptyState(
                icon: Icons.cloud_off,
                title: 'Could not load week $selected',
                message: '$e',
                actionLabel: 'Retry',
                onAction: () =>
                    ref.invalidate(weekContentProvider(selected)),
              ),
              data: (content) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  120,
                ),
                children: [
                  // Week & Trimester header
                  _WeekTrimesterHeader(
                    week: content.week,
                    trimesterLabel: content.trimester.label,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Baby size hero card
                  BabySizeCard(content: content),
                  const SizedBox(height: AppSpacing.xl),

                  // --- Baby Category ---
                  _TrackerCategoryHeader(
                    title: 'Your Baby',
                    badge: 'Growth',
                    badgeColor: AppColors.secondary,
                    icon: CuteFootprint(size: 18, color: AppColors.secondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Baby Development',
                    icon: Icons.child_care_rounded,
                    iconColor: AppColors.secondary,
                    body: content.babyDevelopment,
                    imageAsset: 'assets/images/baby.png',
                    initiallyExpanded: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // --- Mother's Body Category ---
                  _TrackerCategoryHeader(
                    title: 'Your Body',
                    badge: 'Changes',
                    badgeColor: scheme.primary,
                    icon: CuteHeart(size: 18, color: scheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Body Changes',
                    icon: Icons.pregnant_woman_rounded,
                    iconColor: scheme.primary,
                    body: content.motherChanges,
                    imageAsset: 'assets/images/mom.png',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Things to Avoid',
                    icon: Icons.do_not_disturb_on_rounded,
                    iconColor: AppColors.danger,
                    items: content.avoid,
                    imageAsset: 'assets/images/sec_avoid.png',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // --- Medical Advice Category ---
                  const _TrackerCategoryHeader(
                    title: 'Doctor\'s Advice',
                    badge: 'Medical',
                    badgeColor: AppColors.info,
                    icon: CuteSparkle(size: 18, color: AppColors.info),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Clinical Guidance',
                    icon: Icons.medical_information_rounded,
                    iconColor: AppColors.info,
                    body: content.advice,
                    imageAsset: 'assets/images/sec_doctor.png',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // --- Wellness & Nutrition Category ---
                  _TrackerCategoryHeader(
                    title: 'Wellness & Nutrition',
                    badge: 'Self-care',
                    badgeColor: AppColors.secondaryDark,
                    icon: const CuteFlower(size: 18),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Nutrition Guide',
                    icon: Icons.restaurant_rounded,
                    iconColor: AppColors.secondaryDark,
                    items: content.nutrition,
                    imageAsset: 'assets/images/sec_nutrition.png',
                    actionLabel: 'Get an AI weekly meal plan',
                    actionIcon: Icons.restaurant_menu,
                    onAction: () =>
                        context.pushNamed(AppRoutes.mealPlannerName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Safe Exercise',
                    icon: Icons.directions_walk_rounded,
                    iconColor: AppColors.tertiary,
                    items: content.exercises,
                    imageAsset: 'assets/images/sec_exercise.png',
                    actionLabel: 'Get an AI movement plan',
                    actionIcon: Icons.self_improvement,
                    onAction: () =>
                        context.pushNamed(AppRoutes.wellnessPlanName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekSectionCard(
                    title: 'Prenatal Yoga',
                    icon: Icons.self_improvement_rounded,
                    iconColor: AppColors.ringSegments[4],
                    items: content.yoga,
                    imageAsset: 'assets/images/sec_yoga.png',
                    actionLabel: 'Get an AI yoga & movement plan',
                    actionIcon: Icons.auto_awesome,
                    onAction: () =>
                        context.pushNamed(AppRoutes.wellnessPlanName),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // --- FAQs ---
                  const _TrackerCategoryHeader(
                    title: 'Common Questions',
                    badge: 'FAQs',
                    badgeColor: AppColors.tertiary,
                    icon: CuteCloud(size: 24, color: AppColors.tertiary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WeekFaqSection(faqs: content.faqs),
                  const SizedBox(height: AppSpacing.lg),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: scheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        CuteHeart(size: 16, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppConstants.appName} provides general information and is '
                            'not a substitute for professional medical advice.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Week and trimester header with sparkle.
class _WeekTrimesterHeader extends StatelessWidget {
  const _WeekTrimesterHeader({
    required this.week,
    required this.trimesterLabel,
  });

  final int week;
  final String trimesterLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          'Week $week',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              trimesterLabel,
              style: TextStyle(
                color: scheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Spacer(),
        CuteFlower(size: 20, petalColor: scheme.primary),
      ],
    );
  }
}

/// Category section header for tracker content groups.
class _TrackerCategoryHeader extends StatelessWidget {
  const _TrackerCategoryHeader({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          CuteSparkle(size: 12, color: badgeColor.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// Horizontal, scrollable 1–40 week selector with cute pill chips.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final controller = ScrollController(
      initialScrollOffset: ((selected - 1) * 56.0 - 100).clamp(0, 40 * 56.0),
    );
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFFC48B9F).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            IconButton(
              onPressed:
                  selected > 1 ? () => onSelected(selected - 1) : null,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
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
                        horizontal: 3, vertical: AppSpacing.md),
                    child: GestureDetector(
                      onTap: () => onSelected(week),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 46,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary
                              : isCurrent
                                  ? scheme.primaryContainer
                                  : (isDark ? scheme.surfaceContainerHigh : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : isCurrent
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: scheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$week',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                              ),
                            ),
                            if (isCurrent && !isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              onPressed: selected < AppConstants.fullTermWeeks
                  ? () => onSelected(selected + 1)
                  : null,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

