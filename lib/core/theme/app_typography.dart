import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for the app, built on Google Fonts.
///
/// Headlines use `Poppins` (friendly, rounded); body uses `Inter` (highly
/// legible at small sizes and when text is scaled up for accessibility).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;

    final display = GoogleFonts.poppinsTextTheme(base).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final body = GoogleFonts.interTextTheme(base).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    // Slightly tightened tracking on the rounded Poppins headings reads as more
    // premium; comfortable line-height on Inter body improves readability.
    return TextTheme(
      displayLarge: display.displayLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.05),
      displayMedium: display.displayMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.75, height: 1.08),
      displaySmall: display.displaySmall
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.1),
      headlineLarge: display.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.15),
      headlineMedium: display.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.2),
      headlineSmall: display.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.25, height: 1.25),
      titleLarge: display.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.25),
      titleMedium: body.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.45),
      bodySmall: body.bodySmall?.copyWith(height: 1.4),
      labelLarge: body.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: body.labelMedium?.copyWith(letterSpacing: 0.1),
      labelSmall: body.labelSmall?.copyWith(letterSpacing: 0.2),
    );
  }
}
