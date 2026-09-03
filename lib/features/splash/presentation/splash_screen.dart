import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/diagnostics.dart' as diag;
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cute_doodles.dart';
import '../../auth/presentation/controllers/auth_providers.dart';

/// Branded loading screen with cute doodle animation shown while auth state
/// resolves. Navigation is handled by the router's redirect.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authUserProvider);
    final errText = diag.firebaseInitError ??
        (auth.hasError ? '${auth.error}' : null);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Animated Logo with Floating Doodles ---
              AnimatedBuilder(
                animation: _breatheController,
                builder: (context, child) {
                  final scale = 1.0 + (_breatheController.value * 0.06);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Outer glow ring
                    Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFDADA).withValues(alpha: 0.6),
                            const Color(0xFFFFDADA).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // Main logo circle
                    Container(
                      height: 112,
                      width: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFFF0F5),
                            Color(0xFFFFDADA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFDADA),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFC48B9F).withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pregnant_woman_rounded,
                        size: 56,
                        color: Color(0xFFC48B9F),
                      ),
                    ),
                    // Floating doodles around the logo
                    const Positioned(
                      top: -8,
                      right: -4,
                      child: CuteSparkle(size: 18),
                    ),
                    const Positioned(
                      bottom: -2,
                      left: -6,
                      child: CuteHeart(size: 16),
                    ),
                    const Positioned(
                      top: 10,
                      left: -12,
                      child: CuteFlower(size: 20),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: -10,
                      child: CuteFootprint(size: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // --- App Name ---
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5D3A48),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Your journey, cared for 🌸',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8C6875),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // --- Error or Loading ---
              if (errText != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE86A5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: const Color(0xFFE86A5E).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFE86A5E), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errText.length > 200
                              ? errText.substring(0, 200)
                              : errText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE86A5E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: const Color(0xFFC48B9F),
                    backgroundColor:
                        const Color(0xFFFFDADA).withValues(alpha: 0.5),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // --- Build tag ---
              const Text(
                'build: ui-v16',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFBBA5AD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
