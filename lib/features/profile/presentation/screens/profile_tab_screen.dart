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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cute_doodles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../memories/presentation/memory_providers.dart';
import '../../../memories/presentation/photo_picker.dart';
import '../../../memories/presentation/user_avatar.dart';
import '../../../settings/ai_key_providers.dart';
import '../controllers/profile_providers.dart';

/// The Categorized Profile tab: account hero, pregnancy record, app
/// preferences, AI settings, legal and account management with cute vector doodles.
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

    final displayName =
        profile?.name ?? user?.displayName ?? l10n.profileYourProfile;
    final role = user?.role ?? UserRole.mother;

    return Scaffold(

      appBar: AppBar(
        title: Row(
          children: [
            Text(
              l10n.profileTitle,
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            const CuteSparkle(size: 16),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          80,
        ),
        children: [
          // ==================== 1. PROFILE HERO CARD ====================
          _ProfileHeroCard(
            displayName: displayName,
            email: user?.email,
            role: role,
            onAvatarTap: () => _changeAvatar(
              context,
              ref,
              hasAvatar: ref.read(avatarPathProvider).valueOrNull != null,
            ),
            onEditProfileTap: () =>
                context.pushNamed(AppRoutes.editProfileName),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 2. PREGNANCY & MEDICAL RECORD ====================
          if (pregnancy != null) ...[
            _CategorySectionHeader(
              title: l10n.sectionPregnancy,
              badge: 'Medical Record',
              badgeColor: const Color(0xFFE87A90),
              icon: const CuteFootprint(size: 18, color: Color(0xFFE87A90)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE87A90).withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFE87A90).withValues(alpha: 0.15),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _MedicalInfoTile(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF7FC8A0),
                    label: l10n.fieldCurrentWeek,
                    value: l10n.weekLabel(pregnancy.currentWeek),
                  ),
                  const Divider(height: 16),
                  _MedicalInfoTile(
                    icon: Icons.event_rounded,
                    iconColor: const Color(0xFFF4A261),
                    label: l10n.fieldDueDate,
                    value: df.format(pregnancy.dueDate),
                  ),
                  const Divider(height: 16),
                  _MedicalInfoTile(
                    icon: Icons.shield_rounded,
                    iconColor: const Color(0xFF2E9E6B),
                    label: l10n.fieldRisk,
                    value: pregnancy.riskCategory.label,
                  ),
                  if (pregnancy.doctorName != null) ...[
                    const Divider(height: 16),
                    _MedicalInfoTile(
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF3A86FF),
                      label: l10n.fieldDoctor,
                      value: pregnancy.doctorName!,
                    ),
                  ],
                  if (pregnancy.hospital != null) ...[
                    const Divider(height: 16),
                    _MedicalInfoTile(
                      icon: Icons.local_hospital_rounded,
                      iconColor: const Color(0xFFE63946),
                      label: l10n.fieldHospital,
                      value: pregnancy.hospital!,
                    ),
                  ],
                  if (profile?.bloodGroup != null) ...[
                    const Divider(height: 16),
                    _MedicalInfoTile(
                      icon: Icons.bloodtype_rounded,
                      iconColor: const Color(0xFFD90429),
                      label: l10n.fieldBloodGroup,
                      value: profile!.bloodGroup!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5D3A48),
                        side: const BorderSide(color: Color(0xFFFFDADA)),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          context.pushNamed(AppRoutes.editPregnancyName),
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: Text(
                        l10n.profileEditPregnancy,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ==================== 3. APP PREFERENCES ====================
          _CategorySectionHeader(
            title: l10n.sectionAppearance,
            badge: 'Preferences',
            badgeColor: const Color(0xFF5CB8E4),
            icon: const CuteFlower(size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5CB8E4).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF5CB8E4).withValues(alpha: 0.15),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined,
                        size: 20, color: Color(0xFF5CB8E4)),
                    const SizedBox(width: 8),
                    Text(l10n.settingTheme,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5D3A48))),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppThemeMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFFFFDADA),
                      selectedForegroundColor: const Color(0xFF5D3A48),
                    ),
                    segments: [
                      ButtonSegment(
                        value: AppThemeMode.system,
                        label: Text(l10n.themeSystem),
                        icon: const Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.light,
                        label: Text(l10n.themeLight),
                        icon: const Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        label: Text(l10n.themeDark),
                        icon: const Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => ref
                        .read(appSettingsProvider.notifier)
                        .setThemeMode(s.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.language_rounded,
                        size: 20, color: Color(0xFF5CB8E4)),
                    const SizedBox(width: 8),
                    Text(l10n.settingLanguage,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5D3A48))),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFFFFDADA),
                      selectedForegroundColor: const Color(0xFF5D3A48),
                    ),
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'hi', label: Text('हिन्दी')),
                    ],
                    selected: {settings.localeCode},
                    onSelectionChanged: (s) => ref
                        .read(appSettingsProvider.notifier)
                        .setLocale(s.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.format_size_rounded,
                        size: 20, color: Color(0xFF5CB8E4)),
                    const SizedBox(width: 8),
                    Text(l10n.settingTextSize,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5D3A48))),
                    const Spacer(),
                    Text(
                      '${(settings.textScale * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC48B9F),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.textScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  activeColor: const Color(0xFFC48B9F),
                  inactiveColor: const Color(0xFFFFDADA),
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setTextScale(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 4. SMART AI ASSISTANT ====================
          _CategorySectionHeader(
            title: 'Mira AI Assistant',
            badge: 'Smart Setup',
            badgeColor: const Color(0xFFA78BFA),
            icon: const CuteSparkle(size: 18, color: Color(0xFFA78BFA)),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _AiKeyCard(),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 5. SUPPORT & LEGAL ====================
          _CategorySectionHeader(
            title: l10n.sectionAbout,
            badge: 'Legal & Info',
            badgeColor: const Color(0xFF94A3B8),
            icon: const CuteHeart(size: 18, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A86FF).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.privacy_tip_outlined,
                        size: 20, color: Color(0xFF3A86FF)),
                  ),
                  title: Text(
                    l10n.aboutPrivacy,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D3A48),
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(AppConstants.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FC8A0).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined,
                        size: 20, color: Color(0xFF2E9E6B)),
                  ),
                  title: Text(
                    l10n.aboutTerms,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D3A48),
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(AppConstants.termsUrl),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 6. ACCOUNT ACTIONS ====================
          AppButton(
            label: l10n.actionSignOut,
            icon: Icons.logout_rounded,
            variant: AppButtonVariant.tonal,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.actionDeleteAccount,
            icon: Icons.delete_outline_rounded,
            variant: AppButtonVariant.text,
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: AppSpacing.xxxl),
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

