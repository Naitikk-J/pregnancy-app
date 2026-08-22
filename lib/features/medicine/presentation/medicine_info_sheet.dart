import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../document_scan/domain/scan_models.dart';
import '../../document_scan/presentation/scan_providers.dart';

/// Shows an AI-generated, educational explanation of a medicine — what it's for
/// and common side effects — in a bottom sheet. Never medical advice.
Future<void> showMedicineInfoSheet(
  BuildContext context, {
  required String name,
  String? dosage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MedicineInfoSheet(name: name, dosage: dosage),
  );
}

class _MedicineInfoSheet extends ConsumerStatefulWidget {
  const _MedicineInfoSheet({required this.name, this.dosage});
  final String name;
  final String? dosage;

  @override
  ConsumerState<_MedicineInfoSheet> createState() => _MedicineInfoSheetState();
}

class _MedicineInfoSheetState extends ConsumerState<_MedicineInfoSheet> {
  late Future<MedicineInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(documentAiRepositoryProvider)
        .medicineInfo(name: widget.name, dosage: widget.dosage);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) => FutureBuilder<MedicineInfo>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: LoadingView(message: 'Looking up this medicine…'),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Couldn\'t load info',
                message: snap.error is StateError
                    ? (snap.error as StateError).message
                    : 'Please check your connection and try again.',
              ),
            );
          }
          final info = snap.data!;
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            children: [
              Row(
                children: [
                  Icon(Icons.medication_outlined, color: context.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(info.name.isEmpty ? widget.name : info.name,
                        style: context.textStyles.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (info.uses.isNotEmpty) _section(context, 'What it\'s for', info.uses),
              if (info.howItWorks.isNotEmpty)
                _section(context, 'How it works', info.howItWorks),
              if (info.commonSideEffects.isNotEmpty)
                _bullets(context, 'Common side effects', info.commonSideEffects,
                    Icons.report_gmailerrorred_outlined),
              if (info.pregnancyNote.isNotEmpty)
                _card(context, context.colors.secondaryContainer,
                    context.colors.onSecondaryContainer,
                    Icons.pregnant_woman, 'In pregnancy', info.pregnancyNote),
              if (info.whenToCallDoctor.isNotEmpty)
                _bullets(context, 'Call your doctor if', info.whenToCallDoctor,
                    Icons.call_outlined),
              const SizedBox(height: AppSpacing.md),
              Text(
                info.disclaimer,
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textStyles.titleSmall),
            const SizedBox(height: 2),
            Text(body, style: context.textStyles.bodyMedium),
          ],
        ),
      );

  Widget _bullets(
          BuildContext context, String title, List<String> items, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: context.textStyles.titleSmall),
            ]),
            const SizedBox(height: AppSpacing.xs),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text('• $i', style: context.textStyles.bodyMedium),
              ),
          ],
        ),
      );

  Widget _card(BuildContext context, Color bg, Color fg, IconData icon,
          String title, String body) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
                Text(title,
                    style: context.textStyles.titleSmall?.copyWith(color: fg)),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text(body,
                  style: context.textStyles.bodyMedium?.copyWith(color: fg)),
            ],
          ),
        ),
      );
}
