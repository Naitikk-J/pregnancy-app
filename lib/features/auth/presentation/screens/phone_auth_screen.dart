import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/phone_auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Two-step phone sign-in: enter number → enter the SMS code.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Fresh flow each time the screen opens.
    Future.microtask(
      () => ref.read(phoneAuthControllerProvider.notifier).reset(),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !_phoneFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(phoneAuthControllerProvider.notifier)
        .sendCode(_phone.text, resend: resend);
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    await ref.read(phoneAuthControllerProvider.notifier).confirmCode(_code.text);
    // On success the router redirects via authUserProvider.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneAuthControllerProvider);

    ref.listen(phoneAuthControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showSnack(next.errorMessage!, isError: true);
      }
    });

    final isCodeStep = state.step == PhoneStep.enterCode;

    return AuthScaffold(
      title: isCodeStep ? 'Enter the code' : 'Sign in with phone',
      subtitle: isCodeStep
          ? 'We sent a 6-digit code to ${state.phoneNumber}.'
          : 'We will text you a one-time verification code.',
      children: [
        if (!isCodeStep) ...[
          Form(
            key: _phoneFormKey,
            child: AppTextField(
              label: 'Phone number',
              hint: '+91 98765 43210',
              controller: _phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
              onSubmitted: (_) => _sendCode(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Include your country code (e.g. +91 for India).',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Send code',
            isLoading: state.isBusy,
            onPressed: _sendCode,
          ),
        ] else ...[
          AppTextField(
            label: 'Verification code',
            controller: _code,
            prefixIcon: Icons.sms_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Verify & continue',
            isLoading: state.isBusy,
            onPressed: _confirm,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Resend code',
            variant: AppButtonVariant.text,
            onPressed: state.isBusy ? null : () => _sendCode(resend: true),
          ),
        ],
      ],
    );
  }
}
