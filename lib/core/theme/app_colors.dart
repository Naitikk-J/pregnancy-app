import 'package:flutter/material.dart';

/// The brand palette for Pregnancy Companion ("Serene Bloom").
///
/// Warm, calm, reassuring, and premium — maternal rose, gentle sage,
/// soft porcelain surfaces, and deep plum high-contrast typography.
class AppColors {
  AppColors._();

  // Primary Brand Tones (Warm Rose & Blush)
  static const Color primary = Color(0xFFE87A90); // Warm rose accent
  static const Color primaryDark = Color(0xFFC75B72); // Deep rose for contrast
  static const Color primaryLight = Color(0xFFFFDADA); // Legacy soft blush
  static const Color primaryContainer = Color(0xFFFDECEF); // Delicate blush container

  // Secondary Health Accents (Earthy Sage & Mint)
  static const Color secondary = Color(0xFF7C9A92); // Soothing sage
  static const Color secondaryDark = Color(0xFF5D7B73);
  static const Color secondaryContainer = Color(0xFFEBF3F0); // Mint mist container
  static const Color tertiary = Color(0xFFE2A96D); // Warm amber / golden glow
  static const Color tertiaryContainer = Color(0xFFFEF4E8);

  // Gradient & Hero Backgrounds
  static const Color heroGradientStart = Color(0xFFFFFFFF);
  static const Color heroGradientMid = Color(0xFFFFF6F8);
  static const Color heroGradientEnd = Color(0xFFFDECEF);
  static const Color babyBlush = Color(0xFFFFF0F3);

  // Trimester Progress Ring Segments
  static const List<Color> ringSegments = [
    Color(0xFF76C8A4), // Sage green
    Color(0xFF65C8BF), // Teal mint
    Color(0xFFF28882), // Soft coral
    Color(0xFFEAA662), // Warm amber
    Color(0xFFA294DC), // Gentle lavender
  ];

  // Semantic Status Colors
  static const Color success = Color(0xFF34A870);
  static const Color successContainer = Color(0xFFEAF7EE);
  static const Color warning = Color(0xFFF29C38);
  static const Color warningContainer = Color(0xFFFEF6EA);
  static const Color danger = Color(0xFFE6535D);
  static const Color dangerContainer = Color(0xFFFDEBED);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFEFF6FF);

  // Neutrals (Light Mode) — Soft warm porcelain and petal cream
  static const Color lightBackground = Color(0xFFFFFDFD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFFBF6F7);
  static const Color lightSurfaceVariant = Color(0xFFF6EEF1);
  static const Color lightOutline = Color(0xFFEEDDE3);
  static const Color textPrimaryLight = Color(0xFF2D1C24);
  static const Color textSecondaryLight = Color(0xFF755964);
  static const Color textTertiaryLight = Color(0xFFA58B96);

  // Neutrals (Dark Mode) — Warm-tinted deep charcoal & plum
  static const Color darkBackground = Color(0xFF191215);
  static const Color darkSurface = Color(0xFF231A1E);
  static const Color darkSurfaceContainer = Color(0xFF2B2026);
  static const Color darkSurfaceVariant = Color(0xFF382B32);
  static const Color darkOutline = Color(0xFF4A3A42);
  static const Color textPrimaryDark = Color(0xFFFCEEEF);
  static const Color textSecondaryDark = Color(0xFFBFA8B1);
  static const Color textTertiaryDark = Color(0xFF8C737D);

  // Risk Category Colors
  static const Color riskLow = Color(0xFF34A870);
  static const Color riskMedium = Color(0xFFF29C38);
  static const Color riskHigh = Color(0xFFE6535D);
}

