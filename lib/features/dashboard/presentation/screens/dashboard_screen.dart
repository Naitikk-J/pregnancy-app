import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/pregnancy.dart';
import '../../../ai_tools/domain/ai_models.dart';
import '../../../ai_tools/presentation/ai_tools_providers.dart';
import '../../../ai_tools/presentation/widgets/ai_disclaimer.dart';
import '../../../appointments/presentation/appointment_providers.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../document_scan/presentation/scan_providers.dart';
import '../../../emergency/presentation/emergency_providers.dart';
import '../../../medicine/presentation/medicine_providers.dart';
import '../../../memories/presentation/user_avatar.dart';
import '../../../profile/presentation/controllers/profile_providers.dart';
import '../../../recovery/domain/pregnancy_access.dart';
import '../../../recovery/presentation/recovery_providers.dart';
import '../../../water/presentation/water_providers.dart';
import '../../../week_tracker/presentation/controllers/week_content_providers.dart';
import '../controllers/dashboard_providers.dart';
import '../widgets/week_hero_card.dart';

/// The Home tab: a daily summary of the pregnancy. Pulls only real data —
/// pregnancy progress, this-week content, and rotating quote/nutrition tips —
/// with quick access to the tracker and the emergency screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.displayName ?? 'there').split(' ').first;
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final access = ref.watch(pregnancyAccessProvider);
    final quote = ref.watch(dailyQuoteProvider);
    final tip = ref.watch(dailyNutritionTipProvider);
    final smile = ref.watch(dailySmileProvider);
    final myth = ref.watch(dailyMythProvider);
    // Keep the Android home-screen widget in sync (no-op on other platforms).
    ref.watch(homeWidgetSyncProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: UserAvatar(
            name: user?.displayName ?? firstName,
            radius: 18,
            onTap: () => context.pushNamed(AppRoutes.profileName),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'Good morning, $firstName!',
          style: context.textStyles.titleLarge?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.emergency,
            onPressed: () => context.pushNamed(AppRoutes.emergencyName),
            icon: Icon(Icons.favorite_rounded, color: context.colors.primary),
          ),
        ],
      ),
      body: pregnancy == null
          ? (access.needsRecovery
              ? const _RecoveryPrompt()
              : LoadingView(message: context.l10n.dashLoadingJourney))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activePregnancyProvider);
                ref.invalidate(todayWaterProvider);
                ref.invalidate(appointmentsProvider);
                ref.invalidate(weekContentProvider(pregnancy.currentWeek));
                await ref.read(activePregnancyProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  120,
                ),
                children: [
                  const _AccessBanner(),
                  const _SosBanner(),
                  for (final (i, section) in <Widget>[
                    WeekHeroCard(pregnancy: pregnancy),
                    _TodayWellnessPulse(pregnancy: pregnancy),
                    _BabyWeeklyMilestoneCard(pregnancy: pregnancy),
                    const _AskMiraCard(),
                    _DailyInspirationTabbedCard(
                      quote: quote,
                      tip: tip,
                      myth: myth,
                      smile: smile,
                    ),
                    const _EmergencyBanner(),
                  ].indexed)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == 0 ? AppSpacing.xl : AppSpacing.lg),
                      child: AnimatedEntrance(index: i, child: section),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
    );
  }
}

/// Warns when the account can't reach its pregnancy data (typically the active
/// pregnancy belongs to a different account after a sign-in switch, which is what
/// produces `permission-denied` on the tracker screens) and routes to recovery.
class _AccessBanner extends ConsumerWidget {
  const _AccessBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(pregnancyAccessProvider);
    // Only the `foreign` case still renders the dashboard (the foreign doc is
    // world-readable); `missing`/`none` are handled by the full-screen prompt.
    if (access != PregnancyAccess.foreign) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        color: context.colors.errorContainer,
        onTap: () => context.pushNamed(AppRoutes.fixAccessName),
        child: Row(
          children: [
            Icon(Icons.report_gmailerrorred_outlined,
                color: context.colors.onErrorContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                "Your trackers can't load on this account. Tap to fix.",
                style: context.textStyles.titleSmall
                    ?.copyWith(color: context.colors.onErrorContainer),
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.onErrorContainer),
          ],
        ),
      ),
    );
  }
}

