import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant { filled, tonal, outlined, text }

/// The app's primary tactile button ("Serene Bloom").
///
/// Features smooth spring micro-interaction, haptic response, theme-driven
/// colors, loading state, and accessible typography.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || widget.isLoading || _pressed == value) return;
    if (value) {
      HapticFeedback.lightImpact();
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;

    final Color contentColor;
    switch (widget.variant) {
      case AppButtonVariant.filled:
        contentColor = scheme.onPrimary;
        break;
      case AppButtonVariant.tonal:
        contentColor = scheme.primary;
        break;
      case AppButtonVariant.outlined:
        contentColor = scheme.primary;
        break;
      case AppButtonVariant.text:
        contentColor = scheme.primary;
        break;
    }

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 19,
                  color: contentColor,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    Widget button;

    switch (widget.variant) {
      case AppButtonVariant.filled:
        button = Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, const Color(0xFFC75B72), 0.3) ??
                    scheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: InkWell(
              onTap: effectiveOnPressed,
              onTapDown: effectiveOnPressed == null ? null : (_) => _setPressed(true),
              onTapUp: effectiveOnPressed == null ? null : (_) => _setPressed(false),
              onTapCancel: effectiveOnPressed == null ? null : () => _setPressed(false),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: content,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.tonal:
        button = Container(
          height: 52,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: scheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: InkWell(
              onTap: effectiveOnPressed,
              onTapDown: effectiveOnPressed == null ? null : (_) => _setPressed(true),
              onTapUp: effectiveOnPressed == null ? null : (_) => _setPressed(false),
              onTapCancel: effectiveOnPressed == null ? null : () => _setPressed(false),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: content,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.outlined:
        button = Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: scheme.primary,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: InkWell(
              onTap: effectiveOnPressed,
              onTapDown: effectiveOnPressed == null ? null : (_) => _setPressed(true),
              onTapUp: effectiveOnPressed == null ? null : (_) => _setPressed(false),
              onTapCancel: effectiveOnPressed == null ? null : () => _setPressed(false),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: content,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          child: content,
        );
        break;
    }

    final animated = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: button,
    );

    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: animated)
        : animated;
  }
}

