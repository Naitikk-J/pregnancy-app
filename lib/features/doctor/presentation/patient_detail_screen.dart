import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/models/pregnancy.dart';
import 'doctor_providers.dart';

/// Read-only summary of one patient for the doctor: pregnancy dates and the
/// latest vitals pulled from the mother's trackers.
class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({required this.pregnancy, super.key});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(patientProfileProvider(pregnancy.ownerUserId)).valueOrNull;
    final weight = ref.watch(latestWeightProvider(pregnancy.id)).valueOrNull;
    final bp = ref.watch(latestBpProvider(pregnancy.id)).valueOrNull;
    final glucose = ref.watch(latestGlucoseProvider(pregnancy.id)).valueOrNull;

    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : 'Patient';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pregnancy', style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _Row('Week', '${pregnancy.currentWeek} · ${pregnancy.trimester.label}'),
                _Row('Due date',
                    DateFormat('d MMM yyyy').format(pregnancy.dueDate)),
                _Row('Days to go', '${pregnancy.daysRemaining}'),
                _Row('Risk', pregnancy.riskCategory.label),
                if (pregnancy.hospital != null && pregnancy.hospital!.isNotEmpty)
                  _Row('Hospital', pregnancy.hospital!),
                if (profile?.bloodGroup != null &&
                    profile!.bloodGroup!.isNotEmpty)
                  _Row('Blood group', profile.bloodGroup!),
                if (profile != null && profile.medicalConditions.isNotEmpty)
                  _Row('Conditions', profile.medicalConditions.join(', ')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Latest vitals'),
          _VitalCard(
            icon: Icons.favorite_outline,
            label: 'Blood pressure',
            value: bp == null ? null : '${bp.systolic}/${bp.diastolic} mmHg',
            when: bp?.loggedAt,
          ),
          _VitalCard(
            icon: Icons.bloodtype_outlined,
            label: 'Blood sugar',
            value: glucose == null
                ? null
                : '${glucose.mgDl.toStringAsFixed(0)} mg/dL · ${glucose.context.label}',
            when: glucose?.loggedAt,
          ),
          _VitalCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            value: weight == null
                ? null
                : '${weight.weightKg.toStringAsFixed(1)} kg',
            when: weight?.loggedAt,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Records sync from the patient’s own trackers. This view is '
            'read-only.',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          Expanded(
              child: Text(value, style: context.textStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.when,
  });
  final IconData icon;
  final String label;
  final String? value;
  final DateTime? when;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textStyles.titleSmall),
                Text(
                  value ?? 'No readings yet',
                  style: context.textStyles.bodyMedium?.copyWith(
                      color: value == null
                          ? context.colors.onSurfaceVariant
                          : null),
                ),
              ],
            ),
          ),
          if (when != null)
            Text(DateFormat('d MMM').format(when!),
                style: context.textStyles.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
