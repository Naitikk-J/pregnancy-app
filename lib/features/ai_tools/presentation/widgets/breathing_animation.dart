import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

/// A calming, asset-free guided-breathing animation: a soft circle that expands
/// as you breathe in and contracts as you breathe out, with a changing prompt.
class BreathingAnimation extends StatefulWidget {
  const BreathingAnimation({super.key});

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _phase = 'Breathe in';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.forward) {
          setState(() => _phase = 'Breathe in');
        } else if (status == AnimationStatus.reverse) {
          setState(() => _phase = 'Breathe out');
        }
      });
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Center(
            child: AnimatedBuilder(
              animation: curve,
              builder: (context, _) {
                final t = curve.value; // 0..1
                final size = 90 + t * 60; // 90 -> 150
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primary
                        .withValues(alpha: 0.15 + t * 0.25),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary
                            .withValues(alpha: 0.25 + t * 0.2),
                        blurRadius: 24 * t + 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.favorite,
                        color: context.colors.primary, size: 28 + t * 8),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(_phase, style: context.textStyles.titleMedium),
        Text('Follow the circle · relax your shoulders',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}
