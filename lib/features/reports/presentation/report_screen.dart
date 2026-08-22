import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pregnancy_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../contractions/presentation/contraction_providers.dart';
import '../../kick_counter/presentation/kick_counter_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/report_builder.dart';
import 'report_view.dart';

/// A combined, shareable summary of kick-counter and contraction activity.
/// Exports as plain text the mother can copy or email to her doctor — no PDF
/// tooling required, and it works fully offline.
class MovementReportScreen extends ConsumerWidget {
  const MovementReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kicks = ref.watch(kickSessionsProvider).valueOrNull ?? const [];
    final contractions =
        ref.watch(contractionsProvider).valueOrNull ?? const [];
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;

    final currentWeek = pregnancy == null
        ? null
        : PregnancyCalculator.currentWeek(pregnancy.lmpDate);

    final report = ReportBuilder.build(
      generatedAt: DateTime.now(),
      kickSessions: kicks,
      contractions: contractions,
      motherName: profile?.name,
      currentWeek: currentWeek,
      dueDate: pregnancy?.dueDate,
    );

    final hasData = kicks.any((s) => s.isComplete) ||
        contractions.any((c) => c.isComplete);

    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: hasData
          ? ReportView(
              report: report,
              emailSubject: 'My pregnancy movement & contraction report',
            )
          : const EmptyState(
              icon: Icons.assessment_outlined,
              title: 'Nothing to report yet',
              message: 'Once you record kick sessions or time contractions, a '
                  'shareable summary appears here.',
            ),
    );
  }
}
