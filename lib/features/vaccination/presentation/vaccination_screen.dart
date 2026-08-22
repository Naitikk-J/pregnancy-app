import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/vaccine.dart';
import 'vaccination_providers.dart';

/// Vaccination checklist: the recommended pregnancy vaccines with per-vaccine
/// status (due / scheduled / done) the mother can update.
class VaccinationScreen extends ConsumerWidget {
  const VaccinationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccines = ref.watch(vaccineListProvider);
    final done = vaccines.where((v) => v.status == VaccineStatus.done).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            color: context.colors.secondaryContainer,
            child: Row(
              children: [
                Icon(Icons.vaccines,
                    color: context.colors.onSecondaryContainer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '$done of ${vaccines.length} done. Confirm timing and '
                    'suitability with your doctor.',
                    style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final v in vaccines)
            AppCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(_statusIcon(v.status), color: _statusColor(context, v.status)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: context.textStyles.titleSmall),
                        Text(_subtitle(v),
                            style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  PopupMenuButton<VaccineStatus>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (status) => _setStatus(context, ref, v, status),
                    itemBuilder: (_) => [
                      for (final s in VaccineStatus.values)
                        PopupMenuItem(value: s, child: Text('Mark ${s.label.toLowerCase()}')),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _subtitle(Vaccine v) => switch (v.status) {
        VaccineStatus.done => v.completedDate != null
            ? 'Done · ${DateFormat('d MMM yyyy').format(v.completedDate!)}'
            : 'Done',
        VaccineStatus.scheduled => v.scheduledDate != null
            ? 'Scheduled · ${DateFormat('d MMM yyyy').format(v.scheduledDate!)}'
            : 'Scheduled',
        VaccineStatus.due => v.timing,
      };

  IconData _statusIcon(VaccineStatus s) => switch (s) {
        VaccineStatus.done => Icons.check_circle,
        VaccineStatus.scheduled => Icons.event_available,
        VaccineStatus.due => Icons.radio_button_unchecked,
      };

  Color _statusColor(BuildContext context, VaccineStatus s) => switch (s) {
        VaccineStatus.done => context.colors.primary,
        VaccineStatus.scheduled => context.colors.tertiary,
        VaccineStatus.due => context.colors.outline,
      };

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Vaccine v,
    VaccineStatus status,
  ) async {
    Vaccine updated;
    switch (status) {
      case VaccineStatus.done:
        updated = v.copyWith(
            status: status, completedDate: DateTime.now(), clearDates: false);
      case VaccineStatus.scheduled:
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 300)),
        );
        if (picked == null) return;
        updated = v.copyWith(status: status, scheduledDate: picked);
      case VaccineStatus.due:
        updated = v.copyWith(status: status, clearDates: true);
    }
    await ref.read(vaccineCrudProvider)?.upsert(updated);
  }
}
