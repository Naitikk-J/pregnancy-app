import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../document_scan/presentation/scan_providers.dart';
import '../domain/ai_models.dart';
import 'ai_tools_providers.dart';
import 'widgets/ai_disclaimer.dart';

/// "Is this normal?" — describe a symptom and get warm, safety-first guidance on
/// whether it's common in pregnancy and when to seek care. Never a diagnosis.
class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() =>
      _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;
  SymptomCheck? _result;

  static const _common = [
    'Morning sickness',
    'Back pain',
    'Swollen feet',
    'Heartburn',
    'Tiredness',
    'Headache',
    'Trouble sleeping',
    'Constipation',
    'Leg cramps',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final symptom = _ctrl.text.trim();
    if (symptom.isEmpty) {
      context.showSnack('Describe how you feel first.', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref.read(documentAiRepositoryProvider).symptomCheck(
            symptom: symptom,
            context: ref.read(aiContextProvider),
          );
      if (mounted) setState(() => _result = res);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is StateError ? e.message : 'Could not check that. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Is this normal?')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: 'Describe how you feel',
            controller: _ctrl,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in _common)
                ActionChip(
                  label: Text(s),
                  onPressed: () {
                    _ctrl.text = s;
                    _check();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Check',
            icon: Icons.health_and_safety_outlined,
            isLoading: _busy,
            onPressed: _busy ? () {} : _check,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            AppCard(
              color: context.colors.errorContainer,
              child: Text(_error!,
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.colors.onErrorContainer)),
            ),
          if (_result != null) _buildResult(_result!),
        ],
      ),
    );
  }

  Widget _buildResult(SymptomCheck r) {
    final (bg, fg, label, icon) = switch (r.urgency) {
      'urgent' => (
          context.colors.errorContainer,
          context.colors.onErrorContainer,
          'Seek care now',
          Icons.emergency_outlined
        ),
      'call_soon' => (
          context.colors.tertiaryContainer,
          context.colors.onTertiaryContainer,
          'Call your doctor soon',
          Icons.call_outlined
        ),
      _ => (
          context.colors.secondaryContainer,
          context.colors.onSecondaryContainer,
          r.isCommon ? 'Common in pregnancy' : 'Usually not urgent',
          Icons.check_circle_outline
        ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          color: bg,
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label,
                    style: context.textStyles.titleMedium?.copyWith(color: fg)),
              ),
            ],
          ),
        ),
        if (r.urgency == 'urgent') ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Open Emergency & SOS',
            icon: Icons.emergency,
            onPressed: () => context.pushNamed(AppRoutes.emergencyName),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (r.whatItMeans.isNotEmpty)
          AppCard(child: Text(r.whatItMeans, style: context.textStyles.bodyMedium)),
        if (r.selfCare.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('What can help', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          for (final s in r.selfCare)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text('• $s', style: context.textStyles.bodyMedium),
            ),
        ],
        if (r.seekCareIf.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('See a doctor if', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          for (final s in r.seekCareIf)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text('• $s', style: context.textStyles.bodyMedium),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        AiDisclaimer(r.disclaimer),
      ],
    );
  }
}
