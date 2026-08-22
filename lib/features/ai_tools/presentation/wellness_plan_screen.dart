import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../document_scan/presentation/scan_providers.dart';
import '../domain/ai_models.dart';
import 'ai_tools_providers.dart';
import 'widgets/ai_disclaimer.dart';
import 'widgets/breathing_animation.dart';

/// Personalised, safe prenatal yoga + light exercise, tailored to the trimester
/// and any health conditions, with a guided breathing animation.
class WellnessPlanScreen extends ConsumerStatefulWidget {
  const WellnessPlanScreen({super.key});

  @override
  ConsumerState<WellnessPlanScreen> createState() =>
      _WellnessPlanScreenState();
}

class _WellnessPlanScreenState extends ConsumerState<WellnessPlanScreen> {
  bool _busy = false;
  String? _error;
  WellnessPlan? _plan;

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final plan = await ref
          .read(documentAiRepositoryProvider)
          .wellnessPlan(context: ref.read(aiContextProvider));
      if (mounted) setState(() => _plan = plan);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is StateError
            ? e.message
            : 'Could not create the plan. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yoga & movement')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // A calming, guided breathing animation (always available).
          AppCard(
            child: Column(
              children: [
                Text('Guided breathing',
                    style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                const BreathingAnimation(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_plan == null && !_busy) ...[
            Text(
              'Get gentle yoga poses and light exercises chosen for your '
              'trimester and health — with simple steps and things to avoid.',
              style: context.textStyles.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              AppCard(
                color: context.colors.errorContainer,
                child: Text(_error!,
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.colors.onErrorContainer)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppButton(
              label: 'Suggest my plan',
              icon: Icons.self_improvement,
              onPressed: _generate,
            ),
          ],

          if (_busy) const LoadingView(message: 'Preparing gentle movements…'),

          if (_plan != null) ..._result(_plan!),
        ],
      ),
    );
  }

  List<Widget> _result(WellnessPlan p) => [
        if (p.focus.isNotEmpty)
          AppCard(
            color: context.colors.secondaryContainer,
            child: Row(
              children: [
                Icon(Icons.spa_outlined,
                    color: context.colors.onSecondaryContainer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(p.focus,
                      style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSecondaryContainer)),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (p.yoga.isNotEmpty) ...[
          Text('Yoga', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final y in p.yoga) _yogaTile(y),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (p.exercises.isNotEmpty) ...[
          Text('Light exercise', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final e in p.exercises) _exerciseTile(e),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (p.healthTips.isNotEmpty) ...[
          Text('Ways to feel better', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final t in p.healthTips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text('• $t', style: context.textStyles.bodyMedium),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (p.avoid.isNotEmpty)
          AppCard(
            color: context.colors.errorContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.block, size: 18, color: context.colors.onErrorContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Avoid',
                      style: context.textStyles.titleSmall
                          ?.copyWith(color: context.colors.onErrorContainer)),
                ]),
                const SizedBox(height: AppSpacing.xs),
                for (final a in p.avoid)
                  Text('• $a',
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: context.colors.onErrorContainer)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        AiDisclaimer(p.disclaimer),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Regenerate',
          icon: Icons.refresh,
          variant: AppButtonVariant.tonal,
          onPressed: _generate,
        ),
        const SizedBox(height: AppSpacing.xl),
      ];

  Widget _yogaTile(YogaPose y) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ExpansionTile(
          leading: Icon(Icons.self_improvement, color: context.colors.primary),
          title: Text(y.name, style: context.textStyles.titleSmall),
          subtitle: y.benefit.isEmpty ? null : Text(y.benefit),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < y.steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${i + 1}. ${y.steps[i]}',
                    style: context.textStyles.bodyMedium),
              ),
            if (y.caution.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Caution: ${y.caution}',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.error)),
            ],
          ],
        ),
      );

  Widget _exerciseTile(ExerciseItem e) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e.name, style: context.textStyles.titleSmall),
                  ),
                  if (e.minutes > 0)
                    Text('${e.minutes} min',
                        style: context.textStyles.labelMedium
                            ?.copyWith(color: context.colors.primary)),
                ],
              ),
              if (e.benefit.isNotEmpty)
                Text(e.benefit,
                    style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant)),
              if (e.howTo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(e.howTo, style: context.textStyles.bodyMedium),
              ],
            ],
          ),
        ),
      );
}
