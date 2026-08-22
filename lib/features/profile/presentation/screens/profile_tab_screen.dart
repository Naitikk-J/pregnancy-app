import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../memories/presentation/memory_providers.dart';
import '../../../memories/presentation/photo_picker.dart';
import '../../../memories/presentation/user_avatar.dart';
import '../../../settings/ai_key_providers.dart';
import '../controllers/profile_providers.dart';

/// The Profile tab: account summary, pregnancy details, app settings
/// (theme / language / text size), legal links and account actions.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final settings = ref.watch(appSettingsProvider);
    final l10n = context.l10n;
    final df = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- Account header ---
          Row(
            children: [
              UserAvatar(
                name: profile?.name ?? user?.displayName ?? '?',
                radius: 32,
                showEditBadge: true,
                onTap: () => _changeAvatar(
                    context, ref, hasAvatar: ref.read(avatarPathProvider).valueOrNull != null),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.name ?? user?.displayName ?? l10n.profileYourProfile,
                        style: context.textStyles.titleLarge),
                    if (user?.email != null)
                      Text(user!.email!,
                          style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant)),
                    Text((user?.role ?? UserRole.mother).label,
                        style: context.textStyles.labelMedium
                            ?.copyWith(color: context.colors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.profileEditProfile,
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.outlined,
            onPressed: () => context.pushNamed(AppRoutes.editProfileName),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Pregnancy details ---
          if (pregnancy != null) ...[
            SectionHeader(title: l10n.sectionPregnancy),
            AppCard(
              child: Column(
                children: [
                  _row(context, l10n.fieldCurrentWeek,
                      l10n.weekLabel(pregnancy.currentWeek)),
                  _row(context, l10n.fieldDueDate, df.format(pregnancy.dueDate)),
                  _row(context, l10n.fieldRisk, pregnancy.riskCategory.label),
                  if (pregnancy.doctorName != null)
                    _row(context, l10n.fieldDoctor, pregnancy.doctorName!),
                  if (pregnancy.hospital != null)
                    _row(context, l10n.fieldHospital, pregnancy.hospital!),
                  if (profile?.bloodGroup != null)
                    _row(context, l10n.fieldBloodGroup, profile!.bloodGroup!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.profileEditPregnancy,
              icon: Icons.edit_calendar_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: () =>
                  context.pushNamed(AppRoutes.editPregnancyName),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // --- Appearance & language ---
          SectionHeader(title: l10n.sectionAppearance),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingTheme, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<AppThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: AppThemeMode.system, label: Text(l10n.themeSystem)),
                    ButtonSegment(
                        value: AppThemeMode.light, label: Text(l10n.themeLight)),
                    ButtonSegment(
                        value: AppThemeMode.dark, label: Text(l10n.themeDark)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(s.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.settingLanguage, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'hi', label: Text('हिन्दी')),
                  ],
                  selected: {settings.localeCode},
                  onSelectionChanged: (s) =>
                      ref.read(appSettingsProvider.notifier).setLocale(s.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.settingTextSize, style: context.textStyles.titleSmall),
                Slider(
                  value: settings.textScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  label: '${(settings.textScale * 100).round()}%',
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setTextScale(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- AI assistant (optional per-user key) ---
          const SectionHeader(title: 'AI assistant'),
          const _AiKeyCard(),
          const SizedBox(height: AppSpacing.xl),

          // --- Legal ---
          SectionHeader(title: l10n.sectionAbout),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.aboutPrivacy),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(AppConstants.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.aboutTerms),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(AppConstants.termsUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Account actions ---
          AppButton(
            label: l10n.actionSignOut,
            icon: Icons.logout,
            variant: AppButtonVariant.tonal,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.actionDeleteAccount,
            icon: Icons.delete_outline,
            variant: AppButtonVariant.text,
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref,
      {required bool hasAvatar}) async {
    if (hasAvatar) {
      final action = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: Text(ctx.l10n.avatarChangePhoto),
                onTap: () => Navigator.pop(ctx, 'change'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(ctx.l10n.avatarRemovePhoto),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
      if (action == 'remove') {
        await ref.read(localMediaStoreProvider).clearAvatar();
        ref.invalidate(avatarPathProvider);
        return;
      }
      if (action != 'change' || !context.mounted) return;
    }

    final picked = await PhotoPicker.pick(context, allowVideo: false);
    if (picked == null) return;
    await ref.read(localMediaStoreProvider).saveAvatar(
          bytes: picked.bytes,
          extension: picked.extension,
        );
    ref.invalidate(avatarPathProvider);
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: context.textStyles.bodyMedium),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(authControllerProvider.notifier);
    final isPassword = controller.providerIds.contains('password');
    final passwordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.l10n.deleteAccountBody),
            const SizedBox(height: AppSpacing.md),
            if (isPassword)
              AppTextField(
                label: ctx.l10n.deleteAccountPasswordLabel,
                controller: passwordCtrl,
                obscure: true,
              )
            else
              Text(
                ctx.l10n.deleteAccountReauthNote,
                style: ctx.textStyles.bodySmall
                    ?.copyWith(color: ctx.colors.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.colors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.actionDelete),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final ok = await controller.deleteAccount(
        password: isPassword ? passwordCtrl.text : null,
      );
      if (!ok && context.mounted) {
        final err = ref.read(authControllerProvider).error;
        context.showSnack(
          err is Failure ? err.message : context.l10n.deleteAccountError,
          isError: true,
        );
      }
    }
    passwordCtrl.dispose();
  }
}

/// Optional per-user AI key card. AI features work out of the box on the shared
/// key + a free fallback provider — this is only for users who want higher
/// limits by using their OWN free Google AI (Gemini) key. Kept simple: a note,
/// a one-tap "Get a free key" link, and a paste field.
class _AiKeyCard extends ConsumerStatefulWidget {
  const _AiKeyCard();

  @override
  ConsumerState<_AiKeyCard> createState() => _AiKeyCardState();
}

class _AiKeyCardState extends ConsumerState<_AiKeyCard> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(userGeminiKeyProvider.notifier).setKey(_ctrl.text);
    if (mounted) {
      setState(() => _saving = false);
      _ctrl.clear();
      context.showSnack('Your AI key is saved on this device.');
    }
  }

  Future<void> _clear() async {
    await ref.read(userGeminiKeyProvider.notifier).clear();
    if (mounted) context.showSnack('Removed — back to the shared AI.');
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(userGeminiKeyProvider).valueOrNull != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasKey
                      ? 'Using your own AI key ✓'
                      : 'AI works automatically — no setup needed',
                  style: context.textStyles.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasKey
                ? 'Your requests run on your own free quota. You can remove it '
                    'anytime to go back to the shared assistant.'
                : 'Optional: add your own free Google AI key for higher limits '
                    'if you use the AI a lot. Most people never need this.',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasKey)
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove my key'),
            )
          else
            Theme(
              data: context.theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('Add my own free key (advanced)',
                    style: context.textStyles.labelLarge
                        ?.copyWith(color: context.colors.primary)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/app/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Step 1: Get a free key (opens Google)'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _ctrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Step 2: Paste your key here',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save key'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
