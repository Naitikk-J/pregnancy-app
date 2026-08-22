import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final msg = next.error is Failure
            ? (next.error as Failure).message
            : 'Could not send reset email.';
        context.showSnack(msg, isError: true);
      }
    });

    return AuthScaffold(
      title: 'Reset password',
      subtitle: _sent
          ? null
          : 'Enter your email and we will send you a reset link.',
      children: [
        if (_sent)
          EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'Check your inbox',
            message:
                'We sent a password reset link to ${_email.text.trim()}.',
            actionLabel: 'Back to sign in',
            onAction: () => context.pop(),
          )
        else ...[
          Form(
            key: _formKey,
            child: AppTextField(
              label: 'Email',
              controller: _email,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Send reset link',
            isLoading: isBusy,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}
