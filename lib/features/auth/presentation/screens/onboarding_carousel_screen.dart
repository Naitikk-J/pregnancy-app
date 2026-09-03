import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cute_doodles.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.doodle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget doodle;
  final Color accentColor;
}

/// The first-run marketing carousel shown to signed-out users, leading into
/// sign-in / sign-up. Redesigned with cute doodles and pastel gradients.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final _controller = PageController();
  int _index = 0;

  static final _slides = [
    _Slide(
      icon: Icons.calendar_month_rounded,
      title: 'Track Every Week',
      body:
          'Follow your baby\'s growth and your body\'s beautiful changes, week by week with personalized insights.',
      doodle: const CuteFootprint(size: 28, color: Color(0xFF7FC8A0)),
      accentColor: const Color(0xFF7FC8A0),
    ),
    _Slide(
      icon: Icons.medication_rounded,
      title: 'Never Miss a Moment',
      body:
          'Smart reminders for medicines, hydration, appointments and prenatal vitamins — so you can focus on what matters.',
      doodle: const CuteSparkle(size: 28, color: Color(0xFF5CB8E4)),
      accentColor: const Color(0xFF5CB8E4),
    ),
    _Slide(
      icon: Icons.favorite_rounded,
      title: 'Care, Together',
      body:
          'Invite your partner, family and doctor to support your journey with shared tracking and real-time updates.',
      doodle: const CuteHeart(size: 28, color: Color(0xFFE87A90)),
      accentColor: const Color(0xFFE87A90),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      context.goNamed(AppRoutes.loginName);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding:
                    const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm),
                child: TextButton(
                  onPressed: () => context.goNamed(AppRoutes.loginName),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFFC48B9F),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with doodle accents
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Outer soft glow
                            Container(
                              height: 190,
                              width: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    s.accentColor.withValues(alpha: 0.15),
                                    s.accentColor.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            // Main circle
                            Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    s.accentColor.withValues(alpha: 0.12),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: s.accentColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        s.accentColor.withValues(alpha: 0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                s.icon,
                                size: 72,
                                color: s.accentColor,
                              ),
                            ),
                            // Floating doodle top right
                            Positioned(
                              top: -4,
                              right: 2,
                              child: s.doodle,
                            ),
                            // Floating flower bottom left
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: CuteFlower(
                                size: 22,
                                petalColor: s.accentColor.withValues(alpha: 0.6),
                              ),
                            ),
                            // Little sparkle
                            Positioned(
                              top: 16,
                              left: 8,
                              child: CuteSparkle(
                                size: 14,
                                color: s.accentColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Title
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5D3A48),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Body text
                        Text(
                          s.body,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: const Color(0xFF5D3A48)
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 28 : 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? slide.accentColor
                          : const Color(0xFFFFDADA),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
              ],
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: slide.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _next,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLast ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isLast
                                ? Icons.arrow_forward_rounded
                                : Icons.chevron_right_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Secondary CTA
                  TextButton(
                    onPressed: () => context.goNamed(AppRoutes.loginName),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        color: Color(0xFFC48B9F),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
