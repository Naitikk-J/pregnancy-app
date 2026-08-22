import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/diagnostics.dart' as diag;
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/presentation/controllers/auth_providers.dart';

/// Branded loading screen shown while auth state resolves. Navigation away from
/// here is handled entirely by the router's redirect (which reacts to the auth
/// stream), so this screen does no navigation itself.
///
/// TEMP DIAGNOSTIC: shows the auth-stream error (if any) and a build tag so a
/// stuck splash on a real device reveals *why* instead of spinning forever.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    // Prefer the real Firebase-init cause over the downstream [core/no-app].
    final errText = diag.firebaseInitError ??
        (auth.hasError ? '${auth.error}' : null);
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 112,
                width: 112,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pregnant_woman,
                  size: 64,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(AppConstants.appName,
                  style: context.textStyles.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your journey, cared for',
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (errText != null) ...[
                Icon(Icons.error_outline, color: context.colors.error),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Startup error:\n${errText.length > 500 ? errText.substring(0, 500) : errText}',
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.error),
                ),
              ] else
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'build: ui-v15',
                style: context.textStyles.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
