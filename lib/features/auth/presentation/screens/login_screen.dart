import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_buttons.dart';

/// Email/password sign-in with links to register, phone auth and reset.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    // On success the router redirects automatically via authUserProvider.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isBusy = authState.isLoading;

    // Surface auth errors as a snackbar.
    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final msg = next.error is Failure
            ? (next.error as Failure).message
            : 'Sign-in failed.';
        context.showSnack(msg, isError: true);
      }
    });

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue your pregnancy journey.',
      showBack: false,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Email',
                controller: _email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                controller: _password,
                prefixIcon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.required(v, 'Password'),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.pushNamed(AppRoutes.forgotPasswordName),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Sign in',
          isLoading: isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Sign in with phone',
          icon: Icons.phone_outlined,
          variant: AppButtonVariant.tonal,
          onPressed: isBusy
              ? null
              : () => context.pushNamed(AppRoutes.phoneAuthName),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SocialAuthButtons(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?",
                style: context.textStyles.bodyMedium),
            TextButton(
              onPressed: () => context.pushNamed(AppRoutes.registerName),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ],
    );
  }
}
