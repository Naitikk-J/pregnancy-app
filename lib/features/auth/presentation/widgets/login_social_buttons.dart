import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

/// Circular social sign-in buttons (Google, Apple, Facebook / Guest)
/// styled to match the reference 3D clay login screen.
class LoginSocialButtons extends ConsumerWidget {
  const LoginSocialButtons({this.onDone, super.key});

  final VoidCallback? onDone;

  bool get _showApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider.notifier);
    final isBusy = ref.watch(authControllerProvider).isLoading;

    Future<void> run(Future<bool> Function() action) async {
      final ok = await action();
      if (ok) onDone?.call();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google button
        _SocialCircleButton(
          tooltip: 'Continue with Google',
          onPressed: isBusy ? null : () => run(controller.signInWithGoogle),
          child: const _GoogleIcon(),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Apple button (or guest on non-apple platforms)
        _SocialCircleButton(
          tooltip: _showApple ? 'Continue with Apple' : 'Continue as guest',
          onPressed: isBusy
              ? null
              : () => run(
                    _showApple
                        ? controller.signInWithApple
                        : controller.signInAsGuest,
                  ),
          child: Icon(
            _showApple ? Icons.apple : Icons.person_outline,
            size: 26,
            color: const Color(0xFF222222),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Guest button
        _SocialCircleButton(
          tooltip: 'Continue as guest',
          onPressed: isBusy ? null : () => run(controller.signInAsGuest),
          child: const Icon(
            Icons.person_rounded,
            size: 26,
            color: Color(0xFF5D3A48),
          ),
        ),
      ],
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    required this.child,
    required this.onPressed,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Custom painted Google 'G' icon for high fidelity.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: _GooglePainter(),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final strokeWidth = size.width * 0.22;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Blue arc (top-right to middle right)
    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.4, 1.2, false, strokePaint);

    // Green arc (bottom-right to bottom-left)
    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.5, false, strokePaint);

    // Yellow arc (bottom-left to top-left)
    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.3, 1.3, false, strokePaint);

    // Red arc (top-left to top-right)
    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.6, 1.3, false, strokePaint);

    // Horizontal blue bar in the middle
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - 1,
        center.dy - strokeWidth / 2,
        radius - 1,
        strokeWidth,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
