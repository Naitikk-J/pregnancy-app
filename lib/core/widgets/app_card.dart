import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// A modern surface card used throughout the app ("Serene Bloom").
///
/// Features theme-driven surfaces, soft ambient shadows, rounded borders,
/// and tactile micro-interaction press response.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderColor,
    this.borderRadius,
    this.elevation = 0,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    if (value) {
      HapticFeedback.selectionClick();
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusCard);
    final surfaceColor = widget.color ??
        (isDark ? scheme.surfaceContainer : scheme.surfaceContainerLow);
    final effectiveBorder = widget.borderColor ?? scheme.outlineVariant;

    final card = Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFFC48B9F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
          onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
          onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
          borderRadius: effectiveRadius,
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: card,
    );
  }
}

