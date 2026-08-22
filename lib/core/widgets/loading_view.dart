import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Centered loading indicator with an optional message. Shows a gently pulsing
/// baby illustration above a slim progress indicator so waits feel warm and
/// on-brand rather than clinical. Used for full-screen and in-card loading.
class LoadingView extends StatefulWidget {
  const LoadingView({this.message, this.compact = false, super.key});

  final String? message;

  /// When true, hides the illustration (for small in-card loaders).
  final bool compact;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.compact)
            FadeTransition(
              opacity: Tween(begin: 0.65, end: 1.0).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeInOut),
              ),
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.06).animate(
                  CurvedAnimation(parent: _c, curve: Curves.easeInOut),
                ),
                child: Image.asset(
                  'assets/images/baby.png',
                  width: 96,
                  height: 96,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 0),
                ),
              ),
            ),
          if (!widget.compact) const SizedBox(height: AppSpacing.lg),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(widget.message!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
