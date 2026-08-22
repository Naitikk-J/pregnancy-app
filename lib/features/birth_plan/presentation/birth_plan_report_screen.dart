import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/controllers/profile_providers.dart';
import '../../reports/presentation/report_view.dart';
import '../domain/birth_plan.dart';
import '../domain/birth_plan_builder.dart';

/// Renders a birth plan as a shareable text summary (copy or email), reusing
/// the shared report view.
class BirthPlanReportScreen extends ConsumerWidget {
  const BirthPlanReportScreen({required this.plan, super.key});

  final BirthPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final report = BirthPlanBuilder.build(plan, motherName: profile?.name);

    return Scaffold(
      appBar: AppBar(title: const Text('Birth plan')),
      body: ReportView(
        report: report,
        emailSubject: 'My birth plan',
      ),
    );
  }
}
