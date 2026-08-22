import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/pregnancy_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../blood_pressure/presentation/bp_providers.dart';
import '../../blood_sugar/presentation/glucose_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../../sleep/presentation/sleep_providers.dart';
import '../../symptoms/presentation/symptom_providers.dart';
import '../../weight/presentation/weight_providers.dart';
import '../domain/health_pdf_builder.dart';
import '../domain/health_report_builder.dart';
import 'report_view.dart';

/// A combined, shareable health summary (BP, sugar, sleep, weight) for the
/// mother to copy or email to her doctor.
class HealthReportScreen extends ConsumerWidget {
  const HealthReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bp = ref.watch(bpReadingsProvider).valueOrNull ?? const [];
    final glucose = ref.watch(glucoseReadingsProvider).valueOrNull ?? const [];
    final sleep = ref.watch(sleepEntriesProvider).valueOrNull ?? const [];
    final weight = ref.watch(weightEntriesProvider).valueOrNull ?? const [];
    final symptoms = ref.watch(symptomEntriesProvider).valueOrNull ?? const [];
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;

    final currentWeek = pregnancy == null
        ? null
        : PregnancyCalculator.currentWeek(pregnancy.lmpDate);

    final hasData = bp.isNotEmpty ||
        glucose.isNotEmpty ||
        sleep.isNotEmpty ||
        weight.isNotEmpty ||
        symptoms.isNotEmpty;

    final report = HealthReportBuilder.build(
      generatedAt: DateTime.now(),
      bpReadings: bp,
      glucoseReadings: glucose,
      sleepEntries: sleep,
      weightEntries: weight,
      symptoms: symptoms,
      motherName: profile?.name,
      currentWeek: currentWeek,
      dueDate: pregnancy?.dueDate,
      heightCm: profile?.heightCm,
      baselineWeightKg: profile?.weightKg,
    );

    Future<void> exportPdf() async {
      try {
        final bytes = await HealthPdfBuilder.build(
          bp: bp,
          glucose: glucose,
          sleep: sleep,
          weight: weight,
          symptoms: symptoms,
          motherName: profile?.name,
          currentWeek: currentWeek,
          dueDate: pregnancy?.dueDate,
          heightCm: profile?.heightCm,
          baselineWeightKg: profile?.weightKg,
        );
        await Printing.sharePdf(bytes: bytes, filename: 'pregnancy-health-report.pdf');
      } catch (_) {
        if (context.mounted) {
          context.showSnack('Could not create the PDF.', isError: true);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health report'),
        actions: [
          if (hasData)
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: exportPdf,
            ),
        ],
      ),
      body: hasData
          ? ReportView(
              report: report,
              emailSubject: 'My pregnancy health report',
            )
          : const EmptyState(
              icon: Icons.assessment_outlined,
              title: 'Nothing to report yet',
              message: 'Log blood pressure, blood sugar, sleep, weight or '
                  'symptoms and a shareable summary with indicators appears here.',
            ),
    );
  }
}
