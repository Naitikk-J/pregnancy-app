import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai_tools/domain/ai_models.dart';
import '../../ai_tools/presentation/ai_tools_providers.dart';
import '../../ai_tools/presentation/widgets/ai_disclaimer.dart';
import '../../document_scan/presentation/scan_providers.dart';
import '../domain/symptom_entry.dart';
import 'symptom_providers.dart';

/// Symptom tracker: quick logging with severity, plus a recent history and a
/// simple 7-day frequency summary.
class SymptomsScreen extends ConsumerWidget {
  const SymptomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(symptomEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Symptoms')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logSymptom(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log symptom'),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load symptoms',
          message: '$e',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.healing_outlined,
              title: 'No symptoms logged',
              message: 'Log how you feel to spot patterns and share them with '
                  'your doctor.',
              actionLabel: 'Log symptom',
              onAction: () => _logSymptom(context, ref),
            );
          }
          final weekAgo =
              DateTime.now().subtract(const Duration(days: 7));
          final recent =
              entries.where((e) => e.loggedAt.isAfter(weekAgo)).toList();
          final counts = <String, int>{};
          for (final e in recent) {
            counts[e.type] = (counts[e.type] ?? 0) + 1;
          }
          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (sorted.isNotEmpty) ...[
                const SectionHeader(title: 'This week'),
                AppCard(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final entry in sorted)
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: context.colors.primary,
                            child: Text('${entry.value}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.onPrimary)),
                          ),
                          label: Text(entry.key),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionHeader(title: 'History'),
              Text('Tap a symptom for advice tailored to your stage.',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              for (final e in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _severityBadge(context, e.severity),
                  title: Text(e.type),
                  subtitle: Text(
                    '${DateFormat('EEE, d MMM · h:mm a').format(e.loggedAt)}'
                    '${e.note != null && e.note!.isNotEmpty ? '\n${e.note}' : ''}',
                  ),
                  isThreeLine: e.note != null && e.note!.isNotEmpty,
                  onTap: () => _advice(context, ref, e.type, e.note),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(symptomCrudProvider)?.delete(e.id),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _severityBadge(BuildContext context, int severity) {
    final color = severity <= 3
        ? context.colors.tertiary
        : severity <= 6
            ? context.colors.secondary
            : context.colors.error;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text('$severity',
          style: context.textStyles.labelLarge?.copyWith(color: color)),
    );
  }

  /// Personalised AI advice for a logged symptom — uses the mother's week,
  /// trimester and any conditions, so guidance differs per person.
  Future<void> _advice(
      BuildContext context, WidgetRef ref, String type, String? note) async {
    final future = ref.read(documentAiRepositoryProvider).symptomCheck(
          symptom: (note != null && note.isNotEmpty) ? '$type — $note' : type,
          context: ref.read(aiContextProvider),
        );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AdviceSheet(symptom: type, future: future),
    );
  }

  Future<void> _logSymptom(BuildContext context, WidgetRef ref) async {
    final selected = <String>{};
    final customController = TextEditingController();
    var severity = 5.0;
    final noteController = TextEditingController();

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
                Text('Log symptoms', style: ctx.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('Select all you feel — they share the severity and note.',
                    style: ctx.textStyles.bodySmall
                        ?.copyWith(color: ctx.colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final s in kCommonSymptoms)
                      FilterChip(
                        label: Text(s),
                        selected: selected.contains(s),
                        onSelected: (on) => setState(
                            () => on ? selected.add(s) : selected.remove(s)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Add another symptom (optional)',
                  controller: customController,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Severity: ${severity.round()} / 10',
                    style: ctx.textStyles.titleSmall),
                Slider(
                  value: severity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${severity.round()}',
                  onChanged: (v) => setState(() => severity = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Note (optional)',
                  controller: noteController,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save',
                  onPressed: () {
                    if (selected.isEmpty &&
                        customController.text.trim().isEmpty) {
                      ctx.showSnack('Pick at least one symptom.', isError: true);
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

    if (saved == true) {
      final types = <String>{
        ...selected,
        if (customController.text.trim().isNotEmpty) customController.text.trim(),
      };
      final crud = ref.read(symptomCrudProvider);
      final now = DateTime.now();
      final note = noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim();
      // One entry per selected symptom so the history and weekly counts stay
      // per-symptom, all sharing this moment's severity and note.
      for (final type in types) {
        await crud?.upsert(
          SymptomEntry(
            id: const Uuid().v4(),
            type: type,
            severity: severity.round(),
            loggedAt: now,
            note: note,
          ),
        );
      }
    }
    customController.dispose();
    noteController.dispose();
  }
}

/// Bottom sheet showing context-aware AI advice for one symptom.
class _AdviceSheet extends StatelessWidget {
  const _AdviceSheet({required this.symptom, required this.future});
  final String symptom;
  final Future<SymptomCheck> future;

  @override
  Widget build(BuildContext context) {
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + navInset),
        child: FutureBuilder<SymptomCheck>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text('Checking this for your stage…'),
                  ]),
                ),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  snap.error is StateError
                      ? (snap.error as StateError).message
                      : 'Could not get advice right now. Please try again.',
                  style: TextStyle(color: context.colors.error),
                ),
              );
            }
            final c = snap.data!;
            return ListView(
              shrinkWrap: true,
              children: [
                if (c.isUrgent)
                  _banner(context, context.colors.error,
                      context.colors.onError, Icons.emergency,
                      'This can be serious — contact your doctor or emergency '
                      'services now.', onTap: () {
                    Navigator.pop(context);
                    context.pushNamed(AppRoutes.emergencyName);
                  })
                else if (c.callSoon)
                  _banner(
                      context,
                      context.colors.tertiaryContainer,
                      context.colors.onTertiaryContainer,
                      Icons.call_outlined,
                      'Worth mentioning to your doctor soon.'),
                const SizedBox(height: AppSpacing.sm),
                Text(symptom, style: context.textStyles.titleLarge),
                if (c.whatItMeans.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(c.whatItMeans, style: context.textStyles.bodyMedium),
                ],
                _list(context, '🌿 What can help', c.selfCare),
                _list(context, '⚠️ Get care if', c.seekCareIf),
                const SizedBox(height: AppSpacing.md),
                AiDisclaimer(c.disclaimer),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _banner(BuildContext context, Color bg, Color fg, IconData icon,
      String text,
      {VoidCallback? onTap}) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            Icon(icon, color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(text,
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: fg, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(title, style: context.textStyles.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: AppSpacing.sm),
                child:
                    Icon(Icons.circle, size: 6, color: context.colors.primary),
              ),
              Expanded(child: Text(it, style: context.textStyles.bodyMedium)),
            ]),
          ),
      ],
    );
  }
}
