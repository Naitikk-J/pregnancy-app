import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/appointment.dart';
import 'appointment_providers.dart';

/// Appointment manager: upcoming & past visits with reminders.
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: appointmentsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load appointments',
          message: '$e',
        ),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No appointments yet',
              message: 'Add your check-ups and scans to get timely reminders.',
              actionLabel: 'Add appointment',
              onAction: () => _edit(context, ref, null),
            );
          }
          final now = DateTime.now();
          final upcoming = all
              .where((a) => a.status != 'cancelled' && a.dateTime.isAfter(now))
              .toList();
          final past = all
              .where((a) => a.status == 'cancelled' || !a.dateTime.isAfter(now))
              .toList()
              .reversed
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (upcoming.isNotEmpty) ...[
                const SectionHeader(title: 'Upcoming'),
                for (final a in upcoming) _tile(context, ref, a),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (past.isNotEmpty) ...[
                const SectionHeader(title: 'Past'),
                for (final a in past) _tile(context, ref, a),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  static String _reminderLabel(int minutes) {
    if (minutes >= 1440) {
      final d = minutes ~/ 1440;
      return d == 1 ? '1 day' : '$d days';
    }
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      return h == 1 ? '1 hour' : '$h hours';
    }
    return '$minutes min';
  }

  Widget _tile(BuildContext context, WidgetRef ref, Appointment a) {
    final df = DateFormat('EEE, d MMM yyyy · h:mm a');
    return AppCard(
      onTap: () => _edit(context, ref, a),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.event, color: context.colors.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: context.textStyles.titleMedium),
                Text(df.format(a.dateTime),
                    style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant)),
                if (a.doctorName != null || a.hospital != null)
                  Text(
                    [a.doctorName, a.hospital]
                        .where((e) => e != null)
                        .join(' · '),
                    style: context.textStyles.bodySmall,
                  ),
                if (a.isUpcoming)
                  Row(
                    children: [
                      Icon(Icons.alarm,
                          size: 13, color: context.colors.primary),
                      const SizedBox(width: 3),
                      Text('Reminder ${_reminderLabel(a.reminderMinutesBefore)} before',
                          style: context.textStyles.labelSmall
                              ?.copyWith(color: context.colors.primary)),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                ref.read(appointmentActionsProvider)?.delete(a.id),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Appointment? existing,
  ) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final doctorCtrl = TextEditingController(text: existing?.doctorName ?? '');
    final hospitalCtrl = TextEditingController(text: existing?.hospital ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var when = existing?.dateTime ??
        DateTime.now().add(const Duration(days: 1, hours: 1));
    var reminder = existing?.reminderMinutesBefore ?? 120;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'New appointment' : 'Edit appointment',
                    style: ctx.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                    label: 'Title (e.g. Anomaly scan)', controller: titleCtrl),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Doctor', controller: doctorCtrl),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Hospital / clinic', controller: hospitalCtrl),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                      DateFormat('EEE, d MMM yyyy · h:mm a').format(when)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: when,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 400)),
                    );
                    if (date == null) return;
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(when),
                    );
                    setState(() => when = DateTime(date.year, date.month,
                        date.day, time?.hour ?? 9, time?.minute ?? 0));
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: reminder,
                  decoration: const InputDecoration(labelText: 'Remind me'),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 min before')),
                    DropdownMenuItem(value: 60, child: Text('1 hour before')),
                    DropdownMenuItem(value: 120, child: Text('2 hours before')),
                    DropdownMenuItem(value: 1440, child: Text('1 day before')),
                  ],
                  onChanged: (v) => setState(() => reminder = v ?? 120),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                    label: 'Notes', controller: notesCtrl, maxLines: 2),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save',
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(appointmentActionsProvider)?.save(
            Appointment(
              id: existing?.id ?? const Uuid().v4(),
              title: titleCtrl.text.trim(),
              dateTime: when,
              doctorName:
                  doctorCtrl.text.trim().isEmpty ? null : doctorCtrl.text.trim(),
              hospital: hospitalCtrl.text.trim().isEmpty
                  ? null
                  : hospitalCtrl.text.trim(),
              notes:
                  notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              reminderMinutesBefore: reminder,
            ),
          );
    }
    titleCtrl.dispose();
    doctorCtrl.dispose();
    hospitalCtrl.dispose();
    notesCtrl.dispose();
  }
}
