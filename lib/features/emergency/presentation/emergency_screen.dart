import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_share.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/emergency_contact.dart';
import 'emergency_providers.dart';

/// Emergency / SOS screen: a one-tap SOS that alerts your emergency contacts and
/// partner, quick calls to services, your saved contacts, and your care team.
///
/// Default service numbers use India's (112 all-emergencies, 108 ambulance).
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  static const String _emergencyNumber = '112';
  static const String _ambulanceNumber = '108';

  Future<void> _dial(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri) && context.mounted) {
      context.showSnack('Could not start a call to $number.', isError: true);
    }
  }

  Future<void> _sms(BuildContext context, String number, String body) async {
    final uri = Uri(scheme: 'sms', path: number, queryParameters: {'body': body});
    if (!await launchUrl(uri) && context.mounted) {
      context.showSnack('Could not open messaging.', isError: true);
    }
  }

  /// The SOS text sent to family over WhatsApp / SMS.
  static String _alertText(String name) =>
      '🚨 SOS from $name. I may need urgent help with my pregnancy — please '
      'call me or come as soon as you can. (Sent via Pregnancy Companion)';

  Future<void> _whatsApp(BuildContext context, String phone, String body) async {
    if (!await MessageShare.whatsApp(body, phone: phone) && context.mounted) {
      context.showSnack('Couldn’t open WhatsApp. Is it installed?',
          isError: true);
    }
  }

  /// Alerts the primary emergency contact on WhatsApp (or opens WhatsApp's
  /// contact picker if none is set), with a pre-filled SOS message.
  Future<void> _alertFamilyWhatsApp(BuildContext context, WidgetRef ref) async {
    final primary = ref.read(primaryContactProvider);
    final name = ref.read(userProfileProvider).valueOrNull?.name ??
        ref.read(currentUserProvider)?.displayName ??
        'I';
    if (!await MessageShare.whatsApp(_alertText(name), phone: primary?.phone) &&
        context.mounted) {
      context.showSnack('Couldn’t open WhatsApp. Is it installed?',
          isError: true);
    }
  }

  Future<void> _openNearestHospital(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=hospitals+near+me',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      context.showSnack('Could not open maps.', isError: true);
    }
  }

  Future<void> _triggerSos(BuildContext context, WidgetRef ref) async {
    final contacts =
        ref.read(emergencyContactsProvider).valueOrNull ?? const [];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send SOS?'),
        content: Text(contacts.isEmpty
            ? 'This alerts your family in the app and opens WhatsApp so you can '
                'send for help. Add emergency contacts to alert them all at once.'
            : 'This alerts your family in the app, then lets you send an SOS to '
                'all ${contacts.length} of your emergency contacts on WhatsApp.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.colors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 1) Record an in-app alert so partner/family see it.
    final col = ref.read(sosCollectionProvider);
    final user = ref.read(currentUserProvider);
    final name = ref.read(userProfileProvider).valueOrNull?.name ??
        user?.displayName ??
        'Someone';
    if (col != null) {
      final id = const Uuid().v4();
      try {
        await col.doc(id).set({
          'id': id,
          'createdBy': user?.uid,
          'createdByName': name,
          'status': 'active',
          'message': 'SOS: $name needs help.',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {/* offline queue will retry */}
    }

    // 2) Send the SOS to every contact on WhatsApp (or a picker if none).
    if (!context.mounted) return;
    if (contacts.isEmpty) {
      await _whatsApp(context, '', _alertText(name));
    } else {
      await _sendSosToAll(context, contacts, _alertText(name));
    }
  }

  /// WhatsApp has no multi-recipient deep link, so we present every contact and
  /// let the user fire a pre-filled SOS to each with a single tap. Contacts
  /// already messaged are ticked so it's easy to reach everyone.
  Future<void> _sendSosToAll(
    BuildContext context,
    List<EmergencyContact> contacts,
    String text,
  ) async {
    final sent = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sos, color: ctx.colors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Send SOS on WhatsApp',
                        style: ctx.textStyles.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Tap each person to send your SOS message.',
                    style: ctx.textStyles.bodySmall
                        ?.copyWith(color: ctx.colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in contacts)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: sent.contains(c.id)
                                ? const Color(0xFF25D366)
                                : ctx.colors.primaryContainer,
                            child: Icon(
                              sent.contains(c.id) ? Icons.check : Icons.person,
                              color: sent.contains(c.id)
                                  ? Colors.white
                                  : ctx.colors.onPrimaryContainer,
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            [if (c.relation.isNotEmpty) c.relation, c.phone]
                                .join(' · '),
                          ),
                          trailing: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366)),
                            icon: const Icon(Icons.chat, size: 18),
                            label: Text(sent.contains(c.id) ? 'Again' : 'Send'),
                            onPressed: () async {
                              await MessageShare.whatsApp(text, phone: c.phone);
                              setState(() => sent.add(c.id));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Done',
                  variant: AppButtonVariant.tonal,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    final isOwner = pregnancy != null && pregnancy.ownerUserId == user?.uid;
    final contacts = ref.watch(emergencyContactsProvider).valueOrNull ?? const [];
    final name =
        ref.watch(userProfileProvider).valueOrNull?.name ?? 'I';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: context.colors.errorContainer,
        foregroundColor: context.colors.onErrorContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- SOS ---
          _SosButton(onPressed: () => _triggerSos(context, ref)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Alert family on WhatsApp',
            icon: Icons.chat,
            variant: AppButtonVariant.tonal,
            onPressed: () => _alertFamilyWhatsApp(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: 'Call ambulance ($_ambulanceNumber)',
            icon: Icons.local_hospital,
            onPressed: () => _dial(context, _ambulanceNumber),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Call emergency ($_emergencyNumber)',
            icon: Icons.call,
            variant: AppButtonVariant.tonal,
            onPressed: () => _dial(context, _emergencyNumber),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Find nearest hospital',
            icon: Icons.map_outlined,
            variant: AppButtonVariant.outlined,
            onPressed: () => _openNearestHospital(context),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Emergency contacts ---
          SectionHeader(
            title: 'Emergency contacts',
            actionLabel: isOwner ? 'Add' : null,
            onAction: isOwner ? () => _editContact(context, ref, null) : null,
          ),
          if (contacts.isEmpty)
            Text(
              isOwner
                  ? 'Add your partner, family or doctor for one-tap SOS.'
                  : 'No emergency contacts have been added yet.',
              style: context.textStyles.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            )
          else
            for (final c in contacts)
              _ContactTile(
                contact: c,
                canEdit: isOwner,
                onCall: () => _dial(context, c.phone),
                onText: () => _sms(context, c.phone,
                    'SOS: $name needs help. Please call me. (Pregnancy Companion)'),
                onWhatsApp: () =>
                    _whatsApp(context, c.phone, _alertText(name)),
                onEdit: () => _editContact(context, ref, c),
                onDelete: () => ref
                    .read(emergencyContactsCrudProvider)
                    ?.delete(c.id),
              ),
          const SizedBox(height: AppSpacing.xl),

          _CareTeamCard(
            doctorName: pregnancy?.doctorName,
            hospital: pregnancy?.hospital,
            canEdit: isOwner,
            onEdit: () => context.pushNamed(AppRoutes.editPregnancyName),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'If you have severe bleeding, strong abdominal pain, reduced baby '
            'movement, a bad headache with blurred vision, or your waters break '
            'early — contact your doctor or emergency services immediately. '
            'This screen does not replace emergency services.',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _editContact(
    BuildContext context,
    WidgetRef ref,
    EmergencyContact? existing,
  ) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final relCtrl = TextEditingController(text: existing?.relation ?? '');
    var isPrimary = existing?.isPrimary ?? false;

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
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Add contact' : 'Edit contact',
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
              AppTextField(
                  label: 'Relationship (e.g. Husband)', controller: relCtrl),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Call this contact first for SOS'),
                value: isPrimary,
                onChanged: (v) => setState(() => isPrimary = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Save',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty) {
                    ctx.showSnack('Enter a name and phone number.',
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
    );

    if (saved == true) {
      await ref.read(emergencyContactsCrudProvider)?.upsert(
            EmergencyContact(
              id: existing?.id ?? const Uuid().v4(),
              name: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              relation: relCtrl.text.trim(),
              isPrimary: isPrimary,
              createdAt: existing?.createdAt,
            ),
          );
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
    relCtrl.dispose();
  }
}

/// Always-visible care-team card. Shows the saved doctor & hospital, or an
/// invitation to add them; the owner can edit either way (fixes the previously
/// "disabled" care team that only appeared once details existed).
class _CareTeamCard extends StatelessWidget {
  const _CareTeamCard({
    required this.doctorName,
    required this.hospital,
    required this.canEdit,
    required this.onEdit,
  });

  final String? doctorName;
  final String? hospital;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasAny = (doctorName?.isNotEmpty ?? false) ||
        (hospital?.isNotEmpty ?? false);
    return AppCard(
      onTap: canEdit ? onEdit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your care team',
                    style: context.textStyles.titleMedium),
              ),
              if (canEdit)
                Icon(hasAny ? Icons.edit_outlined : Icons.add,
                    size: 20, color: context.colors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!hasAny)
            Text(
              canEdit
                  ? 'Add your doctor and hospital so they are one tap away in an '
                      'emergency.'
                  : 'No care team details added yet.',
              style: context.textStyles.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            )
          else ...[
            if (doctorName?.isNotEmpty ?? false)
              Row(children: [
                const Icon(Icons.medical_services_outlined, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(doctorName!,
                        style: context.textStyles.bodyLarge)),
              ]),
            if (hospital?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(children: [
                const Icon(Icons.local_hospital_outlined, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child:
                        Text(hospital!, style: context.textStyles.bodyLarge)),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.error,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.sos, size: 56, color: context.colors.onError),
              const SizedBox(height: AppSpacing.xs),
              Text('SOS',
                  style: context.textStyles.headlineSmall?.copyWith(
                      color: context.colors.onError,
                      fontWeight: FontWeight.bold)),
              Text('Alert all contacts on WhatsApp',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onError)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.canEdit,
    required this.onCall,
    required this.onText,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final bool canEdit;
  final VoidCallback onCall;
  final VoidCallback onText;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colors.primaryContainer,
              child: Icon(
                  contact.isPrimary ? Icons.star : Icons.person,
                  color: context.colors.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: context.textStyles.titleSmall),
                  Text(
                    [
                      if (contact.relation.isNotEmpty) contact.relation,
                      contact.phone,
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
            IconButton(
              tooltip: 'Text',
              icon: const Icon(Icons.sms_outlined),
              onPressed: onText,
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
