import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import 'premium_providers.dart';

class _Benefit {
  const _Benefit(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

const _benefits = [
  _Benefit(Icons.auto_awesome, 'Unlimited AI chats',
      'Ask Mira as much as you like, any time.'),
  _Benefit(Icons.insights, 'Advanced health insights',
      'Trends and gentle flags across your BP, sugar, weight & sleep.'),
  _Benefit(Icons.block, 'Ad-free experience', 'A calm, distraction-free app.'),
  _Benefit(Icons.notifications_active_outlined, 'Priority reminders',
      'Smarter medicine, appointment & hydration nudges.'),
  _Benefit(Icons.menu_book_outlined, 'Expert content',
      'Exclusive week-by-week guidance and articles.'),
  _Benefit(Icons.cloud_done_outlined, 'Cloud backup',
      'All your records safely backed up and restorable.'),
];

/// The Premium paywall / management screen. Sells the upgrade, and (in this
/// build) toggles the entitlement locally — real billing lands later.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;

  Future<void> _set(bool value) async {
    setState(() => _busy = true);
    try {
      await ref.read(premiumControllerProvider).setPremium(value);
      if (mounted) {
        context.showSnack(value
            ? 'Welcome to Premium ✨'
            : 'Premium cancelled.');
      }
    } catch (_) {
      if (mounted) context.showSnack('Something went wrong.', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Hero(isPremium: isPremium),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'What you get'),
          for (final b in _benefits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(b.icon, color: context.colors.primary),
              title: Text(b.title, style: context.textStyles.titleSmall),
              subtitle: Text(b.subtitle),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (!isPremium) ...[
            const SectionHeader(title: 'Choose a plan'),
            Row(
              children: const [
                Expanded(
                    child: _PlanCard(
                        name: 'Monthly', price: '₹299', per: 'per month')),
                SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _PlanCard(
                        name: 'Yearly',
                        price: '₹1,999',
                        per: 'per year',
                        badge: 'Save 44%')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Go Premium',
              icon: Icons.workspace_premium,
              isLoading: _busy,
              onPressed: () => _set(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Demo build: this unlocks Premium instantly without payment. '
              'Real in-app billing is added before launch.',
              textAlign: TextAlign.center,
              style: context.textStyles.labelSmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ] else ...[
            AppButton(
              label: 'Cancel Premium',
              variant: AppButtonVariant.outlined,
              isLoading: _busy,
              onPressed: () => _set(false),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium,
              size: 48, color: context.colors.onPrimary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isPremium ? 'You’re Premium ✨' : 'Pregnancy Companion Premium',
            textAlign: TextAlign.center,
            style: context.textStyles.headlineSmall
                ?.copyWith(color: context.colors.onPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isPremium
                ? 'Thank you for supporting the app.'
                : 'Unlock the full experience for you and your baby.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onPrimary.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.per,
    this.badge,
  });
  final String name;
  final String price;
  final String per;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: context.textStyles.titleSmall),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.tertiaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(badge!,
                      style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onTertiaryContainer)),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(price, style: context.textStyles.headlineSmall),
          Text(per,
              style: context.textStyles.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
