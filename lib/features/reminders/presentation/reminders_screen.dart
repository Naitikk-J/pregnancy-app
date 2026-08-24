import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/reminder_item.dart';
import 'reminder_providers.dart';

/// Personal reminders with alarm-clock notifications — "drink water at 4pm",
/// "call the doctor", etc. One-off or daily.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remindersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add_alarm),
        label: const Text('New reminder'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load reminders',
            message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.alarm,
              title: 'No reminders yet',
              message: 'Set an alarm for anything — water, a walk, calling your '
                  'doctor, or taking rest.',
              actionLabel: 'New reminder',
              onAction: () => _edit(context, ref, null),
            );
          }
          final upcoming = items.where((r) => !r.done).toList();
          final done = items.where((r) => r.done).toList();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const ReminderStatusBanner(),
              if (upcoming.isNotEmpty) ...[
                const SectionHeader(title: 'Upcoming'),
                for (final r in upcoming) _tile(context, ref, r),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (done.isNotEmpty) ...[
                const SectionHeader(title: 'Done'),
                for (final r in done) _tile(context, ref, r),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, ReminderItem r) {
    final when = r.repeatDaily
        ? 'Every day · ${DateFormat('h:mm a').format(r.remindAt)}'
        : DateFormat('EEE, d MMM · h:mm a').format(r.remindAt);
    return AppCard(
      onTap: () => _edit(context, ref, r),
      child: Row(
        children: [
          Checkbox(
            value: r.done,
            onChanged: (_) => ref.read(reminderActionsProvider)?.toggleDone(r),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: context.textStyles.titleSmall?.copyWith(
                        decoration:
                            r.done ? TextDecoration.lineThrough : null)),
                Row(
                  children: [
                    Icon(r.repeatDaily ? Icons.repeat : Icons.alarm,
                        size: 14, color: context.colors.primary),
                    const SizedBox(width: 4),
                    Text(when,
                        style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                  ],
                ),
                if (r.note != null && r.note!.isNotEmpty)
                  Text(r.note!, style: context.textStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(reminderActionsProvider)?.delete(r),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, ReminderItem? existing) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var date = existing?.remindAt ??
        DateTime.now().add(const Duration(hours: 1));
    var repeat = existing?.repeatDaily ?? false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: ctx.sheetPadding(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'New reminder' : 'Edit reminder',
                  style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                  label: 'What should I remind you?', controller: titleCtrl),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(DateFormat('EEE, d MMM').format(date)),
                      onPressed: repeat
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: date,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 400)),
                              );
                              if (picked != null) {
                                setState(() => date = DateTime(picked.year,
                                    picked.month, picked.day, date.hour, date.minute));
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(DateFormat('h:mm a').format(date)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(date),
                        );
                        if (picked != null) {
                          setState(() => date = DateTime(date.year, date.month,
                              date.day, picked.hour, picked.minute));
                        }
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat every day'),
                value: repeat,
                onChanged: (v) => setState(() => repeat = v),
              ),
              AppTextField(
                  label: 'Note (optional)', controller: noteCtrl, maxLines: 2),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Save',
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    ctx.showSnack('Give it a title.', isError: true);
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
      var when = date;
      // A one-off time already in the past → bump to tomorrow same time.
      if (!repeat && when.isBefore(DateTime.now())) {
        when = when.add(const Duration(days: 1));
      }
      await ref.read(reminderActionsProvider)?.save(
            ReminderItem(
              id: existing?.id ?? const Uuid().v4(),
              title: titleCtrl.text.trim(),
              remindAt: when,
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              repeatDaily: repeat,
              done: existing?.done ?? false,
            ),
          );
      if (context.mounted) context.showSnack('Reminder set ⏰');
    }
    titleCtrl.dispose();
    noteCtrl.dispose();
  }
}
