import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/journal_entry.dart';
import 'journal_providers.dart';

/// Pregnancy journal: dated entries with a mood, optional title and free text.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New entry'),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load journal',
          message: '$e',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Your journal is empty',
              message: 'Capture how you feel and the little moments — you’ll '
                  'love looking back.',
              actionLabel: 'New entry',
              onAction: () => _addEntry(context, ref),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final e in entries)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(e.mood.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              e.title?.isNotEmpty == true
                                  ? e.title!
                                  : e.mood.label,
                              style: context.textStyles.titleSmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                ref.read(journalCrudProvider)?.delete(e.id),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('EEE, d MMM yyyy · HH:mm').format(e.loggedAt),
                        style: context.textStyles.bodySmall
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      if (e.text.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(e.text, style: context.textStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final text = TextEditingController();
    var mood = JournalMood.okay;

    final ok = await showModalBottomSheet<bool>(
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
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New journal entry', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text('How are you feeling?', style: ctx.textStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final m in JournalMood.values)
                    GestureDetector(
                      onTap: () => setState(() => mood = m),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: mood == m
                                ? ctx.colors.primaryContainer
                                : ctx.colors.surfaceContainerHighest,
                            child: Text(m.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(m.label, style: ctx.textStyles.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Title (optional)',
                controller: title,
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Write something…',
                controller: text,
                prefixIcon: Icons.notes,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Save', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      final body = text.text.trim();
      final heading = title.text.trim();
      if (body.isNotEmpty || heading.isNotEmpty) {
        await ref.read(journalCrudProvider)?.upsert(
              JournalEntry(
                id: const Uuid().v4(),
                loggedAt: DateTime.now(),
                text: body,
                mood: mood,
                title: heading.isEmpty ? null : heading,
              ),
            );
      }
    }
    title.dispose();
    text.dispose();
  }
}
