import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/week_content.dart';

/// The hero card showing baby size comparison, length and weight for the week.
class BabySizeCard extends StatelessWidget {
  const BabySizeCard({required this.content, super.key});

  final WeekContent content;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          colors: [scheme.secondaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.child_care,
                size: 40, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your baby is about the size of',
                    style: context.textStyles.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer)),
                Text(content.sizeComparison,
                    style: context.textStyles.titleLarge?.copyWith(
                        color: scheme.onSecondaryContainer)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  children: [
                    if (content.lengthLabel != null)
                      _stat(context, Icons.straighten, content.lengthLabel!),
                    if (content.weightLabel != null)
                      _stat(context, Icons.scale, content.weightLabel!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: context.textStyles.labelMedium
                  ?.copyWith(color: context.colors.onSecondaryContainer)),
        ],
      );
}

/// A collapsible section (development, avoid, nutrition, …). Renders either a
/// paragraph [body] or a bulleted [items] list.
class WeekSectionCard extends StatelessWidget {
  const WeekSectionCard({
    required this.title,
    required this.icon,
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
  final String? body;
  final List<String> items;

  /// Optional illustration shown at the top of the section's expanded content.
  final String? imageAsset;

  /// Optional call-to-action shown at the bottom of the expanded content
  /// (e.g. "Get an AI plan for your stage").
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if ((body == null || body!.isEmpty) && items.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: context.theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          leading: Icon(icon, color: context.colors.primary),
          title: Text(title, style: context.textStyles.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: [
            if (imageAsset != null) ...[
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primaryContainer.withValues(alpha: 0.5),
                      context.colors.secondaryContainer.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (body != null && body!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(body!, style: context.textStyles.bodyMedium),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                      child: Icon(Icons.circle,
                          size: 6, color: context.colors.primary),
                    ),
                    Expanded(
                        child: Text(item,
                            style: context.textStyles.bodyMedium)),
                  ],
                ),
              ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.auto_awesome, size: 18),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// FAQ list for the week.
class WeekFaqSection extends StatelessWidget {
  const WeekFaqSection({required this.faqs, super.key});
  final List<FaqItem> faqs;

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: context.theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.help_outline, color: context.colors.primary),
          title: Text('FAQs', style: context.textStyles.titleMedium),
          shape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          children: [
            for (final faq in faqs)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faq.question,
                        style: context.textStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(faq.answer, style: context.textStyles.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
