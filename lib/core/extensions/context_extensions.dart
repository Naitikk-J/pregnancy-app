import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

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
