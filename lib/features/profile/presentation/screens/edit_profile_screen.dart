import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../controllers/profile_providers.dart';

const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

/// Lets the mother edit her saved medical & personal profile
/// (`users/{uid}/profile/main`). Pre-fills from the current profile and saves
/// via [ProfileRepository.updateProfile]. Fields not shown here (medical
/// conditions, food preferences) are preserved untouched.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();

  String? _bloodGroup;
  int _previousPregnancies = 0;
  int _waterGoalMl = 2500;
  String _sleepTime = '22:30';
  String _wakeTime = '06:30';

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  /// Fill the form from the current profile (once).
  void _populate(UserProfile p) {
    _name.text = p.name;
    _age.text = p.age?.toString() ?? '';
    _weight.text = p.weightKg?.toString() ?? '';
    _height.text = p.heightCm?.toString() ?? '';
    _bloodGroup = p.bloodGroup;
    _previousPregnancies = p.previousPregnancies;
    _waterGoalMl = p.waterGoalMl;
    _sleepTime = p.sleepTime;
    _wakeTime = p.wakeTime;
  }

  TimeOfDay _parse(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool sleep}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(sleep ? _sleepTime : _wakeTime),
    );
    if (picked != null) {
      setState(() {
        if (sleep) {
          _sleepTime = _fmt(picked);
        } else {
          _wakeTime = _fmt(picked);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      context.showSnack('You are not signed in.', isError: true);
      return;
    }
    setState(() => _saving = true);

    // Preserve fields this screen doesn't edit.
    final base =
        ref.read(userProfileProvider).valueOrNull ?? const UserProfile(name: '');
    final updated = UserProfile(
      name: _name.text.trim(),
      age: int.tryParse(_age.text.trim()),
      weightKg: double.tryParse(_weight.text.trim()),
      heightCm: double.tryParse(_height.text.trim()),
      bloodGroup: _bloodGroup,
      medicalConditions: base.medicalConditions,
      previousPregnancies: _previousPregnancies,
      foodPreferences: base.foodPreferences,
      waterGoalMl: _waterGoalMl,
      sleepTime: _sleepTime,
      wakeTime: _wakeTime,
    );

    try {
      await ref.read(profileRepositoryProvider).updateProfile(uid, updated);
      if (mounted) {
        context.showSnack('Profile updated.');
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
    final async = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Could not load profile.\n$e')),
        data: (p) {
          if (!_initialized) {
            _populate(p ?? const UserProfile(name: ''));
            _initialized = true;
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                  AppSpacing.lg, AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom),
              children: [
                AppTextField(
                  label: 'Name',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Age',
                        controller: _age,
                        prefixIcon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Weight (kg)',
                        controller: _weight,
                        prefixIcon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Height (cm)',
                  controller: _height,
                  prefixIcon: Icons.height,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Blood group ---
                Text('Blood group', style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final bg in _bloodGroups)
                      ChoiceChip(
                        label: Text(bg),
                        selected: _bloodGroup == bg,
                        onSelected: (_) => setState(
                          () => _bloodGroup = _bloodGroup == bg ? null : bg,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Previous pregnancies ---
                Row(
                  children: [
                    Expanded(
                      child: Text('Previous pregnancies',
                          style: context.textStyles.titleSmall),
                    ),
                    IconButton.filledTonal(
                      onPressed: _previousPregnancies > 0
                          ? () => setState(() => _previousPregnancies--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('$_previousPregnancies',
                          style: context.textStyles.titleMedium),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _previousPregnancies++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Daily water goal ---
                Text('Daily water goal · $_waterGoalMl ml',
                    style: context.textStyles.titleSmall),
                Slider(
                  value: _waterGoalMl.clamp(1000, 4000).toDouble(),
                  min: 1000,
                  max: 4000,
                  divisions: 30,
                  label: '$_waterGoalMl ml',
                  onChanged: (v) =>
                      setState(() => _waterGoalMl = (v / 100).round() * 100),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Sleep & wake times ---
                Row(
                  children: [
                    Expanded(
                      child: _TimeTile(
                        label: 'Sleep time',
                        value: _sleepTime,
                        icon: Icons.bedtime_outlined,
                        onTap: () => _pickTime(sleep: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _TimeTile(
                        label: 'Wake time',
                        value: _wakeTime,
                        icon: Icons.wb_sunny_outlined,
                        onTap: () => _pickTime(sleep: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: 'Save changes',
                  icon: Icons.check,
                  isLoading: _saving,
                  onPressed: _saving ? () {} : _save,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(label,
                      style: context.textStyles.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: context.textStyles.titleMedium),
          ],
        ),
      ),
    );
  }
}
