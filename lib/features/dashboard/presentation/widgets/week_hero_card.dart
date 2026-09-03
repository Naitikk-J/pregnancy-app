import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cute_doodles.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../week_tracker/presentation/controllers/week_content_providers.dart';

/// The signature home hero: a horizontal "Baby Loading Bar" on a
/// soft blush surface, with cute doodles and the current
/// week/progress ("Serene Bloom").
class WeekHeroCard extends ConsumerWidget {
  const WeekHeroCard({required this.pregnancy, super.key});

  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final week = pregnancy.currentWeek;
    final progress = pregnancy.progress;
    final progressPercent = (progress * 100).toInt().clamp(0, 100);
    final size = ref
        .watch(weekContentProvider(pregnancy.currentWeek))
        .valueOrNull
        ?.sizeComparison;
    final onHero = scheme.onSurface;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Week $week',
                        style: context.textStyles.headlineMedium?.copyWith(
                          color: onHero,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const CuteSparkle(size: 16),
                    ],
                  ),
                  Text(
                    'of 40 weeks • $progressPercent% Loaded',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const _BouncingHeart(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _BabyLoadingBar(progress: progress),
          if (size != null && size.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _infoRow(
              context,
              Icons.eco_rounded,
              'Size of ${_article(size)} $size',
              onHero,
            ),
          ],
        ],
      ),
    );
  }

  static String _article(String word) {
    if (word.isEmpty) return 'a';
    return 'aeiouAEIOU'.contains(word[0]) ? 'an' : 'a';
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, Color onHero) {
    return Row(
      children: [
        const CuteFlower(size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: context.textStyles.bodyMedium?.copyWith(
              color: onHero,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


/// A horizontal rounded progress bar with a cute footprint at the leading edge.
class _BabyLoadingBar extends StatelessWidget {
  const _BabyLoadingBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final fillWidth = trackWidth * value;

            return SizedBox(
              height: 24,
              child: Stack(
                children: [
                  // Unfilled track
                  Container(
                    width: trackWidth,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  // Filled track
                  Container(
                    width: fillWidth,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer,
                          scheme.primary,
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  // The cute footprint "knob" at the end of the progress
                  Positioned(
                    left: (fillWidth - 28).clamp(0, trackWidth - 28),
                    top: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? scheme.surface : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black38
                                : const Color(0xFFC48B9F).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Center(
                        child: CuteFootprint(
                          size: 14,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


/// A playful micro-animation to add delight to the hero card.
class _BouncingHeart extends StatefulWidget {
  const _BouncingHeart();

  @override
  State<_BouncingHeart> createState() => _BouncingHeartState();
}

class _BouncingHeartState extends State<_BouncingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: Transform.scale(
            scale: 0.9 + (0.1 * t),
            child: child,
          ),
        );
      },
      child: Icon(
        Icons.favorite,
        color: Theme.of(context).colorScheme.primary,
        size: 32,
      ),
    );
  }
}