/// Profile Hero Card with custom gradient and cute doodle accents.
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.displayName,
    required this.email,
    required this.role,
    required this.onAvatarTap,
    required this.onEditProfileTap,
  });

  final String displayName;
  final String? email;
  final UserRole role;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  scheme.surfaceContainerHigh,
                  scheme.surfaceContainer,
                  scheme.surfaceContainerLow,
                ]
              : [
                  Colors.white,
                  AppColors.heroGradientMid,
                  scheme.primaryContainer,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFFC48B9F).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: scheme.outlineVariant,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  UserAvatar(
                    name: displayName,
                    radius: 36,
                    showEditBadge: true,
                    onTap: onAvatarTap,
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: CuteSparkle(size: 14, color: scheme.primary),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        role.label,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Edit Profile',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.tonal,
            onPressed: onEditProfileTap,
          ),
        ],
      ),
    );
  }
}

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF5D3A48),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        const CuteSparkle(size: 14, color: Color(0xFFFFDADA)),
      ],
    );
  }
}

class _MedicalInfoTile extends StatelessWidget {
  const _MedicalInfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF5D3A48).withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5D3A48),
          ),
        ),
      ],
    );
  }
}

/// Optional per-user AI key card with cute doodle accent.
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFA78BFA), size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasKey
                      ? 'Using your own AI key ✓'
                      : 'AI works automatically — no setup needed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D3A48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasKey
                ? 'Your requests run on your own quota. You can remove it anytime to return to the shared assistant.'
                : 'Optional: Add your personal Google AI Studio key for higher capacity.',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF8C6875).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasKey)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE86A5E),
                side: const BorderSide(color: Color(0xFFE86A5E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
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
                title: const Text(
                  'Add my own free key (Advanced)',
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA78BFA),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      ),
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
