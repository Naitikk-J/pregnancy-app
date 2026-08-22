import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/scan_models.dart';
import 'document_picker.dart';
import 'scan_providers.dart';

/// Upload a lab / test report (photo or PDF) and get a plain-language
/// explanation with out-of-range values flagged. Educational only — never a
/// diagnosis; the mother is always pointed back to her doctor.
class LabAnalysisScreen extends ConsumerStatefulWidget {
  const LabAnalysisScreen({super.key});

  @override
  ConsumerState<LabAnalysisScreen> createState() => _LabAnalysisScreenState();
}

class _LabAnalysisScreenState extends ConsumerState<LabAnalysisScreen> {
  static const _uuid = Uuid();

  bool _busy = false;
  String? _error;
  LabAnalysis? _analysis;

  Future<void> _pickAndAnalyze() async {
    final doc = await DocumentPicker.pick(context);
    if (doc == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final analysis = await ref
          .read(documentAiRepositoryProvider)
          .analyzeLab(bytes: doc.bytes, mimeType: doc.mimeType);

      final id = _uuid.v4();
      final path = await ref.read(localScanStoreProvider).saveImage(
            id: id,
            bytes: doc.bytes,
            extension: doc.extension,
          );
      await ref.read(localScanStoreProvider).addRecord(ScanRecord(
            id: id,
            type: 'lab',
            createdAt: DateTime.now(),
            imagePath: path,
            title: analysis.reportType.isEmpty ? 'Lab report' : analysis.reportType,
            summary: analysis.summary,
          ));
      ref.invalidate(scanHistoryProvider);

      if (mounted) setState(() => _analysis = analysis);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e is StateError ? e.message : 'Could not analyze the report.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyze lab report')),
      body: _busy
          ? const LoadingView(message: 'Reading your report…')
          : _analysis != null
              ? _buildResult(_analysis!)
              : _buildIntro(),
    );
  }

  Widget _buildIntro() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          color: context.colors.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.biotech_outlined,
                  size: 40, color: context.colors.onPrimaryContainer),
              const SizedBox(height: AppSpacing.sm),
              Text('Understand your lab report',
                  style: context.textStyles.titleLarge
                      ?.copyWith(color: context.colors.onPrimaryContainer)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Upload a blood test, urine test or scan report — as a photo or a '
                'PDF — and we\'ll explain the values in simple language and flag '
                'anything to review with your doctor.',
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          _note(context.colors.errorContainer, context.colors.onErrorContainer,
              Icons.error_outline, _error!),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppButton(
          label: 'Choose photo or PDF',
          icon: Icons.upload_file_outlined,
          onPressed: _pickAndAnalyze,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'This is an educational aid, not a medical diagnosis. Always confirm '
          'results and next steps with your doctor.',
          style: context.textStyles.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildResult(LabAnalysis a) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (a.urgent)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _note(
              context.colors.errorContainer,
              context.colors.onErrorContainer,
              Icons.warning_amber_rounded,
              'Some values may need prompt attention. Please contact your '
              'doctor soon.',
            ),
          ),
        Text(a.reportType, style: context.textStyles.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (a.summary.isNotEmpty)
          AppCard(
            child: Text(a.summary, style: context.textStyles.bodyMedium),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (a.findings.isNotEmpty) ...[
          Text('Values', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final f in a.findings) _FindingTile(finding: f),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (a.recommendations.isNotEmpty) ...[
          Text('Suggestions', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in a.recommendations)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $r', style: context.textStyles.bodyMedium),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _note(context.colors.surfaceContainerHighest, context.colors.onSurfaceVariant,
            Icons.info_outline, a.disclaimer),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Analyze another',
          icon: Icons.refresh,
          variant: AppButtonVariant.tonal,
          onPressed: () => setState(() => _analysis = null),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _note(Color bg, Color fg, IconData icon, String text) {
    return AppCard(
      color: bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: context.textStyles.bodyMedium?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.finding});
  final LabFinding finding;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (finding.status) {
      'high' => (Colors.red, 'High'),
      'low' => (Colors.orange, 'Low'),
      'borderline' => (Colors.amber, 'Borderline'),
      'normal' => (Colors.green, 'Normal'),
      _ => (context.colors.outline, '—'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(finding.name,
                      style: context.textStyles.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(label,
                      style: context.textStyles.labelSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [
                if (finding.value.isNotEmpty)
                  '${finding.value}${finding.unit.isNotEmpty ? ' ${finding.unit}' : ''}',
                if (finding.referenceRange.isNotEmpty)
                  'ref: ${finding.referenceRange}',
              ].join('  ·  '),
              style: context.textStyles.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            if (finding.note.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(finding.note, style: context.textStyles.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
