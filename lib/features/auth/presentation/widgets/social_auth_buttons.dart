import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';

/// The "or continue with" block: Google, Apple (Apple platforms only) and Guest.
class SocialAuthButtons extends ConsumerWidget {
  const SocialAuthButtons({this.onDone, super.key});

  /// Called after a successful social/guest sign-in (router handles redirect,
  /// but callers may also close a sheet, etc.).
  final VoidCallback? onDone;

  bool get _showApple =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider.notifier);
    final isBusy = ref.watch(authControllerProvider).isLoading;

    Future<void> run(Future<bool> Function() action) async {
      final ok = await action();
      if (ok) onDone?.call();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: context.colors.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('or continue with',
                  style: context.textStyles.bodySmall),
            ),
            Expanded(child: Divider(color: context.colors.outlineVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          variant: AppButtonVariant.outlined,
          onPressed: isBusy ? null : () => run(controller.signInWithGoogle),
        ),
        if (_showApple) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            variant: AppButtonVariant.outlined,
            onPressed: isBusy ? null : () => run(controller.signInWithApple),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Continue as guest',
          icon: Icons.person_outline,
          variant: AppButtonVariant.text,
          onPressed: isBusy ? null : () => run(controller.signInAsGuest),
        ),
      ],
    );
  }
}
