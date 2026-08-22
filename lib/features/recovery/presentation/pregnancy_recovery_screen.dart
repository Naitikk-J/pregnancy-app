import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/pregnancy_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../domain/pregnancy_access.dart';
import 'recovery_providers.dart';

/// Recovers an account whose active pregnancy became inaccessible — most often
/// after signing in with a different Google account, which leaves
/// `activePregnancyId` pointing at a pregnancy this account neither owns nor is
/// a member of, so every tracker read is denied.
///
/// The fix creates a fresh pregnancy owned by the current account (preserving
/// the profile) or lets the user switch back to the original account.
class PregnancyRecoveryScreen extends ConsumerStatefulWidget {
  const PregnancyRecoveryScreen({super.key});

  @override
  ConsumerState<PregnancyRecoveryScreen> createState() =>
      _PregnancyRecoveryScreenState();
}

class _PregnancyRecoveryScreenState
    extends ConsumerState<PregnancyRecoveryScreen> {
  DateTime? _lmp;
  RiskCategory _risk = RiskCategory.low;

  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp ?? now.subtract(const Duration(days: 56)),
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      helpText: 'Select your last menstrual period',
    );
    if (picked != null) setState(() => _lmp = picked);
  }

  Future<void> _createFresh() async {
    final lmp = _lmp;
    if (lmp == null) {
      context.showSnack('Please select your last period date.', isError: true);
      return;
    }
    final ok = await ref.read(recoveryControllerProvider.notifier).createFreshPregnancy(
          lmp: lmp,
          risk: _risk,
        );
    if (!mounted) return;
    if (ok) {
      context.showSnack('Your pregnancy is set up on this account.');
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.homeName);
      }
    } else {
      context.showSnack('Could not set up your pregnancy. Please try again.',
          isError: true);
    }
  }

  Future<void> _switchAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign in with another account?'),
        content: const Text(
            'You will be signed out so you can sign in with the account that '
            'originally set up this pregnancy.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(pregnancyAccessProvider);
    final user = ref.watch(currentUserProvider);
    final saving = ref.watch(recoveryControllerProvider).isLoading;
    final df = DateFormat('EEE, d MMM yyyy');

    final account = user?.email ?? user?.phone ?? user?.displayName ?? '';

    final lmp = _lmp;
    final week = lmp == null ? null : PregnancyCalculator.currentWeek(lmp);
    final due = lmp == null ? null : PregnancyCalculator.dueDateFromLmp(lmp);

    return Scaffold(
      appBar: AppBar(title: const Text('Fix data access')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          AppCard(
            color: context.colors.errorContainer,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: context.colors.onErrorContainer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _explain(access),
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.colors.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
          if (account.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Signed in as $account',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
          const SizedBox(height: AppSpacing.xl),

          Text('Option 1 — set up on this account',
              style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a fresh pregnancy record owned by this account. Your profile '
            'is kept; enter your last period so we can set your week and dates.',
            style: context.textStyles.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Last period (LMP)', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: _pickLmp,
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: context.colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    lmp == null ? 'Tap to select' : df.format(lmp),
                    style: context.textStyles.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          if (lmp != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: context.colors.secondaryContainer,
              child: Row(
                children: [
                  Icon(Icons.pregnant_woman,
                      color: context.colors.onSecondaryContainer),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'You are in week $week.\n'
                      'Estimated due date: ${df.format(due!)}',
                      style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          Text('Risk category', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final r in RiskCategory.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _risk == r,
                  onSelected: (_) => setState(() => _risk = r),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: 'Set up my pregnancy',
            icon: Icons.check,
            isLoading: saving,
            onPressed: saving ? () {} : _createFresh,
          ),

          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          Text('Option 2 — use another account',
              style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If this pregnancy was set up under a different account, sign out and '
            'sign back in with that account to see all your existing data.',
            style: context.textStyles.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Sign in with another account',
            icon: Icons.switch_account_outlined,
            variant: AppButtonVariant.outlined,
            onPressed: saving ? () {} : _switchAccount,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _explain(PregnancyAccess access) => switch (access) {
        PregnancyAccess.foreign =>
          "Your trackers can't load because this pregnancy was set up on a "
              'different account. Set it up on this account, or switch accounts.',
        PregnancyAccess.missing =>
          "We couldn't find your pregnancy record, so your trackers can't load. "
              'Set it up again below to continue.',
        PregnancyAccess.none =>
          "This account doesn't have a pregnancy yet. Set one up to start "
              'tracking.',
        _ =>
          'Set up your pregnancy on this account to make sure your trackers '
              'load correctly.',
      };
}
