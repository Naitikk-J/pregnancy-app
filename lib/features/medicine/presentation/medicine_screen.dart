import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_share.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai_tools/presentation/interaction_check_sheet.dart';
import '../domain/medicine.dart';
import 'medicine_info_sheet.dart';
import 'medicine_providers.dart';

/// Warns — right at the top of the Medicines screen — when the OS is blocking
/// reminders (notifications turned off, or exact alarms disabled), with a tap to
/// fix it. This is what turns "my reminders never fire" from a silent mystery
/// into something the user can act on.
class _ReminderStatusBanner extends ConsumerWidget {
  const _ReminderStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationStatusProvider).valueOrNull;
    if (status == null || status.ready && status.exactAlarmsAllowed) {
      return const SizedBox.shrink();
    }
    final blocked = !status.notificationsEnabled;
    final color = blocked
        ? context.colors.errorContainer
        : context.colors.tertiaryContainer;
    final onColor = blocked
        ? context.colors.onErrorContainer
        : context.colors.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        color: color,
        onTap: () async {
          await ref.read(notificationServiceProvider).requestPermissions();
          ref.invalidate(notificationStatusProvider);
          if (context.mounted) {
            context.showSnack(
              blocked
                  ? 'If nothing changed, enable notifications in Settings → Apps '
                      '→ Pregnancy Companion, and turn off battery optimization.'
                  : 'Exact-alarm settings opened — allow it so reminders are on '
                      'time.',
            );
          }
        },
        child: Row(
          children: [
            Icon(blocked ? Icons.notifications_off_outlined : Icons.alarm_off,
                color: onColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blocked
                        ? 'Reminders are blocked'
                        : 'Reminders may be delayed',
                    style: context.textStyles.titleSmall?.copyWith(
                        color: onColor, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    blocked
                        ? 'Notifications are off for this app — tap to turn them '
                            'on so medicine alarms can fire.'
                        : 'Exact alarms are off. Tap to allow precise reminder '
                            'times.',
                    style:
                        context.textStyles.bodySmall?.copyWith(color: onColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: onColor),
          ],
        ),
      ),
    );
  }
}

/// Medicine scheduler: today's doses (take/skip), refill alerts, and the full
/// medicine list with add/edit. Saving schedules daily alarm reminders per dose
/// time. Meds are set up by frequency (times/day) and course length (days) —
/// no calendar dates — plus an SOS ("only when needed") mode.
class MedicineScreen extends ConsumerWidget {
  const MedicineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flush any "Taken" taps recorded while the app was in the background.
    ref.watch(pendingDoseReconcileProvider);
    // Re-register reminders so alarms survive reboot/reinstall.
    ref.watch(medicineRescheduleProvider);
    final medsAsync = ref.watch(medicinesProvider);
    final doses = ref.watch(todayDosesProvider);

