import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cute_doodles.dart';
import '../../domain/entities/week_content.dart';

/// The hero card showing baby size comparison, length and weight for the week.
class BabySizeCard extends StatelessWidget {
  const BabySizeCard({required this.content, super.key});

  final WeekContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  scheme.surfaceContainerHigh,
                  scheme.surfaceContainer,
                  scheme.surfaceContainerLow,
                ]
              : [
                  Colors.white,
                  AppColors.heroGradientMid,
                  scheme.primaryContainer,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFFC48B9F).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: scheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.child_care_rounded,
                    size: 34, color: scheme.primary),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CuteSparkle(size: 12, color: scheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Your baby is about the size of',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    CuteHeart(size: 12, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  content.sizeComparison,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  children: [
                    if (content.lengthLabel != null)
                      _stat(context, Icons.straighten_rounded, content.lengthLabel!),
                    if (content.weightLabel != null)
                      _stat(context, Icons.scale_rounded, content.weightLabel!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// A collapsible section with cute styling. Renders either a paragraph [body]
/// or a bulleted [items] list, with optional illustration and CTA.
class WeekSectionCard extends StatelessWidget {
  const WeekSectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    this.body,
    this.items = const [],
    this.imageAsset,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? body;
  final List<String> items;
  final String? imageAsset;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if ((body == null || body!.isEmpty) && items.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = iconColor ?? scheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : effectiveColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? scheme.outlineVariant : effectiveColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Theme(
        data: context.theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 20, color: effectiveColor),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: [
            if (imageAsset != null) ...[
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  gradient: LinearGradient(
                    colors: [
                      effectiveColor.withValues(alpha: 0.12),
                      effectiveColor.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: CuteFlower(size: 32, petalColor: effectiveColor),
                  ),
                ),
              ),
            ],
            if (body != null && body!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  body!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            for (final item in items)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 6, right: AppSpacing.sm),
                      child: CuteSparkle(
                        size: 8,
                        color: effectiveColor.withValues(alpha: 0.7),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: effectiveColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.auto_awesome, size: 18),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// FAQ list for the week with cute doodle styling.
class WeekFaqSection extends StatelessWidget {
  const WeekFaqSection({required this.faqs, super.key});
  final List<FaqItem> faqs;

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.tertiary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? scheme.outlineVariant : AppColors.tertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: context.theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.tertiary.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(Icons.help_outline_rounded,
                size: 20, color: AppColors.tertiary),
          ),
          title: Text(
            'Frequently Asked Questions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          shape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          children: [
            for (final faq in faqs)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHigh
                        : scheme.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: scheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CuteSparkle(
                            size: 14,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              faq.question,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 22),
                        child: Text(
                          faq.answer,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

