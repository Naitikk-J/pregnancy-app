import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/models/pregnancy.dart';
import 'doctor_providers.dart';
import 'patient_detail_screen.dart';

/// A doctor's view of their linked patients. Doctors link to a pregnancy using
/// its invite code (via Partner & family), then see a read-only summary here.
class DoctorPortalScreen extends ConsumerWidget {
  const DoctorPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = ref.watch(isDoctorProvider);
    final patients = ref.watch(doctorPatientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor portal')),
      body: !isDoctor
          ? const EmptyState(
              icon: Icons.medical_services_outlined,
              title: 'For doctors',
              message: 'This portal is for accounts with the Doctor role. Ask '
                  'your patient to share their invite code, then join it from '
                  'Partner & family to see their records here.',
            )
          : patients.when(
              loading: () => const LoadingView(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load patients',
                message: '$e',
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No patients yet',
                    message: 'Join a patient with their invite code (Partner & '
                        'family) to see them here.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [for (final p in list) _PatientTile(pregnancy: p)],
                );
              },
            ),
    );
  }
}

class _PatientTile extends ConsumerWidget {
  const _PatientTile({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(patientProfileProvider(pregnancy.ownerUserId)).valueOrNull;
    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : 'Patient';

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(pregnancy: pregnancy),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.primaryContainer,
            child: Text(name.characters.first.toUpperCase(),
                style: context.textStyles.titleMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textStyles.titleMedium),
                Text(
                  'Week ${pregnancy.currentWeek} · ${pregnancy.trimester.label} · '
                  'Due ${DateFormat('d MMM yyyy').format(pregnancy.dueDate)}',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _RiskChip(risk: pregnancy.riskCategory.label),
        ],
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.risk});
  final String risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(risk,
          style: context.textStyles.labelSmall
              ?.copyWith(color: context.colors.onSecondaryContainer)),
    );
  }
}
