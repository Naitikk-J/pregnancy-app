import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../document_scan/domain/scan_models.dart';
import '../../document_scan/presentation/scan_providers.dart';

/// Central hub for everything report-related: visual insights, a shareable
/// health report (with PDF export), prescription scanning, lab-report analysis,
/// the movement report, and the device-local history of past scans.
class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Insights')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Visualise & share'),
          _NavCard(
            icon: Icons.insights_outlined,
            title: 'Health insights',
            subtitle: 'Charts of your weight, BP, sugar and sleep',
            onTap: () => context.pushNamed(AppRoutes.insightsName),
          ),
          _NavCard(
            icon: Icons.summarize_outlined,
            title: 'Health report',
            subtitle: 'View, export as PDF, copy or email to your doctor',
            onTap: () => context.pushNamed(AppRoutes.healthReportName),
          ),
          _NavCard(
            icon: Icons.child_care_outlined,
            title: 'Movement report',
            subtitle: 'Kick counts & contraction summary',
            onTap: () => context.pushNamed(AppRoutes.movementReportName),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Scan & analyse'),
          _NavCard(
            icon: Icons.document_scanner_outlined,
            title: 'Scan prescription',
            subtitle: 'Photo/PDF → auto-fill medicines & timings',
            onTap: () => context.pushNamed(AppRoutes.prescriptionScanName),
          ),
          _NavCard(
            icon: Icons.biotech_outlined,
            title: 'Analyze lab report',
            subtitle: 'Understand your test results in simple language',
            onTap: () => context.pushNamed(AppRoutes.labAnalysisName),
          ),

          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Recent scans (on this device)'),
            for (final r in history)
              _ScanTile(
                record: r,
                onView: () => _view(context, r),
                onDelete: () async {
                  await ref.read(localScanStoreProvider).deleteRecord(r.id);
                  ref.invalidate(scanHistoryProvider);
                },
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _view(BuildContext context, ScanRecord r) {
    final file = File(r.imagePath);
    if (!file.existsSync()) {
      context.showSnack('That scan file is no longer on this device.',
          isError: true);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(r.title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: r.imagePath.toLowerCase().endsWith('.pdf')
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('PDF saved on this device.'),
                    )
                  : InteractiveViewer(child: Image.file(file)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 28, color: context.colors.primary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({
    required this.record,
    required this.onView,
    required this.onDelete,
  });

  final ScanRecord record;
  final VoidCallback onView;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final isPrescription = record.type == 'prescription';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onView,
        child: Row(
          children: [
            Icon(
              isPrescription
                  ? Icons.medication_outlined
                  : Icons.biotech_outlined,
              color: context.colors.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.title, style: context.textStyles.titleSmall),
                  Text(
                    '${DateFormat('d MMM yyyy, HH:mm').format(record.createdAt)}'
                    '${record.summary.isNotEmpty ? ' · ${record.summary}' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
