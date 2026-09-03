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

/// Redesigned Emergency SOS Screen ("Serene Bloom").
///
/// Features high-contrast, instant-action emergency hotlines,
/// tactile 1-tap SOS broadcast, medical passport card, and contact speed-dial.
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

  static String _alertText(String name) =>
      '🚨 SOS ALERT from $name. I may need urgent pregnancy / medical assistance. '
      'Please call me immediately. (Sent via Pregnancy Companion)';

  Future<void> _whatsApp(BuildContext context, String phone, String body) async {
    if (!await MessageShare.whatsApp(body, phone: phone) && context.mounted) {
      context.showSnack('Couldn’t open WhatsApp. Is it installed?', isError: true);
    }
  }

  Future<void> _alertFamilyWhatsApp(BuildContext context, WidgetRef ref) async {
    final primary = ref.read(primaryContactProvider);
    final name = ref.read(userProfileProvider).valueOrNull?.name ??
        ref.read(currentUserProvider)?.displayName ??
        'I';
    if (!await MessageShare.whatsApp(_alertText(name), phone: primary?.phone) &&
        context.mounted) {
      context.showSnack('Couldn’t open WhatsApp. Is it installed?', isError: true);
    }
  }

  Future<void> _openNearestHospital(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=maternity+hospitals+near+me',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      context.showSnack('Could not open maps.', isError: true);
    }
  }

  Future<void> _triggerSos(BuildContext context, WidgetRef ref) async {
    final contacts = ref.read(emergencyContactsProvider).valueOrNull ?? const [];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 28),
            SizedBox(width: 8),
            Text('Broadcast SOS?'),
          ],
        ),
        content: Text(contacts.isEmpty
            ? 'This records an in-app emergency alert and opens WhatsApp so you can send for help.'
            : 'This records an in-app emergency alert for your family and sends an immediate SOS to ${contacts.length} emergency contact${contacts.length == 1 ? '' : 's'}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final col = ref.read(sosCollectionProvider);
    final user = ref.read(currentUserProvider);
    final name = ref.read(userProfileProvider).valueOrNull?.name ??
        user?.displayName ??
        'Mother';

    if (col != null) {
      final id = const Uuid().v4();
      try {
        await col.doc(id).set({
          'id': id,
          'createdBy': user?.uid,
          'createdByName': name,
          'status': 'active',
          'message': 'SOS: $name needs urgent assistance.',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {}
    }

    if (!context.mounted) return;
    if (contacts.isEmpty) {
      await _whatsApp(context, '', _alertText(name));
    } else {
      await _sendSosToAll(context, contacts, _alertText(name));
    }
  }

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
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sos_rounded, color: Color(0xFFE11D48)),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Send SOS on WhatsApp', style: ctx.textStyles.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap each contact to send your pre-filled SOS message.',
                  style: ctx.textStyles.bodySmall?.copyWith(
                    color: ctx.colors.onSurfaceVariant,
                  ),
                ),
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
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [if (c.relation.isNotEmpty) c.relation, c.phone].join(' · '),
                          ),
                          trailing: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                            ),
                            icon: const Icon(Icons.chat, size: 16),
                            label: Text(sent.contains(c.id) ? 'Sent' : 'Send SOS'),
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
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    final isOwner = pregnancy != null && pregnancy.ownerUserId == user?.uid;
    final contacts = ref.watch(emergencyContactsProvider).valueOrNull ?? const [];
    final name = profile?.name ?? user?.displayName ?? 'Mother';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS & Safety'),
        actions: [
          IconButton(
            tooltip: 'Find Nearby Hospitals',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _openNearestHospital(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl + 40,
        ),
        children: [
          // ==================== 1. TACTILE HERO SOS CARD ====================
          _HeroSosBroadcastCard(
            onSosTap: () => _triggerSos(context, ref),
            onWhatsAppTap: () => _alertFamilyWhatsApp(context, ref),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 2. 1-TAP EMERGENCY HOTLINES ====================
          Text(
            'Direct Emergency Dials',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _HotlineDialButton(
                  title: 'Ambulance',
                  number: _ambulanceNumber,
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFFE11D48),
                  onTap: () => _dial(context, _ambulanceNumber),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HotlineDialButton(
                  title: 'Emergency',
                  number: _emergencyNumber,
                  icon: Icons.call_rounded,
                  color: const Color(0xFF6366F1),
                  onTap: () => _dial(context, _emergencyNumber),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _HotlineDialButton(
                  title: 'Nearby Hospitals',
                  number: 'Maps Route',
                  icon: Icons.directions_car_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => _openNearestHospital(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HotlineDialButton(
                  title: 'Blood Donors',
                  number: 'Find Donors',
                  icon: Icons.bloodtype_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.pushNamed(AppRoutes.bloodDonorsName),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 3. MEDICAL PASSPORT CARD ====================
          _MedicalPassportCard(
            name: name,
            pregnancy: pregnancy,
            profile: profile,
            onEditTap: isOwner
                ? () => context.pushNamed(AppRoutes.editProfileName)
                : null,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 4. EMERGENCY CONTACTS ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts (${contacts.length})',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isOwner)
                TextButton.icon(
                  onPressed: () => _editContact(context, ref, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Contact'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (contacts.isEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Icon(Icons.contact_phone_outlined,
                        size: 36, color: context.colors.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No emergency contacts added yet',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add your partner, family, or doctor for instant 1-tap SOS alerts.',
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _editContact(context, ref, null),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Contact Now'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            for (final c in contacts)
              _ContactCard(
                contact: c,
                canEdit: isOwner,
                onCall: () => _dial(context, c.phone),
                onSms: () => _sms(
                  context,
                  c.phone,
                  'SOS from $name. Please call me immediately. (Pregnancy Companion)',
                ),
                onWhatsApp: () => _whatsApp(context, c.phone, _alertText(name)),
                onEdit: () => _editContact(context, ref, c),
                onDelete: () =>
                    ref.read(emergencyContactsCrudProvider)?.delete(c.id),
              ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 5. RED FLAG WARNINGS ====================
          const _RedFlagsWarningCard(),
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
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: ctx.sheetPadding(),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add Emergency Contact' : 'Edit Contact',
                style: ctx.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Full Name', controller: nameCtrl),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Phone Number',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Relationship (e.g. Husband, Sister, Doctor)',
                controller: relCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primary Contact (Dial First)'),
                value: isPrimary,
                onChanged: (v) => setState(() => isPrimary = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Save Contact',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                    ctx.showSnack('Please enter name and phone number.', isError: true);
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
              ),
              const SizedBox(height: AppSpacing.md),
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

// ---------------- Helper Widgets ----------------

class _HeroSosBroadcastCard extends StatelessWidget {
  const _HeroSosBroadcastCard({
    required this.onSosTap,
    required this.onWhatsAppTap,
  });

  final VoidCallback onSosTap;
  final VoidCallback onWhatsAppTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Broadcast',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Alert all family & contacts with your location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSosTap,
              icon: const Icon(Icons.warning_rounded, color: Color(0xFFBE123C), size: 22),
              label: const Text(
                'BROADCAST SOS ALERT',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFBE123C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onWhatsAppTap,
              icon: const Icon(Icons.chat, color: Colors.white, size: 18),
              label: const Text(
                'Alert Primary Contact on WhatsApp',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotlineDialButton extends StatelessWidget {
  const _HotlineDialButton({
    required this.title,
    required this.number,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String number;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  number,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalPassportCard extends StatelessWidget {
  const _MedicalPassportCard({
    required this.name,
    this.pregnancy,
    this.profile,
    this.onEditTap,
  });

  final String name;
  final dynamic pregnancy;
  final dynamic profile;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final bloodGroup = profile?.bloodGroup ?? 'Unknown';
    final week = pregnancy?.currentWeek != null ? 'Week ${pregnancy.currentWeek}' : 'Active';
    final doctor = pregnancy?.doctorName ?? 'Not specified';
    final hospital = pregnancy?.hospital ?? 'Not specified';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.badge_rounded, color: context.colors.primary, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Emergency Medical ID',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (onEditTap != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEditTap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MedicalStat(label: 'Mother', value: name),
              ),
              Expanded(
                child: _MedicalStat(label: 'Gestational Stage', value: week),
              ),
              Expanded(
                child: _MedicalStat(
                  label: 'Blood Group',
                  value: bloodGroup,
                  valueColor: const Color(0xFFE11D48),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MedicalStat(label: 'Doctor', value: doctor),
              ),
              Expanded(
                child: _MedicalStat(label: 'Hospital / Clinic', value: hospital),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicalStat extends StatelessWidget {
  const _MedicalStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            fontSize: 11,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.canEdit,
    required this.onCall,
    required this.onSms,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final bool canEdit;
  final VoidCallback onCall;
  final VoidCallback onSms;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: contact.isPrimary
                  ? const Color(0xFFFFF1F2)
                  : context.colors.surfaceContainerHigh,
              child: Icon(
                contact.isPrimary ? Icons.star_rounded : Icons.person_rounded,
                color: contact.isPrimary
                    ? const Color(0xFFE11D48)
                    : context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        contact.name,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    [if (contact.relation.isNotEmpty) contact.relation, contact.phone].join(' · '),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'WhatsApp',
              icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
              onPressed: onWhatsApp,
            ),
            IconButton(
              tooltip: 'SMS',
              icon: const Icon(Icons.sms_rounded, size: 20),
              onPressed: onSms,
            ),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              tooltip: 'Call',
              icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
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

class _RedFlagsWarningCard extends StatelessWidget {
  const _RedFlagsWarningCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.errorContainer.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: context.colors.onErrorContainer, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'When to Seek Immediate Medical Help',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• Heavy or sudden vaginal bleeding\n'
            '• Severe or persistent abdominal pain\n'
            '• Noticeable reduction in baby kicks/movements\n'
            '• Water breaking or continuous fluid leaking\n'
            '• Severe headache with blurred vision or dizziness\n'
            '• High fever with chills',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onErrorContainer,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
