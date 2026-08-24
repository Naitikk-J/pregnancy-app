import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Convenience accessors on [BuildContext] to cut boilerplate in widgets.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Localized strings for the active locale.
  AppLocalizations get l10n => AppLocalizations.of(this);

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Rough form-factor helpers for responsive layouts.
  bool get isCompact => screenWidth < 600;
  bool get isMedium => screenWidth >= 600 && screenWidth < 840;
  bool get isExpanded => screenWidth >= 840;

  /// Padding for a scroll-controlled modal bottom sheet. Insets every side by
  /// [horizontal]/[top], and pads the bottom by the on-screen keyboard height
  /// **plus the system navigation-bar inset** — so the last control (e.g. a Save
  /// button) is never hidden behind the keyboard or the gesture / 3-button nav
  /// bar. `showModalBottomSheet` applies no safe area of its own, which is why
  /// the bar would otherwise overlap the sheet's bottom.
  EdgeInsets sheetPadding({
    double horizontal = AppSpacing.lg,
    double top = AppSpacing.lg,
  }) {
    final m = MediaQuery.of(this);
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: top,
      // viewInsets = keyboard; viewPadding.bottom = nav bar (stays put when the
      // keyboard is up, so both are additive and neither control is clipped).
      bottom: m.viewInsets.bottom + m.viewPadding.bottom + AppSpacing.lg,
    );
  }

  void showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(this)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.errorContainer : null,
      ),
    );
  }
}
