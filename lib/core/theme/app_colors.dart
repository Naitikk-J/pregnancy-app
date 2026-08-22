import 'package:flutter/material.dart';

/// The brand palette for Pregnancy Companion.
///
/// Warm, calm and reassuring — a deep-teal "action" colour paired with soft
/// blush, coral and cream, inspired by modern maternal-wellness design. Deep
/// teal carries CTAs, the bottom nav and the FAB; blush/coral bring emotional
/// warmth; cream keeps every screen soft rather than clinical white.
class AppColors {
  AppColors._();

  // Brand seeds.
  static const Color primary = Color(0xFF14564D); // deep teal (CTAs, nav, FAB)
  static const Color primaryDark = Color(0xFF0E3F38);
  static const Color secondary = Color(0xFFF1857B); // warm coral / salmon
  static const Color tertiary = Color(0xFF8E7CC3); // soft lavender accent

  /// The signature hero gradient (blush → coral → peach) used behind the
  /// circular baby-growth ring and other headline surfaces.
  static const Color heroGradientStart = Color(0xFFFBE6E0); // pale blush
  static const Color heroGradientMid = Color(0xFFF9D3CB); // blush
  static const Color heroGradientEnd = Color(0xFFF7E3CB); // warm peach cream

  /// Soft blush used for the baby-illustration halo at the centre of the ring
  /// and other gentle "baby" surfaces.
  static const Color babyBlush = Color(0xFFFBE3DD);

  /// Segment colours for the multi-colour trimester progress ring (green →
  /// mint → coral → amber → lavender), matching the reference design.
  static const List<Color> ringSegments = [
    Color(0xFF7FC8A0), // green
    Color(0xFF6FD0C0), // mint-teal
    Color(0xFFF0857D), // coral
    Color(0xFFF4B36B), // amber
    Color(0xFFA99BE0), // lavender
  ];

  // Semantic
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFF0A63C);
  static const Color danger = Color(0xFFE86A5E);
  static const Color info = Color(0xFF2E86C1);

  // Neutrals (light) — a warm cream so screens feel soft and never stark white.
  static const Color lightBackground = Color(0xFFFBF6F1);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1EAE4);

  // Neutrals (dark) — warm-tinted charcoal to stay on-brand in dark mode.
  static const Color darkBackground = Color(0xFF111615);
  static const Color darkSurface = Color(0xFF1A2220);
  static const Color darkSurfaceVariant = Color(0xFF25302D);

  // Risk category colors (used across dashboard, doctor portal)
  static const Color riskLow = Color(0xFF2E9E6B);
  static const Color riskMedium = Color(0xFFF0A63C);
  static const Color riskHigh = Color(0xFFE86A5E);
}
