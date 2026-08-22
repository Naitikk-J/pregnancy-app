import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../journal/domain/journal_entry.dart';
import '../domain/mood_entry.dart';
import 'mood_providers.dart';

/// A month calendar where the mother taps any day to record how she felt. Each
/// day cell is tinted with the mood colour and shows its emoji, so she can see
/// her emotional journey across the month at a glance.
class MoodCalendarScreen extends ConsumerStatefulWidget {
  const MoodCalendarScreen({super.key});

  @override
  ConsumerState<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends ConsumerState<MoodCalendarScreen> {
  late DateTime _month; // first day of the shown month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int by) {
    setState(() => _month = DateTime(_month.year, _month.month + by));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final moods = ref.watch(moodByDateProvider);
    final today = DateTime.now();
    final todayKey = MoodEntry.keyFor(today);
    final todayMood = moods[todayKey];

    return Scaffold(
      appBar: AppBar(title: const Text('Mood calendar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _TodayCard(
            todayMood: todayMood?.mood,
            onPick: (m) => _pickMood(context, today, existing: todayMood),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MonthHeader(
            month: _month,
            onPrev: () => _shiftMonth(-1),
            onNext: _isCurrentMonth ? null : () => _shiftMonth(1),
          ),
          const SizedBox(height: AppSpacing.md),
          _CalendarGrid(
            month: _month,
            moods: moods,
            onTapDay: (day) => _pickMood(context, day,
                existing: moods[MoodEntry.keyFor(day)]),
          ),
          const SizedBox(height: AppSpacing.xl),
          _MonthSummary(month: _month, moods: moods),
          const SizedBox(height: AppSpacing.lg),
          const _Legend(),
        ],
      ),
    );
  }

  Future<void> _pickMood(BuildContext context, DateTime day,
      {MoodEntry? existing}) async {
    // No logging the future.
    final today = DateTime.now();
    if (day.isAfter(DateTime(today.year, today.month, today.day))) {
      context.showSnack("You can't set a mood for a future day.");
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MoodPickerSheet(day: day, existing: existing),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.todayMood, required this.onPick});
  final JournalMood? todayMood;
  final ValueChanged<JournalMood> onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            todayMood == null
                ? 'How are you feeling today?'
                : 'Today you feel ${todayMood!.label.toLowerCase()} ${todayMood!.emoji}',
            style: context.textStyles.titleMedium
                ?.copyWith(color: context.colors.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in JournalMood.values)
                _MoodBubble(
                  mood: m,
                  selected: todayMood == m,
                  onTap: () => onPick(m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble(
      {required this.mood, required this.selected, required this.onTap});
  final JournalMood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? moodColor(mood)
              : moodColor(mood).withValues(alpha: 0.22),
          border: selected
              ? Border.all(color: context.colors.onPrimaryContainer, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(mood.emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onPrev, this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            textAlign: TextAlign.center,
            style: context.textStyles.titleLarge,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right,
              color: onNext == null ? context.colors.outlineVariant : null),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid(
      {required this.month, required this.moods, required this.onTapDay});
  final DateTime month;
  final Map<String, MoodEntry> moods;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7; // Sun=0
    final today = DateTime.now();
    final todayKey = MoodEntry.keyFor(today);

    final cells = <Widget>[];
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final l in labels) {
      cells.add(Center(
        child: Text(l,
            style: context.textStyles.labelMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ));
    }
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final key = MoodEntry.keyFor(day);
      final mood = moods[key]?.mood;
      final isToday = key == todayKey;
      final isFuture = day.isAfter(DateTime(today.year, today.month, today.day));
      cells.add(_DayCell(
        day: d,
        mood: mood,
        isToday: isToday,
        isFuture: isFuture,
        onTap: isFuture ? null : () => onTapDay(day),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.mood,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });
  final int day;
  final JournalMood? mood;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasMood = mood != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasMood
              ? moodColor(mood!).withValues(alpha: 0.85)
              : context.colors.surfaceContainerHighest.withValues(
                  alpha: isFuture ? 0.25 : 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: isToday
              ? Border.all(color: context.colors.primary, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: hasMood
            ? Text(mood!.emoji, style: const TextStyle(fontSize: 18))
            : Text(
                '$day',
                style: context.textStyles.bodySmall?.copyWith(
                  color: isFuture
                      ? context.colors.outline
                      : context.colors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.month, required this.moods});
  final DateTime month;
  final Map<String, MoodEntry> moods;

  @override
  Widget build(BuildContext context) {
    final prefix =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final monthMoods =
        moods.values.where((m) => m.dateKey.startsWith(prefix)).toList();
    if (monthMoods.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.insights_outlined, color: context.colors.primary),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Tap any day to log your mood and build your journey.'),
            ),
          ],
        ),
      );
    }
    final counts = <JournalMood, int>{};
    for (final m in monthMoods) {
      counts[m.mood] = (counts[m.mood] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'This month'),
          Text('${monthMoods.length} days logged · mostly '
              '${top.key.label.toLowerCase()} ${top.key.emoji}'),
          const SizedBox(height: AppSpacing.md),
          for (final m in JournalMood.values)
            if ((counts[m] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(width: 56, child: Text(m.label)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (counts[m] ?? 0) / monthMoods.length,
                          minHeight: 8,
                          backgroundColor: context
                              .colors.surfaceContainerHighest,
                          color: moodColor(m),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${counts[m]}'),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final m in JournalMood.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.emoji),
              const SizedBox(width: 4),
              Text(m.label, style: context.textStyles.bodySmall),
            ],
          ),
      ],
    );
  }
}

class _MoodPickerSheet extends ConsumerStatefulWidget {
  const _MoodPickerSheet({required this.day, this.existing});
  final DateTime day;
  final MoodEntry? existing;

  @override
  ConsumerState<_MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends ConsumerState<_MoodPickerSheet> {
  JournalMood? _mood;
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');

  @override
  void initState() {
    super.initState();
    _mood = widget.existing?.mood;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: viewInsets + navInset + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('EEEE, d MMMM').format(widget.day),
              style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in JournalMood.values)
                _MoodBubble(
                  mood: m,
                  selected: _mood == m,
                  onTap: () => setState(() => _mood = m),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              hintText: 'Add a note (optional)',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (widget.existing != null)
                TextButton.icon(
                  onPressed: () async {
                    await ref
                        .read(moodActionsProvider)
                        ?.remove(widget.existing!.dateKey);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _mood == null
                    ? null
                    : () async {
                        await ref.read(moodActionsProvider)?.setMood(
                              widget.day,
                              _mood!,
                              note: _note.text.trim().isEmpty
                                  ? null
                                  : _note.text.trim(),
                            );
                        if (context.mounted) Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
