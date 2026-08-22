import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/presentation/appointment_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/calendar_event.dart';

/// Pregnancy calendar: an agenda combining computed milestones with the
/// mother's appointments, split into upcoming and earlier.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final appointments =
        ref.watch(appointmentsProvider).valueOrNull ?? const [];

    final events = <CalendarEvent>[
      if (pregnancy != null)
        ...pregnancyMilestones(pregnancy.lmpDate, pregnancy.dueDate),
      for (final a in appointments) _fromAppointment(a),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final upcoming =
        events.where((e) => !e.date.isBefore(startOfToday)).toList();
    final past = events.reversed
        .where((e) => e.date.isBefore(startOfToday))
        .toList();

    if (events.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar')),
        body: const EmptyState(
          icon: Icons.event_outlined,
          title: 'Nothing scheduled yet',
          message: 'Your pregnancy milestones appear here once your dates are '
              'set, along with any appointments you add.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Upcoming'),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Nothing coming up.',
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            )
          else
            for (final e in upcoming) _EventTile(event: e, past: false),
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Earlier'),
            for (final e in past) _EventTile(event: e, past: true),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  CalendarEvent _fromAppointment(Appointment a) => CalendarEvent(
        date: a.dateTime,
        title: a.title,
        subtitle: [
          if (a.doctorName != null) a.doctorName,
          if (a.hospital != null) a.hospital,
          DateFormat('HH:mm').format(a.dateTime),
        ].whereType<String>().join(' · '),
        kind: CalendarEventKind.appointment,
      );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.past});
  final CalendarEvent event;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final isAppt = event.kind == CalendarEventKind.appointment;
    final color = past
        ? context.colors.outline
        : (isAppt ? context.colors.primary : context.colors.tertiary);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isAppt ? Icons.event_note : Icons.flag, color: color),
        ],
      ),
      title: Text(event.title,
          style: past
              ? context.textStyles.bodyLarge
                  ?.copyWith(color: context.colors.onSurfaceVariant)
              : context.textStyles.bodyLarge),
      subtitle: Text(
        [
          DateFormat('EEE, d MMM yyyy').format(event.date),
          if (event.subtitle != null && event.subtitle!.isNotEmpty)
            event.subtitle!,
        ].join(' · '),
        style: context.textStyles.bodySmall
            ?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    );
  }
}
