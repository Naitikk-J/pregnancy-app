import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cute_doodles.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/login_social_buttons.dart';

/// Email/password registration screen with a 3D claymorphic layout.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _accent = Color(0xFFC48B9F);
  static const _titleColor = Color(0xFF5D3A48);
  static const _subtitleColor = Color(0xFF8C6875);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.mother;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).register(
          email: _email.text,
          password: _password.text,
          name: _name.text,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isBusy = authState.isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final msg = next.error is Failure
            ? (next.error as Failure).message
            : 'Registration failed.';
        context.showSnack(msg, isError: true);
      }
    });

    final roles = UserRole.values
        .where((r) => r != UserRole.admin && r != UserRole.doctor)
        .toList();

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
                              const SizedBox(height: AppSpacing.md),
                              _PhoneFrame(
                                child: Column(
                                  children: [
                                    const SizedBox(height: AppSpacing.xl),
                                    _RegisterHeader(
                                      titleColor: _titleColor,
                                      subtitleColor: _subtitleColor,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xl,
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppTextField(
                                              label: 'Full Name',
                                              controller: _name,
                                              prefixIcon: Icons.person_rounded,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: (v) =>
                                                  Validators.required(
                                                      v, 'Name'),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.md),
                                            AppTextField(
                                              label: 'Email address',
                                              controller: _email,
                                              prefixIcon: Icons.email_rounded,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: Validators.email,
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.md),
                                            AppTextField(
                                              label: 'Password',
                                              controller: _password,
                                              prefixIcon: Icons.lock_rounded,
                                              obscure: true,
                                              textInputAction:
                                                  TextInputAction.done,
                                              validator: Validators.password,
                                              onSubmitted: (_) => _submit(),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            Row(
                                              children: [
                                                const Text(
                                                  'I am a…',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: _titleColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const CuteFlower(size: 14),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                            Wrap(
                                              spacing: AppSpacing.xs,
                                              children: [
                                                for (final role in roles)
                                                  ChoiceChip(
                                                    label: Text(
                                                      role == UserRole.mother
                                                          ? 'Mother 🌸'
                                                          : role ==
                                                                  UserRole.husband
                                                              ? 'Partner 👨‍👩‍👧'
                                                              : 'Family 💖',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            _role == role
                                                                ? FontWeight
                                                                    .w700
                                                                : FontWeight
                                                                    .w500,
                                                        color: _role == role
                                                            ? Colors.white
                                                            : _titleColor,
                                                      ),
                                                    ),
                                                    selected: _role == role,
                                                    selectedColor: _accent,
                                                    backgroundColor:
                                                        Colors.white,
                                                    side: BorderSide(
                                                      color: _role == role
                                                          ? Colors.transparent
                                                          : const Color(
                                                                  0xFFFFDADA)
                                                              .withValues(
                                                                  alpha: 0.8),
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    onSelected: (_) => setState(
                                                        () => _role = role),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xl),
                                            AppButton(
                                              label: 'Create Account',
                                              isLoading: isBusy,
                                              onPressed: _submit,
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            _DividerRow(
                                                color: _subtitleColor),
                                            const SizedBox(
                                                height: AppSpacing.md),
                                            const LoginSocialButtons(),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'Already have an account? ',
                                                  style: TextStyle(
                                                    color: _subtitleColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => context.pop(),
                                                  child: const Text(
                                                    'Sign in',
                                                    style: TextStyle(
                                                      color: _accent,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xl),
                                          ],
                                        ),
                                      ),
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
            top: 16,
            left: 8,
            child: _Cloud(size: 48),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: _Cloud(size: 36),
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
        border: Border.all(
          color: const Color(0xFFFFDADA),
          width: 1.5,
        ),
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

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFDADA), Color(0xFFE899AA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC48B9F).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CuteSparkle(size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Join the Journey',
                textAlign: TextAlign.center,
                style: context.textStyles.headlineMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const CuteHeart(size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Create an account for personalized tracking',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: color.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: color.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
