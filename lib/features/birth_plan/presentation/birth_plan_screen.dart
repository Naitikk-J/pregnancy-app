import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/birth_plan.dart';
import 'birth_plan_providers.dart';
import 'birth_plan_report_screen.dart';

/// Editable birth-plan form. Preferences save to the pregnancy and can be
/// exported as a shareable text summary for the care team.
class BirthPlanScreen extends ConsumerStatefulWidget {
  const BirthPlanScreen({super.key});

  @override
  ConsumerState<BirthPlanScreen> createState() => _BirthPlanScreenState();
}

class _BirthPlanScreenState extends ConsumerState<BirthPlanScreen> {
  BirthPlan _draft = const BirthPlan();
  bool _seeded = false;
  bool _saving = false;

  final _companion = TextEditingController();
  final _environment = TextEditingController();
  final _requests = TextEditingController();

  @override
  void dispose() {
    _companion.dispose();
    _environment.dispose();
    _requests.dispose();
    super.dispose();
  }

  void _seed(BirthPlan plan) {
    _draft = plan;
    _companion.text = plan.companion;
    _environment.text = plan.environmentNotes;
    _requests.text = plan.specialRequests;
    _seeded = true;
  }

  BirthPlan get _current => _draft.copyWith(
        companion: _companion.text,
        environmentNotes: _environment.text,
        specialRequests: _requests.text,
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(saveBirthPlanProvider)(_current);
      if (mounted) context.showSnack('Birth plan saved.');
    } catch (_) {
      if (mounted) {
        context.showSnack('Could not save. Start a pregnancy first.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(birthPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth plan'),
        actions: [
          IconButton(
            tooltip: 'Preview & share',
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BirthPlanReportScreen(plan: _current),
              ),
            ),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load your plan',
          message: '$e',
        ),
        data: (plan) {
          if (!_seeded) _seed(plan);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'A birth plan shares your wishes with your care team. Nothing '
                'here is fixed — your doctor will always prioritise safety.',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Delivery'),
              _ChoiceRow<BirthType>(
                label: 'Preferred birth',
                value: _draft.birthType,
                values: BirthType.values,
                labelOf: (v) => v.label,
                onChanged: (v) => setState(() =>
                    _draft = _draft.copyWith(birthType: v)),
              ),
              _ChoiceRow<PainPreference>(
                label: 'Pain management',
                value: _draft.painPreference,
                values: PainPreference.values,
                labelOf: (v) => v.label,
                onChanged: (v) => setState(() =>
                    _draft = _draft.copyWith(painPreference: v)),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Birth companion (who’s with you)',
                controller: _companion,
                prefixIcon: Icons.people_outline,
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'After birth'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Immediate skin-to-skin'),
                value: _draft.skinToSkin,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(skinToSkin: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Delayed cord clamping'),
                value: _draft.delayedCordClamping,
                onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(delayedCordClamping: v)),
              ),
              _ChoiceRow<FeedingPreference>(
                label: 'Feeding',
                value: _draft.feeding,
                values: FeedingPreference.values,
                labelOf: (v) => v.label,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(feeding: v)),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Environment & comfort'),
              AppTextField(
                label: 'Lighting, music, movement…',
                controller: _environment,
                prefixIcon: Icons.spa_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Special requests'),
              AppTextField(
                label: 'Anything else your team should know',
                controller: _requests,
                prefixIcon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Save birth plan',
                icon: Icons.save_outlined,
                isLoading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: context.textStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(labelOf(v)),
                selected: v == value,
                onSelected: (_) => onChanged(v),
              ),
          ],
        ),
      ],
    );
  }
}
