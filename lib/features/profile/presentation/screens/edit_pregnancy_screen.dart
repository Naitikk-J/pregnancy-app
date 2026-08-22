import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/pregnancy_calculator.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/pregnancy.dart';
import '../controllers/profile_providers.dart';

/// Lets the mother correct her pregnancy dates and care details after
/// onboarding (`pregnancies/{id}`). Changing the last-period date recomputes the
/// estimated due date and the current week live. Saves via
/// [ProfileRepository.updatePregnancy].
class EditPregnancyScreen extends ConsumerStatefulWidget {
  const EditPregnancyScreen({super.key});

  @override
  ConsumerState<EditPregnancyScreen> createState() =>
      _EditPregnancyScreenState();
}

class _EditPregnancyScreenState extends ConsumerState<EditPregnancyScreen> {
  final _doctor = TextEditingController();
  final _hospital = TextEditingController();

  DateTime? _lmp;
  RiskCategory _risk = RiskCategory.low;

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _doctor.dispose();
    _hospital.dispose();
    super.dispose();
  }

  void _populate(Pregnancy p) {
    _lmp = p.lmpDate;
    _risk = p.riskCategory;
    _doctor.text = p.doctorName ?? '';
    _hospital.text = p.hospital ?? '';
  }

  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp ?? now.subtract(const Duration(days: 56)),
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      helpText: 'Select your last menstrual period',
    );
    if (picked != null) setState(() => _lmp = picked);
  }

  Future<void> _save(Pregnancy base) async {
    final lmp = _lmp;
    if (lmp == null) {
      context.showSnack('Please select your last period date.', isError: true);
      return;
    }
    setState(() => _saving = true);

    final lmpDateOnly = DateTime(lmp.year, lmp.month, lmp.day);
    final doctor = _doctor.text.trim();
    final hospital = _hospital.text.trim();

    final updated = Pregnancy(
      id: base.id,
      ownerUserId: base.ownerUserId,
      lmpDate: lmpDateOnly,
      dueDate: PregnancyCalculator.dueDateFromLmp(lmpDateOnly),
      riskCategory: _risk,
      doctorName: doctor.isEmpty ? null : doctor,
      hospital: hospital.isEmpty ? null : hospital,
      doctorUserId: base.doctorUserId,
      status: base.status,
      members: base.members,
      createdAt: base.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      await ref.read(profileRepositoryProvider).updatePregnancy(updated);
      if (mounted) {
        context.showSnack('Pregnancy details updated.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        context.showSnack('Could not save. Please try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activePregnancyProvider);
    final df = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Edit pregnancy')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Could not load pregnancy.\n$e')),
        data: (p) {
          if (p == null) {
            return const EmptyState(
              icon: Icons.pregnant_woman,
              title: 'No active pregnancy',
              message: 'Complete onboarding to set up your pregnancy first.',
            );
          }
          if (!_initialized) {
            _populate(p);
            _initialized = true;
          }

          final lmp = _lmp;
          final week =
              lmp == null ? null : PregnancyCalculator.currentWeek(lmp);
          final due =
              lmp == null ? null : PregnancyCalculator.dueDateFromLmp(lmp);

          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                AppSpacing.lg, AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              Text('Last period (LMP)', style: context.textStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                onTap: _pickLmp,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: context.colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        lmp == null ? 'Tap to select' : df.format(lmp),
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              if (lmp != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: context.colors.secondaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.pregnant_woman,
                          color: context.colors.onSecondaryContainer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'You are in week $week.\n'
                          'Estimated due date: ${df.format(due!)}',
                          style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              Text('Risk category', style: context.textStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final r in RiskCategory.values)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: _risk == r,
                      onSelected: (_) => setState(() => _risk = r),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Doctor name (optional)',
                controller: _doctor,
                prefixIcon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Hospital / clinic (optional)',
                controller: _hospital,
                prefixIcon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'Save changes',
                icon: Icons.check,
                isLoading: _saving,
                onPressed: _saving ? () {} : () => _save(p),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}
