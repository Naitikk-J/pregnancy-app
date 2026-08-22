import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/onboarding_controller.dart';

/// Multi-step wizard collecting the mother's profile and creating the first
/// pregnancy. On completion the account document flips to `onboardingComplete`,
/// and the router redirects to the home dashboard.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  static const _conditions = [
    'Diabetes', 'Hypertension', 'Thyroid', 'Anemia', 'Asthma',
    'PCOS', 'Heart condition', 'None'
  ];
  static const _foodPrefs = [
    'Vegetarian', 'Non-vegetarian', 'Vegan', 'Eggetarian',
  ];

  final _page = PageController();
  int _step = 0;
  bool _submitting = false;

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _doctor = TextEditingController();
  final _hospital = TextEditingController();

  static const _stepCount = 5;

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingControllerProvider);
    _name.text = d.name;
    _age.text = d.age?.toString() ?? '';
    _weight.text = d.weightKg?.toString() ?? '';
    _height.text = d.heightCm?.toString() ?? '';
    _doctor.text = d.doctorName ?? '';
    _hospital.text = d.hospital ?? '';
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _doctor.dispose();
    _hospital.dispose();
    super.dispose();
  }

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  /// Lets someone who signed in with the wrong account back out. Signs out of
  /// Google + Firebase (so the account picker reappears) and clears the draft;
  /// the router then redirects to the onboarding/login screen.
  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use a different account?'),
        content: const Text(
          'You’ll be signed out and can sign in again with the correct account. '
          'Nothing you’ve entered here is saved yet.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true) return;
    ref.invalidate(onboardingControllerProvider);
    await ref.read(authControllerProvider.notifier).signOut();
  }

  // Persist the free-text fields of the *current* step into the draft.
  void _syncTextIntoDraft() {
    _controller.update((d) => d.copyWith(
          name: _name.text.trim(),
          age: int.tryParse(_age.text.trim()),
          weightKg: double.tryParse(_weight.text.trim()),
          heightCm: double.tryParse(_height.text.trim()),
          doctorName: _doctor.text.trim(),
          hospital: _hospital.text.trim(),
        ));
  }

  String? _validateStep(int step, OnboardingDraft d) {
    switch (step) {
      case 0:
        if (_name.text.trim().isEmpty) {
          return 'Please enter your name.';
        }
      case 3:
        if (d.lmpDate == null) {
          return 'Please select your last period date or due date.';
        }
    }
    return null;
  }

  Future<void> _next() async {
    _syncTextIntoDraft();
    final draft = ref.read(onboardingControllerProvider);
    final error = _validateStep(_step, draft);
    if (error != null) {
      context.showSnack(error, isError: true);
      return;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      await _page.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      await _submit();
    }
  }

  Future<void> _back() async {
    if (_step == 0) return;
    setState(() => _step--);
    await _page.animateToPage(
      _step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _controller.submit();
      // Router redirects to home when onboardingComplete flips.
    } on Failure catch (f) {
      if (mounted) context.showSnack(f.message, isError: true);
    } catch (_) {
      if (mounted) {
        context.showSnack('Could not save. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_step + 1} of $_stepCount'),
        leading: _step == 0
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : _confirmSignOut,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _stepCount,
                  minHeight: 8,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepAboutYou(draft),
                  _stepBody(draft),
                  _stepHealth(draft),
                  _stepPregnancy(draft),
                  _stepLifestyle(draft),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: _step == _stepCount - 1 ? 'Finish' : 'Next',
                isLoading: _submitting,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepShell(String title, String subtitle, List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(title, style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle,
            style: context.textStyles.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xl),
        ...children,
      ],
    );
  }

  // ---- Step 1: About you ----
  Widget _stepAboutYou(OnboardingDraft d) => _stepShell(
        'About you',
        'Tell us who you are.',
        [
          AppTextField(
            label: 'Full name',
            controller: _name,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Age',
            controller: _age,
            prefixIcon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Your role', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              // Doctor/admin are provisioned out-of-band, not self-selected.
              for (final role in UserRole.values
                  .where((r) => r != UserRole.admin && r != UserRole.doctor))
                ChoiceChip(
                  label: Text(role.label),
                  selected: d.role == role,
                  onSelected: (_) =>
                      _controller.update((x) => x.copyWith(role: role)),
                ),
            ],
          ),
        ],
      );

  // ---- Step 2: Body ----
  Widget _stepBody(OnboardingDraft d) => _stepShell(
        'Your measurements',
        'Used to track healthy weight gain and BMI.',
        [
          AppTextField(
            label: 'Weight (kg)',
            controller: _weight,
            prefixIcon: Icons.monitor_weight_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Height (cm)',
            controller: _height,
            prefixIcon: Icons.height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Blood group', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final bg in _bloodGroups)
                ChoiceChip(
                  label: Text(bg),
                  selected: d.bloodGroup == bg,
                  onSelected: (_) =>
                      _controller.update((x) => x.copyWith(bloodGroup: bg)),
                ),
            ],
          ),
        ],
      );

  // ---- Step 3: Health ----
  Widget _stepHealth(OnboardingDraft d) => _stepShell(
        'Health history',
        'Helps personalise your guidance and risk alerts.',
        [
          Text('Medical conditions', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in _conditions)
                FilterChip(
                  label: Text(c),
                  selected: d.medicalConditions.contains(c),
                  onSelected: (_) => _controller.toggleCondition(c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Previous pregnancies', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _CounterRow(
            value: d.previousPregnancies,
            onChanged: (v) =>
                _controller.update((x) => x.copyWith(previousPregnancies: v)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Risk category', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final r in RiskCategory.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: d.riskCategory == r,
                  onSelected: (_) =>
                      _controller.update((x) => x.copyWith(riskCategory: r)),
                ),
            ],
          ),
        ],
      );

  // ---- Step 4: Pregnancy ----
  Widget _stepPregnancy(OnboardingDraft d) {
    final df = DateFormat('EEE, d MMM yyyy');
    return _stepShell(
      'Your pregnancy',
      'Pick your last period date so we can calculate your weeks.',
      [
        AppCard(
          onTap: _pickLmp,
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: context.colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last period (LMP)',
                        style: context.textStyles.bodySmall),
                    Text(
                      d.lmpDate == null ? 'Tap to select' : df.format(d.lmpDate!),
                      style: context.textStyles.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        if (d.lmpDate != null) ...[
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
                    'You are in week ${d.currentWeek}.\n'
                    'Estimated due date: ${df.format(d.dueDate!)}',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      ],
    );
  }

  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final initial = ref.read(onboardingControllerProvider).lmpDate ??
        now.subtract(const Duration(days: 56));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      helpText: 'Select your last menstrual period',
    );
    if (picked != null) {
      _controller.update((x) => x.copyWith(lmpDate: picked));
    }
  }

  // ---- Step 5: Lifestyle ----
  Widget _stepLifestyle(OnboardingDraft d) => _stepShell(
        'Daily routine',
        'We will time reminders around your day.',
        [
          Text('Food preference', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final f in _foodPrefs)
                ChoiceChip(
                  label: Text(f),
                  selected: d.foodPreferences.contains(f),
                  onSelected: (_) => _controller.setFoodPreference(f),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Daily water goal: ${(d.waterGoalMl / 1000).toStringAsFixed(2)} L',
              style: context.textStyles.titleSmall),
          Slider(
            value: d.waterGoalMl.toDouble(),
            min: 1000,
            max: 4000,
            divisions: 12,
            label: '${d.waterGoalMl} ml',
            onChanged: (v) =>
                _controller.update((x) => x.copyWith(waterGoalMl: v.round())),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TimeRow(
            label: 'Sleep time',
            icon: Icons.bedtime_outlined,
            value: d.sleepTime,
            onPick: (t) => _controller.update((x) => x.copyWith(sleepTime: t)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TimeRow(
            label: 'Wake time',
            icon: Icons.wb_sunny_outlined,
            value: d.wakeTime,
            onPick: (t) => _controller.update((x) => x.copyWith(wakeTime: t)),
          ),
        ],
      );
}

/// A +/- counter used for previous-pregnancies.
class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('$value', style: context.textStyles.titleLarge),
        ),
        IconButton.filledTonal(
          onPressed: value < 15 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// A row that opens a time picker and shows the selected "HH:mm".
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onPick,
  });

  final String label;
  final IconData icon;
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts.first) ?? 22,
          minute: int.tryParse(parts.last) ?? 0,
        );
        final picked =
            await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          onPick('${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Row(
        children: [
          Icon(icon, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.textStyles.titleMedium)),
          Text(value, style: context.textStyles.titleMedium),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