    final allMeds = medsAsync.valueOrNull ?? const <Medicine>[];
    final medNames = allMeds
        .where((m) => m.name.trim().isNotEmpty)
        .map((m) => m.name.trim())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines'),
        actions: [
          IconButton(
            tooltip: 'Scan prescription',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => context.pushNamed(AppRoutes.prescriptionScanName),
          ),
          if (allMeds.isNotEmpty)
            IconButton(
              tooltip: 'Share list to buy',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => _shareToBuy(context, allMeds),
            ),
          if (medNames.length >= 2)
            IconButton(
              tooltip: 'Check interactions',
              icon: const Icon(Icons.warning_amber_outlined),
              onPressed: () =>
                  showInteractionCheckSheet(context, medicines: medNames),
            ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              if (v == 'test') _testReminder(context, ref);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'test',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.alarm),
                  title: Text('Test reminder'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: medsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load medicines',
          message: '$e',
        ),
        data: (meds) {
          if (meds.isEmpty) {
            return EmptyState(
              icon: Icons.medication_outlined,
              imageAsset: 'assets/images/mom.png',
              title: 'No medicines yet',
              message: 'Add your prescriptions to get dose reminders and track '
                  'adherence — or scan a prescription to add them all at once.',
              actionLabel: 'Add medicine',
              onAction: () => _edit(context, ref, null),
              secondaryActionLabel: 'Scan a prescription',
              onSecondaryAction: () =>
                  context.pushNamed(AppRoutes.prescriptionScanName),
            );
          }
          final endingSoon = meds.where((m) => m.endingSoon()).toList();
          final sos = meds.where((m) => m.asNeeded).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const _ReminderStatusBanner(),
              if (doses.isNotEmpty) ...[
                const SectionHeader(title: 'Today’s doses'),
                for (final dose in doses) _doseTile(context, ref, dose),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (sos.isNotEmpty) ...[
                const SectionHeader(title: 'When needed (SOS)'),
                for (final m in sos) _sosTile(context, ref, m),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (endingSoon.isNotEmpty) ...[
                const SectionHeader(title: 'Running low'),
                for (final m in endingSoon)
                  AppCard(
                    color: context.colors.tertiaryContainer,
                    onTap: () => _shareToBuy(context, [m]),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: context.colors.onTertiaryContainer),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_endingLabel(m),
                                  style: context.textStyles.titleSmall?.copyWith(
                                      color:
                                          context.colors.onTertiaryContainer)),
                              if (m.courseUnits != null)
                                Text('Buy about ${m.courseUnits} to continue',
                                    style: context.textStyles.bodySmall?.copyWith(
                                        color: context
                                            .colors.onTertiaryContainer)),
                            ],
                          ),
                        ),
                        Icon(Icons.share_outlined,
                            color: context.colors.onTertiaryContainer),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionHeader(title: 'All medicines'),
              for (final m in meds) _medicineTile(context, ref, m),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _endingLabel(Medicine m) {
    final d = m.daysUntilEnd;
    if (d == null) return '${m.name} is running low';
    if (d <= 0) return '${m.name} finishes today';
    if (d == 1) return '${m.name} finishes tomorrow';
    return '${m.name} finishes in $d days';
  }

  Future<void> _testReminder(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(medicineActionsProvider);
    if (actions == null) return;
    final service = ref.read(notificationServiceProvider);
    // Make sure the OS has granted permission first, then schedule the test.
    await service.requestPermissions();
    final status = await service.status();
    ref.invalidate(notificationStatusProvider);
    if (!status.notificationsEnabled) {
      if (context.mounted) {
        context.showSnack(
          'Notifications are turned OFF for this app. Open Settings → Apps → '
          'Pregnancy Companion → Notifications and allow them.',
        );
      }
      return;
    }
    await actions.sendTestReminder();
    if (context.mounted) {
      final extra = status.exactAlarmsAllowed
          ? ''
          : ' (exact alarms are off, so it may arrive a bit late).';
      context.showSnack('Test alarm set — watch for it in ~8 seconds$extra');
    }
  }

  /// Composes a "medicines to buy" shopping list — with quantities computed from
  /// the prescription (units/dose × times/day × days) — and shares it (WhatsApp /
  /// SMS / Email) so a partner can pick them up. When passed a single medicine,
  /// shares just that one; otherwise prefers courses that are running low, then
  /// falls back to all active medicines.
  Future<void> _shareToBuy(BuildContext context, List<Medicine> meds) async {
    final List<Medicine> list;
    if (meds.length == 1) {
      list = meds;
    } else {
      final low = meds.where((m) => m.endingSoon()).toList();
      list = (low.isNotEmpty ? low : meds.where((m) => m.active).toList())
          .where((m) => m.name.trim().isNotEmpty)
          .toList();
    }

    if (list.isEmpty) {
      context.showSnack('No medicines to share yet.');
      return;
    }

    final lines = list.map((m) {
      final name = m.name.trim();
      final dose = m.dosage.trim();
      final qty = m.courseUnits;
      if (qty != null) {
        // e.g. "Folic acid — buy 60 (1 tablet × 2/day for 30 days)"
        final per = '${dose.isEmpty ? '1' : dose} × ${m.timesPerDay}/day '
            'for ${m.durationDays} days';
        return '• $name — buy $qty ($per)';
      }
      if (m.asNeeded) return '• $name${dose.isEmpty ? '' : ' — $dose'} (as needed)';
      return dose.isEmpty ? '• $name' : '• $name — $dose';
    }).join('\n');

    final text = 'Medicines to buy 🛒\n\n$lines\n\n'
        'Thank you 🙏 (via Pregnancy Companion)';

    await showShareSheet(
      context,
      text: text,
      subject: 'Medicines to buy',
    );
  }

  Widget _doseTile(BuildContext context, WidgetRef ref, DoseView dose) {
    final taken = dose.status == DoseStatus.taken;
    final skipped = dose.status == DoseStatus.skipped;
    // Tick = taken, untick = not taken. Tapping the tile toggles it.
    void toggle() => ref.read(medicineActionsProvider)?.markDose(dose.medicine,
        dose.time, taken ? DoseStatus.pending : DoseStatus.taken);
    return AppCard(
      onTap: toggle,
      child: Row(
        children: [
          Checkbox(
            value: taken,
            onChanged: (_) => toggle(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dose.medicine.name,
                    style: context.textStyles.titleMedium?.copyWith(
                        decoration: taken ? TextDecoration.lineThrough : null,
                        color: taken ? context.colors.onSurfaceVariant : null)),
                Row(
                  children: [
                    Icon(Icons.alarm,
                        size: 13, color: context.colors.primary),
                    const SizedBox(width: 3),
                    Text(dose.time,
                        style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600)),
                    Text('  ·  ${dose.medicine.dosage} · ${dose.medicine.timingLabel}',
                        style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
          if (skipped)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text('Skipped',
                  style: context.textStyles.labelSmall
                      ?.copyWith(color: context.colors.error)),
            )
          else if (!taken)
            IconButton(
              tooltip: 'Skip this dose',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => ref.read(medicineActionsProvider)?.markDose(
                  dose.medicine, dose.time, DoseStatus.skipped),
            ),
        ],
      ),
    );
  }

  /// An SOS medicine: no schedule, a single "Log dose taken" action.
  Widget _sosTile(BuildContext context, WidgetRef ref, Medicine m) {
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.emergency_outlined, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: context.textStyles.titleMedium),
                Text('${m.dosage} · ${m.timingLabel}',
                    style: context.textStyles.bodySmall),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Took it'),
            onPressed: () {
              // Fire-and-forget; Firestore offline persistence queues the write.
              ref.read(medicineActionsProvider)?.logAsNeededDose(m);
              context.showSnack('Logged ${m.name}.');
            },
          ),
        ],
      ),
    );
  }

  Widget _medicineTile(BuildContext context, WidgetRef ref, Medicine m) {
    return AppCard(
      onTap: () => _edit(context, ref, m),
      child: Row(
        children: [
          Icon(Icons.medication,
              color: m.active
                  ? context.colors.primary
                  : context.colors.outline),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: context.textStyles.titleMedium),
                Text('${m.dosage} · ${m.timingLabel}',
                    style: context.textStyles.bodySmall),
                Text(_scheduleSummary(m),
                    style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'About this medicine',
            icon: const Icon(Icons.info_outline),
            onPressed: m.name.trim().isEmpty
                ? null
                : () => showMedicineInfoSheet(context,
                    name: m.name, dosage: m.dosage),
          ),
          Switch(
            value: m.active,
            onChanged: (v) =>
                ref.read(medicineActionsProvider)?.setActive(m, v),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(medicineActionsProvider)?.delete(m),
          ),
        ],
      ),
    );
  }

  String _scheduleSummary(Medicine m) {
    if (m.asNeeded) return 'Only when needed (SOS)';
    final freq = m.times.length;
    final perDay = freq == 1 ? 'Once a day' : '$freq times a day';
    final course = m.durationDays != null ? ' · for ${m.durationDays} days' : ' · ongoing';
    final at = m.times.isEmpty ? '' : ' · ${m.times.join(', ')}';
    return '$perDay$course$at';
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Medicine? existing,
  ) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var timing = existing?.timing ?? MedicineTiming.afterFood;
    var asNeeded = existing?.asNeeded ?? false;
    var frequency =
        (existing?.times.isNotEmpty ?? false) ? existing!.times.length : 2;
    var times = <String>[
      ...(existing?.times.isNotEmpty ?? false)
          ? existing!.times
          : defaultDoseTimes(frequency)
    ];
    var ongoing =
        existing != null && !existing.asNeeded && existing.durationDays == null;
    var days = existing?.durationDays ?? 5;

    String two(int v) => v.toString().padLeft(2, '0');

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
                Text(existing == null ? 'Add medicine' : 'Edit medicine',
                    style: ctx.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                    label: 'Name (e.g. Folic acid)', controller: nameCtrl),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                    label: 'Dosage (e.g. 1 tablet, 5 ml)',
                    controller: dosageCtrl),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('What is this medicine? (effects)'),
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      if (n.isEmpty) {
                        ctx.showSnack('Enter the medicine name first.',
                            isError: true);
                        return;
                      }
                      showMedicineInfoSheet(ctx,
                          name: n, dosage: dosageCtrl.text.trim());
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // --- Timing (before / after food) ---
                Text('When to take', style: ctx.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<MedicineTiming>(
                  segments: const [
                    ButtonSegment(
                        value: MedicineTiming.beforeFood,
                        label: Text('Before food')),
                    ButtonSegment(
                        value: MedicineTiming.afterFood,
                        label: Text('After food')),
                    ButtonSegment(
                        value: MedicineTiming.anytime, label: Text('Anytime')),
                  ],
                  selected: {timing},
                  onSelectionChanged: (s) => setState(() => timing = s.first),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- SOS ---
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only when needed (SOS)'),
                  subtitle: const Text('No fixed schedule or reminders'),
                  value: asNeeded,
                  onChanged: (v) => setState(() => asNeeded = v),
                ),

                if (!asNeeded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // --- How many times a day ---
                  _StepperRow(
                    label: 'How many times a day',
                    value: frequency,
                    min: 1,
                    max: 6,
                    onChanged: (v) => setState(() {
                      frequency = v;
                      times = [...defaultDoseTimes(frequency)];
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Reminder times (tap to change)',
                      style: ctx.textStyles.bodySmall?.copyWith(
                          color: ctx.colors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (var i = 0; i < times.length; i++)
                        InputChip(
                          avatar: const Icon(Icons.alarm, size: 16),
                          label: Text(times[i]),
                          onPressed: () async {
                            final parts = times[i].split(':');
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay(
                                hour: int.tryParse(parts.first) ?? 9,
                                minute: int.tryParse(
                                        parts.length > 1 ? parts[1] : '0') ??
                                    0,
                              ),
                            );
                            if (picked != null) {
                              setState(() => times[i] =
                                  '${two(picked.hour)}:${two(picked.minute)}');
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // --- For how many days ---
                  Row(
                    children: [
                      Expanded(
                        child: Text('Ongoing (no end)',
                            style: ctx.textStyles.titleSmall),
                      ),
                      Switch(
                        value: ongoing,
                        onChanged: (v) => setState(() => ongoing = v),
                      ),
                    ],
                  ),
                  if (!ongoing)
                    _StepperRow(
                      label: 'For how many days',
                      value: days,
                      min: 1,
                      max: 120,
                      step: 1,
                      onChanged: (v) => setState(() => days = v),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],

                AppTextField(
                    label: 'Notes (optional)',
                    controller: notesCtrl,
                    maxLines: 2),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save',
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      ctx.showSnack('Please enter a name.', isError: true);
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

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      // Ask for notification permission before scheduling reminders.
      if (!asNeeded) {
        await ref.read(notificationServiceProvider).requestPermissions();
      }
      final start = existing?.startDate ?? DateTime.now();
      final startDay = DateTime(start.year, start.month, start.day);
      final actions = ref.read(medicineActionsProvider);
      if (actions == null) {
        if (context.mounted) {
          context.showSnack(
              "Your pregnancy isn't set up on this account yet.",
              isError: true);
        }
      } else {
        try {
          await actions.save(
            Medicine(
              id: existing?.id ?? const Uuid().v4(),
              name: nameCtrl.text.trim(),
              dosage: dosageCtrl.text.trim(),
              timing: timing,
              times: asNeeded ? const [] : times,
              startDate: start,
              endDate: asNeeded || ongoing
                  ? null
                  : startDay.add(Duration(days: days)),
              refillDate: existing?.refillDate,
              notes: notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              active: existing?.active ?? true,
              asNeeded: asNeeded,
              durationDays: asNeeded || ongoing ? null : days,
            ),
            previousTimes: existing?.times ?? const [],
          );
          if (context.mounted) context.showSnack('Medicine saved.');
        } catch (e) {
          if (context.mounted) {
            context.showSnack(
                "Couldn't save. If this keeps happening your account may need "
                'to be re-linked to your pregnancy.',
                isError: true);
          }
        }
      }
    }
    nameCtrl.dispose();
    dosageCtrl.dispose();
    notesCtrl.dispose();
  }
}

/// A "- value +" stepper row bounded to [min]..[max].
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: context.textStyles.titleSmall)),
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('$value', style: context.textStyles.titleLarge),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
