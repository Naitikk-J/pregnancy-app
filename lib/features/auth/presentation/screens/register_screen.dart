import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_buttons.dart';

/// Email/password registration with role selection.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
    final isBusy = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final msg = next.error is Failure
            ? (next.error as Failure).message
            : 'Registration failed.';
        context.showSnack(msg, isError: true);
      }
    });

    // Admin and doctor cannot self-register — doctors are provisioned and
    // verified out-of-band. Offered roles are mother/partner/family only.
    final roles = UserRole.values
        .where((r) => r != UserRole.admin && r != UserRole.doctor)
        .toList();

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'A few details and you are ready to begin.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Full name',
                controller: _name,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
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
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('I am a…', style: context.textStyles.titleSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final role in roles)
              ChoiceChip(
                label: Text(role.label),
                selected: _role == role,
                onSelected: (_) => setState(() => _role = role),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Create account',
          isLoading: isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        const SocialAuthButtons(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account?',
                style: context.textStyles.bodyMedium),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
