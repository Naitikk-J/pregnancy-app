import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../document_scan/presentation/scan_providers.dart';
import '../domain/ai_models.dart';
import 'widgets/ai_disclaimer.dart';

/// Checks the mother's current medicines for well-known interactions and
/// pregnancy cautions. Educational only.
Future<void> showInteractionCheckSheet(
  BuildContext context, {
  required List<String> medicines,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _InteractionSheet(medicines: medicines),
  );
}

class _InteractionSheet extends ConsumerStatefulWidget {
  const _InteractionSheet({required this.medicines});
  final List<String> medicines;

  @override
  ConsumerState<_InteractionSheet> createState() => _InteractionSheetState();
}

class _InteractionSheetState extends ConsumerState<_InteractionSheet> {
  late Future<InteractionReport> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(documentAiRepositoryProvider)
        .interactions(medicines: widget.medicines);
  }

  Color _severityColor(String s) => switch (s) {
        'high' => Colors.red,
        'moderate' => Colors.orange,
        _ => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, controller) => FutureBuilder<InteractionReport>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: LoadingView(message: 'Checking interactions…'),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Couldn\'t check',
                message: snap.error is StateError
                    ? (snap.error as StateError).message
                    : 'Please try again.',
              ),
            );
          }
          final r = snap.data!;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            children: [
              Row(
                children: [
                  Icon(Icons.medication_liquid_outlined,
                      color: context.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Interaction check',
                      style: context.textStyles.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Checked: ${widget.medicines.join(', ')}',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              if (r.pairs.isEmpty)
                AppCard(
                  color: context.colors.secondaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: context.colors.onSecondaryContainer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'No notable interactions were flagged.',
                          style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final p in r.pairs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('${p.a} + ${p.b}',
                                    style: context.textStyles.titleSmall),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _severityColor(p.severity)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill),
                                ),
                                child: Text(p.severity.toUpperCase(),
                                    style: context.textStyles.labelSmall
                                        ?.copyWith(
                                            color: _severityColor(p.severity),
                                            fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          if (p.note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(p.note, style: context.textStyles.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
              if (r.generalNotes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final n in r.generalNotes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text('• $n', style: context.textStyles.bodyMedium),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              AiDisclaimer(r.disclaimer),
            ],
          );
        },
      ),
    );
  }
}
