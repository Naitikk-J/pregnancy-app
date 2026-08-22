import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../week_tracker/presentation/controllers/week_content_providers.dart';

/// The signature home hero: a multi-colour circular "baby growth" ring on a
/// soft blush surface, with a baby illustration at its centre and the current
/// week, trimester and days-to-go beside it. Inspired by modern maternal
/// wellness design — warm, emotional and glanceable.
class WeekHeroCard extends ConsumerWidget {
  const WeekHeroCard({required this.pregnancy, super.key});

  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = pregnancy.currentWeek;
    final daysLeft = pregnancy.daysRemaining;
    final size = ref
        .watch(weekContentProvider(pregnancy.currentWeek))
        .valueOrNull
        ?.sizeComparison;
    final onHero = AppColors.primaryDark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        gradient: const LinearGradient(
          colors: [
            AppColors.heroGradientStart,
            AppColors.heroGradientMid,
            AppColors.heroGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: pregnancy.progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => _BabyRing(progress: value),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week $week',
                  style: context.textStyles.headlineSmall?.copyWith(
                      color: onHero, fontWeight: FontWeight.w800),
                ),
                Text(
                  'of 40 weeks',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: onHero.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _pill(context, Icons.spa_rounded, pregnancy.trimester.label,
                    onHero),
                const SizedBox(height: AppSpacing.sm),
                _infoRow(context, Icons.favorite_rounded,
                    context.l10n.daysToGo(daysLeft), onHero),
                if (size != null && size.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(context, Icons.eco_rounded,
                      'Size of ${_article(size)} $size', onHero),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _article(String word) {
    if (word.isEmpty) return 'a';
    return 'aeiouAEIOU'.contains(word[0]) ? 'an' : 'a';
  }

  Widget _pill(
      BuildContext context, IconData icon, String label, Color onHero) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: context.textStyles.labelMedium?.copyWith(
                  color: onHero, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, Color onHero) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: context.textStyles.bodyMedium
                ?.copyWith(color: onHero.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }
}

/// The circular multi-colour growth ring with a baby illustration in the centre
/// and a progress knob marking how far along the journey is.
class _BabyRing extends StatelessWidget {
  const _BabyRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const _BreathingBaby(),
          ),
        ),
      ),
    );
  }
}

/// The baby illustration with a gentle, looping "breathing" motion (a soft
/// scale + vertical bob) so the hero feels alive rather than static.
class _BreathingBaby extends StatefulWidget {
  const _BreathingBaby();

  @override
  State<_BreathingBaby> createState() => _BreathingBabyState();
}

class _BreathingBabyState extends State<_BreathingBaby>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
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
        final t = curve.value; // 0..1
        return Transform.translate(
          offset: Offset(0, -2 + t * 4), // gentle bob
          child: Transform.scale(scale: 0.95 + t * 0.08, child: child),
        );
      },
      child: Image.asset(
        'assets/images/baby.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.child_care_rounded, size: 32, color: AppColors.primary),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - 12) / 2;
    const stroke = 9.0;
    const start = -math.pi / 2; // 12 o'clock
    const full = 2 * math.pi;

    final segments = AppColors.ringSegments;
    final segSweep = full / segments.length;
    const gap = 0.10; // radians between segments

    // Multi-colour decorative journey track.
    for (var i = 0; i < segments.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = segments[i].withValues(alpha: 0.85);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + i * segSweep + gap / 2,
        segSweep - gap,
        false,
        paint,
      );
    }

    // Progress knob riding along the ring at the current progress angle.
    final p = progress.clamp(0.0, 1.0);
    final angle = start + full * p;
    final knobCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(knobCenter, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      knobCenter,
      8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.primary,
    );
    canvas.drawCircle(knobCenter, 3, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
