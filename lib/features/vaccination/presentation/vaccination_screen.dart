import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustom(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add vaccine'),
      ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(vaccineActionsProvider)?.delete(v);
                      } else {
                        _setStatus(context, ref, v,
                            VaccineStatus.fromName(value));
                      }
                    },
                    itemBuilder: (_) => [
                      for (final s in VaccineStatus.values)
                        PopupMenuItem(
                            value: s.name,
                            child: Text('Mark ${s.label.toLowerCase()}')),
                      if (isCustomVaccine(v.id)) ...[
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 88),
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
    await ref.read(vaccineActionsProvider)?.save(updated);
    if (context.mounted && status == VaccineStatus.scheduled) {
      context.showSnack('Scheduled — you’ll get a reminder that morning ⏰');
    }
  }

  /// Adds a custom vaccine the catalog doesn't list (e.g. a doctor-advised
  /// extra), optionally scheduling it with a reminder.
  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final timingCtrl = TextEditingController();
    DateTime? scheduledDate;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: ctx.sheetPadding(),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add vaccine', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                  label: 'Vaccine name', controller: nameCtrl),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'When it’s typically given (optional)',
                controller: timingCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(52),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(scheduledDate == null
                      ? 'Schedule a date (optional)'
                      : 'Scheduled: '
                          '${DateFormat('d MMM yyyy').format(scheduledDate!)}'),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 400)),
                  );
                  if (picked != null) setState(() => scheduledDate = picked);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Save',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    ctx.showSnack('Enter a vaccine name.', isError: true);
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

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      final vaccine = Vaccine(
        id: 'custom_${const Uuid().v4()}',
        name: nameCtrl.text.trim(),
        timing: timingCtrl.text.trim().isEmpty
            ? 'As advised by your doctor'
            : timingCtrl.text.trim(),
        status: scheduledDate == null
            ? VaccineStatus.due
            : VaccineStatus.scheduled,
        scheduledDate: scheduledDate,
      );
      await ref.read(vaccineActionsProvider)?.save(vaccine);
      if (context.mounted) {
        context.showSnack(scheduledDate == null
            ? 'Vaccine added.'
            : 'Vaccine added — reminder set for that morning ⏰');
      }
    }
    nameCtrl.dispose();
    timingCtrl.dispose();
  }
}
