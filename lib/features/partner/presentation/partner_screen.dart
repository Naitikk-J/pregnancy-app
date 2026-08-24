import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/models/pregnancy.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import 'partner_providers.dart';

/// Partner & family mode: share the pregnancy's invite code so a partner or
/// family member can follow along, view members, or join an existing pregnancy.
class PartnerScreen extends ConsumerWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final isOwner = pregnancy != null && pregnancy.ownerUserId == user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner & family')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (pregnancy != null) ...[
            AppCard(
              color: context.colors.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite code',
                      style: context.textStyles.titleMedium?.copyWith(
                          color: context.colors.onSecondaryContainer)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Share this code with your partner or family. They install '
                    'the app, sign in, and tap "Join a pregnancy".',
                    style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSecondaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          pregnancy.id,
                          style: context.textStyles.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              color: context.colors.onSecondaryContainer),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: context.colors.onSecondaryContainer,
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: pregnancy.id));
                          if (context.mounted) {
                            context.showSnack('Invite code copied.');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Members'),
            _MemberTile(
              label: 'Owner',
              roleLabel: 'Mother',
              isYou: pregnancy.ownerUserId == user?.uid,
            ),
            for (final entry in pregnancy.members.entries)
              if (entry.key != pregnancy.ownerUserId)
                _MemberTile(
                  label: 'Member',
                  roleLabel: _roleLabel(entry.value),
                  isYou: entry.key == user?.uid,
                  onRemove: isOwner
                      ? () => ref.read(partnerRepositoryProvider).removeMember(
                            pregnancyId: pregnancy.id,
                            uid: entry.key,
                          )
                      : null,
                ),
            const SizedBox(height: AppSpacing.lg),
            if (isOwner) _SharingSection(pregnancy: pregnancy),
          ],
          const SectionHeader(title: 'Join a pregnancy'),
          Text(
            'Have an invite code from someone? Join to follow their pregnancy.',
            style: context.textStyles.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Join a pregnancy',
            icon: Icons.group_add_outlined,
            variant: AppButtonVariant.tonal,
            onPressed: () => _join(context, ref),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _roleLabel(Object? memberData) {
    if (memberData is Map && memberData['role'] is String) {
      return UserRole.fromName(memberData['role'] as String).label;
    }
    return 'Member';
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    var role = UserRole.husband;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: ctx.sheetPadding(),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join a pregnancy', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Invite code',
                controller: code,
                prefixIcon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('I am the', style: ctx.textStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final r in [UserRole.husband, UserRole.family])
                    ChoiceChip(
                      label: Text(r.label),
                      selected: role == r,
                      onSelected: (_) => setState(() => role = r),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Join', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      final uid = ref.read(currentUserProvider)?.uid;
      final text = code.text.trim();
      if (uid != null && text.isNotEmpty) {
        try {
          await ref
              .read(partnerRepositoryProvider)
              .join(code: text, uid: uid, role: role);
          if (context.mounted) context.showSnack('Joined successfully.');
        } catch (e) {
          if (context.mounted) {
            context.showSnack('Could not join: that code did not match.',
                isError: true);
          }
        }
      }
    }
    code.dispose();
  }
}

/// Owner-only controls for what members (partner/family) can view. Emergency
/// contacts and the pregnancy overview are always visible; these gate the
/// detailed trackers. Privacy-first: only the overview categories default on.
class _SharingSection extends ConsumerWidget {
  const _SharingSection({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'What your family can see'),
        Text(
          'Choose what partners and family can view. You always see everything; '
          'your private journal is never shared.',
          style: context.textStyles.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final cat in Pregnancy.shareCategories)
                SwitchListTile(
                  title: Text(Pregnancy.labelForCategory(cat)),
                  value: pregnancy.isShared(cat),
                  onChanged: (v) {
                    final sharing = {...pregnancy.sharing, cat: v};
                    ref
                        .read(profileRepositoryProvider)
                        .updatePregnancy(pregnancy.copyWith(sharing: sharing));
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.label,
    required this.roleLabel,
    required this.isYou,
    this.onRemove,
  });

  final String label;
  final String roleLabel;
  final bool isYou;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        child: Icon(Icons.person, color: context.colors.onPrimaryContainer),
      ),
      title: Text(isYou ? '$roleLabel (you)' : roleLabel),
      subtitle: Text(label),
      trailing: onRemove == null
          ? null
          : IconButton(
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: onRemove,
            ),
    );
  }
}
