import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/login_social_buttons.dart';

/// Email/password sign-in with a clay-style 3D layout adapted to the pink theme.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _accent = Color(0xFFC48B9F);
  static const _titleColor = Color(0xFF5D3A48);
  static const _subtitleColor = Color(0xFF8C6875);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isBusy = authState.isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final msg = next.error is Failure
            ? (next.error as Failure).message
            : 'Sign-in failed.';
        context.showSnack(msg, isError: true);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF2F5),
              Color(0xFFFFDADA),
              Color(0xFFFBE4EC),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          _DecorativeBackground(),
                          Column(
                            children: [
                              const SizedBox(height: AppSpacing.xl),
                              _PhoneFrame(
                                child: Column(
                                  children: [
                                    const SizedBox(height: AppSpacing.xxl),
                                    _LoginHeader(
                                      titleColor: _titleColor,
                                      subtitleColor: _subtitleColor,
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    _InputCard(
                                      formKey: _formKey,
                                      emailController: _email,
                                      passwordController: _password,
                                      accentColor: _accent,
                                      titleColor: _titleColor,
                                      subtitleColor: _subtitleColor,
                                      isBusy: isBusy,
                                      onSubmit: _submit,
                                      onGuestSignIn: () => ref
                                          .read(authControllerProvider.notifier)
                                          .signInAsGuest(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 720,
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 8,
            child: _Cloud(size: 48),
          ),
          Positioned(
            top: 56,
            right: 16,
            child: _Cloud(size: 36),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            child: _PottedPlant(
              potColor: const Color(0xFFE8C4A0),
              leafColor: const Color(0xFF7FC8A0),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 4,
            child: _PottedPlant(
              potColor: const Color(0xFFF0A0B0),
              leafColor: const Color(0xFFFFB6C8),
              flower: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.55,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _PottedPlant extends StatelessWidget {
  const _PottedPlant({
    required this.potColor,
    required this.leafColor,
    this.flower = false,
  });

  final Color potColor;
  final Color leafColor;
  final bool flower;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (flower)
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: leafColor,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(Icons.eco, color: leafColor, size: 28),
          const SizedBox(height: 2),
          Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: potColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
                bottom: Radius.circular(10),
              ),
              boxShadow: [
                BoxShadow(
                  color: potColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl + 8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    required this.titleColor,
    required this.subtitleColor,
  });

  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SparkleLine(isLeft: true, color: titleColor),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: context.textStyles.headlineMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SparkleLine(isLeft: false, color: titleColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Login to continue your journey',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkleLine extends StatelessWidget {
  const _SparkleLine({required this.isLeft, required this.color});

  final bool isLeft;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFBBF24);
    return SizedBox(
      width: 22,
      height: 24,
      child: Stack(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          // Top ray
          Transform.rotate(
            angle: isLeft ? -0.5 : 0.5,
            child: Container(
              width: 10,
              height: 3,
              decoration: BoxDecoration(
                color: goldColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Middle ray
          Align(
            alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 13,
              height: 3,
              decoration: BoxDecoration(
                color: goldColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Bottom ray
          Transform.rotate(
            angle: isLeft ? 0.5 : -0.5,
            child: Container(
              width: 10,
              height: 3,
              decoration: BoxDecoration(
                color: goldColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.accentColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.isBusy,
    required this.onSubmit,
    required this.onGuestSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Color accentColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool isBusy;
  final VoidCallback onSubmit;
  final VoidCallback onGuestSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                AuthTextField(
                  hint: 'Email or Username',
                  controller: emailController,
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  accentColor: accentColor,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  hint: 'Password',
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v, 'Password'),
                  onSubmitted: (_) => onSubmit(),
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.pushNamed(AppRoutes.forgotPasswordName),
              style: TextButton.styleFrom(
                foregroundColor: titleColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LoginButton(
            isBusy: isBusy,
            accentColor: accentColor,
            onPressed: onSubmit,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: subtitleColor.withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'or continue with',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: subtitleColor.withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const LoginSocialButtons(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: context.textStyles.bodyMedium?.copyWith(
                  color: subtitleColor,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(AppRoutes.registerName),
                child: Text(
                  'Sign Up',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              TextButton(
                onPressed: isBusy
                    ? null
                    : () => context.pushNamed(AppRoutes.phoneAuthName),
                style: TextButton.styleFrom(
                  foregroundColor: subtitleColor,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Sign in with phone',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Text(
                '•',
                style: TextStyle(
                  color: subtitleColor.withValues(alpha: 0.4),
                ),
              ),
              TextButton(
                onPressed: isBusy ? null : onGuestSignIn,
                style: TextButton.styleFrom(
                  foregroundColor: titleColor,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Continue as guest',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isBusy,
    required this.accentColor,
    required this.onPressed,
  });

  final bool isBusy;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor,
                Color.lerp(accentColor, const Color(0xFF5D3A48), 0.2)!,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
