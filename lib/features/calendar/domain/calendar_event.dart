import 'package:equatable/equatable.dart';

enum CalendarEventKind { milestone, appointment }

/// A dated item shown on the pregnancy calendar/timeline. Aggregates
/// pregnancy milestones (computed) and appointments (from Firestore).
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.date,
    required this.title,
    required this.kind,
    this.subtitle,
  });

  final DateTime date;
  final String title;
  final String? subtitle;
  final CalendarEventKind kind;

  @override
  List<Object?> get props => [date, title, subtitle, kind];
}

/// Pure builder for the standard pregnancy milestones, dated from the LMP.
/// Returned in chronological order.
List<CalendarEvent> pregnancyMilestones(DateTime lmp, DateTime dueDate) {
  final start = DateTime(lmp.year, lmp.month, lmp.day);
  DateTime afterWeeks(int weeks) => start.add(Duration(days: weeks * 7));

  final events = <CalendarEvent>[
    CalendarEvent(
      date: start,
      title: 'Pregnancy start (LMP)',
      subtitle: 'Week 1',
      kind: CalendarEventKind.milestone,
    ),
    CalendarEvent(
      date: afterWeeks(13),
      title: 'Second trimester begins',
      subtitle: 'Week 14',
      kind: CalendarEventKind.milestone,
    ),
    CalendarEvent(
      date: afterWeeks(19),
      title: 'Anomaly scan window',
      subtitle: 'Around week 20',
      kind: CalendarEventKind.milestone,
    ),
    CalendarEvent(
      date: afterWeeks(23),
      title: 'Glucose screening window',
      subtitle: 'Weeks 24–28',
      kind: CalendarEventKind.milestone,
    ),
    CalendarEvent(
      date: afterWeeks(27),
      title: 'Third trimester begins',
      subtitle: 'Week 28',
      kind: CalendarEventKind.milestone,
    ),
    CalendarEvent(
      date: afterWeeks(36),
      title: 'Full term approaching',
      subtitle: 'Week 37',
      kind: CalendarEventKind.milestone,
    ),
    CalendarEvent(
      date: DateTime(dueDate.year, dueDate.month, dueDate.day),
      title: 'Estimated due date',
      subtitle: 'Week 40',
      kind: CalendarEventKind.milestone,
    ),
  ]..sort((a, b) => a.date.compareTo(b.date));

  return events;
}
