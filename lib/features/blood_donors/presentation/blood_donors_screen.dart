import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_share.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/blood_donor.dart';
import 'blood_donor_providers.dart';

/// A small directory of potential blood donors with their blood groups. Donors
/// whose blood is compatible with the mother's group are highlighted and sorted
/// first, so a match can be reached quickly if a transfusion is ever needed.
/// This is intentionally separate from the SOS / emergency contacts.
class BloodDonorsScreen extends ConsumerWidget {
  const BloodDonorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorsAsync = ref.watch(bloodDonorsProvider);
    final motherGroup = ref.watch(motherBloodGroupProvider);
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    final isOwner = pregnancy != null && pregnancy.ownerUserId == user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Blood donors')),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Add donor'),
            )
          : null,
      body: donorsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load donors',
          message: '$e',
        ),
        data: (donors) {
          final compatible = compatibleDonorGroups(motherGroup);
          final sorted = [...donors]..sort((a, b) {
              final ca = compatible.contains(a.bloodGroup.toUpperCase());
              final cb = compatible.contains(b.bloodGroup.toUpperCase());
              if (ca != cb) return ca ? -1 : 1;
              return a.name.compareTo(b.name);
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            children: [
              AppCard(
                color: context.colors.primaryContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bloodtype,
                        color: context.colors.onPrimaryContainer),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        motherGroup == null || motherGroup.isEmpty
                            ? 'Add your blood group in your profile to see which '
                                'donors are a match for you.'
                            : 'Your blood group is $motherGroup. Compatible donors '
                                'are highlighted and listed first.',
                        style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (sorted.isEmpty)
                EmptyState(
                  icon: Icons.bloodtype_outlined,
                  title: 'No donors saved yet',
                  message: isOwner
                      ? 'Add family or friends with their blood group so a match '
                          'is one tap away in an emergency.'
                      : 'No blood donors have been added yet.',
                  actionLabel: isOwner ? 'Add donor' : null,
                  onAction: isOwner ? () => _edit(context, ref, null) : null,
                )
              else
                for (final d in sorted)
                  _DonorTile(
                    donor: d,
                    isMatch: compatible.contains(d.bloodGroup.toUpperCase()),
                    canEdit: isOwner,
                    onCall: () => _dial(context, d.phone),
                    onWhatsApp: () => _whatsApp(context, d),
                    onEdit: () => _edit(context, ref, d),
                    onDelete: () =>
                        ref.read(bloodDonorsCrudProvider)?.delete(d.id),
                  ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Blood group compatibility here is a general guide only. Actual '
                'transfusion requires cross-matching by a hospital or blood bank.',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _dial(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri) && context.mounted) {
      context.showSnack('Could not start a call.', isError: true);
    }
  }

  Future<void> _whatsApp(BuildContext context, BloodDonor d) async {
    final text =
        'Hi ${d.name}, this is regarding a possible blood donation (${d.bloodGroup}). '
        'Could you help if needed? (Sent via Pregnancy Companion)';
    if (!await MessageShare.whatsApp(text, phone: d.phone) && context.mounted) {
      context.showSnack('Couldn’t open WhatsApp. Is it installed?',
          isError: true);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BloodDonor? existing,
  ) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final relCtrl = TextEditingController(text: existing?.relation ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var group = existing?.bloodGroup ?? '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom +
              MediaQuery.viewPaddingOf(ctx).bottom +
              AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Add donor' : 'Edit donor',
                    style: ctx.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: 'Name', controller: nameCtrl),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Phone number',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Blood group', style: ctx.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final bg in kBloodGroups)
                      ChoiceChip(
                        label: Text(bg),
                        selected: group == bg,
                        onSelected: (_) => setState(() => group = bg),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                    label: 'Relationship (optional)', controller: relCtrl),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                    label: 'Note (optional)', controller: noteCtrl),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save',
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty ||
                        group.isEmpty) {
                      ctx.showSnack('Enter a name, phone and blood group.',
                          isError: true);
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      await ref.read(bloodDonorsCrudProvider)?.upsert(
            BloodDonor(
              id: existing?.id ?? const Uuid().v4(),
              name: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              bloodGroup: group,
              relation: relCtrl.text.trim(),
              note: noteCtrl.text.trim(),
              createdAt: existing?.createdAt,
            ),
          );
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
    relCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _DonorTile extends StatelessWidget {
  const _DonorTile({
    required this.donor,
    required this.isMatch,
    required this.canEdit,
    required this.onCall,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onDelete,
  });

  final BloodDonor donor;
  final bool isMatch;
  final bool canEdit;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: isMatch ? context.colors.tertiaryContainer : null,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colors.error.withValues(alpha: 0.15),
              child: Text(
                donor.bloodGroup,
                style: context.textStyles.labelMedium
                    ?.copyWith(color: context.colors.error),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(donor.name,
                            style: context.textStyles.titleSmall),
                      ),
                      if (isMatch) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.tertiary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill),
                          ),
                          child: Text('Match',
                              style: context.textStyles.labelSmall?.copyWith(
                                  color: context.colors.tertiary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    [
                      if (donor.relation.isNotEmpty) donor.relation,
                      donor.phone,
                      if (donor.note.isNotEmpty) donor.note,
                    ].join(' · '),
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'WhatsApp',
              icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
              onPressed: onWhatsApp,
            ),
            IconButton.filledTonal(
              tooltip: 'Call',
              icon: const Icon(Icons.call),
              onPressed: onCall,
            ),
            if (canEdit)
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
