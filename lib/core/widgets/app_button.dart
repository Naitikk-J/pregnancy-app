import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant { filled, tonal, outlined, text }

/// The app's primary button. Handles a built-in loading state (disables input
/// and shows a spinner) and an optional leading icon. Full-width by default so
/// it's an easy touch target for one-handed use.
class AppButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.filled =>
        FilledButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.tonal =>
        FilledButton.tonal(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.outlined =>
        OutlinedButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.text =>
        TextButton(onPressed: effectiveOnPressed, child: child),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