/// Full-screen replacement for the endless spinner when there is no reachable
/// pregnancy at all (deleted record, or the account has none yet).
class _RecoveryPrompt extends StatelessWidget {
  const _RecoveryPrompt();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.pregnant_woman,
      imageAsset: 'assets/images/mom.png',
      title: "Let's set up your pregnancy",
      message:
          "We couldn't load your pregnancy on this account. Set it up to start "
          'tracking your journey.',
      actionLabel: 'Set up now',
      onAction: () => context.pushNamed(AppRoutes.fixAccessName),
    );
  }
}

/// Shows any active SOS alert raised in this pregnancy (so a partner/family sees
/// it immediately on opening the app), with quick call + resolve actions.
class _SosBanner extends ConsumerWidget {
  const _SosBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(activeSosProvider).valueOrNull ?? const [];
    if (alerts.isEmpty) return const SizedBox.shrink();
    final alert = alerts.first;
    final name = (alert['createdByName'] as String?) ?? '';
    final col = ref.read(sosCollectionProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        color: context.colors.error,
        onTap: () => context.pushNamed(AppRoutes.emergencyName),
        child: Row(
          children: [
            Icon(Icons.sos, color: context.colors.onError),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(context.l10n.dashSosRaised(name),
                  style: context.textStyles.titleSmall
                      ?.copyWith(color: context.colors.onError)),
            ),
            TextButton(
              onPressed: col == null
                  ? null
                  : () => col
                      .doc(alert['id'] as String)
                      .set({'status': 'resolved'}, SetOptions(merge: true)),
              child: Text(context.l10n.dashResolve,
                  style: TextStyle(color: context.colors.onError)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clean, serene daily wellness pulse card summarizing today's key stats.
class _TodayWellnessPulse extends ConsumerWidget {
  const _TodayWellnessPulse({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(todayWaterProvider).valueOrNull;
    final doses = ref.watch(todayDosesProvider);
    final pendingDoses = doses.where((d) => d.status != DoseStatus.taken).length;
    final appointments = ref.watch(appointmentsProvider).valueOrNull ?? const [];
    final upcoming = appointments.where((a) => a.isUpcoming).toList();
    final nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;

    final waterPercent = (waterState != null && waterState.goalMl > 0)
        ? (waterState.consumedMl / waterState.goalMl).clamp(0.0, 1.0)
        : 0.0;

    final df = DateFormat('EEE, d MMM');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      color: context.colors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Today\'s Care Pulse',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.care),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Care Hub'),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Water Pill
              Expanded(
                child: _PulseTile(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: '${waterState?.consumedMl ?? 0} ml',
                  subtitle: 'Water (${(waterPercent * 100).toInt()}%)',
                  onTap: () => context.pushNamed(AppRoutes.waterName),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Medicine Pill
              Expanded(
                child: _PulseTile(
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: pendingDoses == 0 ? 'All done' : '$pendingDoses left',
                  subtitle: 'Medicines',
                  onTap: () => context.pushNamed(AppRoutes.medicinesName),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Appointment Pill
              Expanded(
                child: _PulseTile(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: nextAppointment != null
                      ? df.format(nextAppointment.dateTime)
                      : 'Dr. Visit',
                  subtitle: nextAppointment != null ? 'Checkup' : 'Schedule',
                  onTap: () => context.pushNamed(AppRoutes.appointmentsName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseTile extends StatelessWidget {
  const _PulseTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF2C2428) : const Color(0xFFFFF8F9),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                style: context.textStyles.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: context.textStyles.bodySmall?.copyWith(
                  fontSize: 10,
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean baby developmental highlight card for the current week.
class _BabyWeeklyMilestoneCard extends ConsumerWidget {
  const _BabyWeeklyMilestoneCard({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(weekContentProvider(pregnancy.currentWeek));

    return AppCard(
      onTap: () => context.go(AppRoutes.tracker),
      child: contentAsync.when(
        loading: () => const SizedBox(
          height: 70,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (content) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Color(0xFFDB2777),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week ${pregnancy.currentWeek}: Baby is size of a ${content.sizeComparison}',
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        content.babyDevelopment.length > 90
                            ? '${content.babyDevelopment.substring(0, 90)}...'
                            : content.babyDevelopment,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact, single-card swipeable inspiration widget combining Quote, Tip, Myth, and Smile.
class _DailyInspirationTabbedCard extends StatefulWidget {
  const _DailyInspirationTabbedCard({
    required this.quote,
    required this.tip,
    required this.myth,
    required this.smile,
  });

  final String quote;
  final String tip;
  final (String, String) myth;
  final String smile;

  @override
  State<_DailyInspirationTabbedCard> createState() =>
      _DailyInspirationTabbedCardState();
}

class _DailyInspirationTabbedCardState
    extends State<_DailyInspirationTabbedCard> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Daily Inspiration',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Full-width segmented tab bar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2428) : const Color(0xFFF5F3F4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabPill(
                    label: 'Quote',
                    selected: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabPill(
                    label: 'Nutrition',
                    selected: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                ),
                Expanded(
                  child: _TabPill(
                    label: 'Myth',
                    selected: _activeTab == 2,
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                ),
                Expanded(
                  child: _TabPill(
                    label: 'Smile',
                    selected: _activeTab == 3,
                    onTap: () => setState(() => _activeTab = 3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildTabContent(_activeTab),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int tab) {
    switch (tab) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“${widget.quote}”',
                style: context.textStyles.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition Tip',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.tip,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close_rounded,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Myth: ${widget.myth.$1}',
                      style: context.textStyles.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded,
                      color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Fact: ${widget.myth.$2}',
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 3:
      default:
        return KeyedSubtree(
          key: const ValueKey(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Smile',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.smile,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : context.colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}



/// A home-screen wellbeing helper: the mother taps how she's feeling and AI
/// suggests gentle coping ideas — activities, calming music (YouTube), books,
/// meditation/yoga — with a safety net for serious symptoms.
class _WellbeingCard extends ConsumerStatefulWidget {
  const _WellbeingCard();
  @override
  ConsumerState<_WellbeingCard> createState() => _WellbeingCardState();
}

class _WellbeingCardState extends ConsumerState<_WellbeingCard> {
  bool _loading = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _feelings = <(String, IconData)>[
    ('Low mood', Icons.sentiment_dissatisfied_outlined),
    ('Anxious', Icons.psychology_outlined),
    ('Stressed', Icons.bolt_outlined),
    ('Not sleeping well', Icons.bedtime_outlined),
    ('Very tired', Icons.battery_2_bar_outlined),
    ('Nauseous', Icons.sick_outlined),
    ('Lonely', Icons.person_outline),
    ('Back pain', Icons.accessibility_new_outlined),
  ];

  Future<void> _get(String feeling) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final plan = await ref.read(documentAiRepositoryProvider).wellbeing(
            feeling: feeling,
            context: ref.read(aiContextProvider),
          );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _WellbeingSheet(feeling: feeling, plan: plan),
      );
    } catch (e) {
      if (mounted) {
        context.showSnack(
            e is StateError ? e.message : 'Could not load suggestions.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.tertiaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_outlined,
                  color: context.colors.onTertiaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Feeling something? I can help',
                    style: context.textStyles.titleSmall?.copyWith(
                        color: context.colors.onTertiaryContainer)),
              ),
              if (_loading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap how you feel — or tell me in your own words — for gentle, safe '
            'ideas to feel better.',
            style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onTertiaryContainer
                    .withValues(alpha: 0.85)),
          ),
          // Proactive nudge from her own logged sleep/mood.
          Builder(builder: (context) {
            final nudge = ref.watch(wellbeingNudgeProvider);
            if (nudge == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: _loading ? null : () => _get(nudge.feeling),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.favorite, color: context.colors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(nudge.message,
                              style: context.textStyles.bodyMedium),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (label, icon) in _feelings)
                ActionChip(
                  avatar: Icon(icon, size: 16),
                  label: Text(label),
                  onPressed: _loading ? null : () => _get(label),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !_loading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _submitText,
                  decoration: const InputDecoration(
                    hintText: 'Tell me how you feel…',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => _submitText(_ctrl.text),
                icon: const Icon(Icons.send),
                tooltip: 'Get suggestions',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitText(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    FocusScope.of(context).unfocus();
    _get(t);
  }
}

/// The result sheet for the wellbeing helper.
class _WellbeingSheet extends StatelessWidget {
  const _WellbeingSheet({required this.feeling, required this.plan});
  final String feeling;
  final WellbeingPlan plan;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + navInset),
        children: [
          if (plan.urgent) ...[
            AppCard(
              color: context.colors.error,
              onTap: () => context.pushNamed(AppRoutes.emergencyName),
              child: Row(
                children: [
                  Icon(Icons.emergency, color: context.colors.onError),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Please reach out for help right now — tap for emergency '
                      'contacts, or call your doctor.',
                      style: context.textStyles.titleSmall
                          ?.copyWith(color: context.colors.onError),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('For when you feel ${feeling.toLowerCase()}',
              style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (plan.supportive.isNotEmpty)
            Text(plan.supportive,
                style: context.textStyles.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: context.colors.onSurfaceVariant)),
          _list(context, '🌿 Things you can do', plan.activities),
          if (plan.music.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('🎵 Calming music', style: context.textStyles.titleSmall),
            for (final q in plan.music)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_outline),
                title: Text(q),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _open(
                    'https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}'),
              ),
          ],
          if (plan.books.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('📚 Books that may help',
                style: context.textStyles.titleSmall),
            for (final b in plan.books)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(b.title),
                subtitle: b.author.isEmpty ? null : Text(b.author),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _open(
                    'https://www.google.com/search?q=${Uri.encodeComponent('${b.title} ${b.author} book')}'),
              ),
          ],
          _list(context, '🧘 Meditation & yoga', plan.meditationYoga),
          if (plan.seekHelp.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: context.colors.secondaryContainer,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_outline,
                      color: context.colors.onSecondaryContainer),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(plan.seekHelp,
                        style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSecondaryContainer)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AiDisclaimer(plan.disclaimer),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(title, style: context.textStyles.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: AppSpacing.sm),
                  child: Icon(Icons.circle,
                      size: 6, color: context.colors.primary),
                ),
                Expanded(
                    child:
                        Text(it, style: context.textStyles.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A prominent entry point to the "Ask Mira" AI assistant, right on the home
/// screen so help is always one tap away.
class _AskMiraCard extends StatelessWidget {
  const _AskMiraCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: () => context.pushNamed(AppRoutes.aiAssistantName),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask Mira',
                          style: context.textStyles.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      Text(
                        'Your AI pregnancy companion — ask me anything',
                        style: context.textStyles.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.errorContainer,
      onTap: () => context.pushNamed(AppRoutes.emergencyName),
      child: Row(
        children: [
          Icon(Icons.emergency, color: context.colors.onErrorContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.dashEmergencyBanner,
              style: context.textStyles.titleSmall
                  ?.copyWith(color: context.colors.onErrorContainer),
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.onErrorContainer),
        ],
      ),
    );
  }
}
