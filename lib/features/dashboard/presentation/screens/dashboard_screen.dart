import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../reminders/presentation/reminder_providers.dart';
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
            onTap: () => context.go(AppRoutes.profile),
          ),
        ),
        leadingWidth: 56,
        title: Text(context.l10n.dashGreeting(firstName)),
        actions: [
          IconButton(
            tooltip: context.l10n.emergency,
            onPressed: () => context.pushNamed(AppRoutes.emergencyName),
            icon: Icon(Icons.emergency_outlined, color: context.colors.error),
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _AccessBanner(),
                  const _SosBanner(),
                  for (final (i, section) in <Widget>[
                    WeekHeroCard(pregnancy: pregnancy),
                    const _QuickActions(),
                    const _AskMiraCard(),
                    const _WellbeingCard(),
                    const _DashSection(title: 'Your baby'),
                    _BabySizeCard(pregnancy: pregnancy),
                    _ThisWeekCard(week: pregnancy.currentWeek),
                    const _DashSection(title: 'Today'),
                    const _RemindersCard(),
                    _TodayInfoCard(pregnancy: pregnancy),
                    const _TodayStrip(),
                    const _DashSection(title: 'For you'),
                    _QuoteCard(quote: quote),
                    _TipCard(tip: tip),
                    _MythCard(myth: myth.$1, fact: myth.$2),
                    _SmileCard(smile: smile),
                    _EmergencyBanner(),
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

/// A small section divider on the dashboard so the long feed reads as grouped
/// sections ("Your baby", "Today", "For you") rather than one undifferentiated
/// scroll.
class _DashSection extends StatelessWidget {
  const _DashSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 2),
      child: SectionHeader(title: title),
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

/// Home card showing the next few upcoming reminders, with a tap-through to the
/// full Reminders screen to add/manage alarms.
class _RemindersCard extends ConsumerWidget {
  const _RemindersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingRemindersProvider);
    return AppCard(
      onTap: () => context.pushNamed(AppRoutes.remindersName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alarm, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child:
                    Text('Reminders', style: context.textStyles.titleSmall),
              ),
              TextButton.icon(
                onPressed: () => context.pushNamed(AppRoutes.remindersName),
                icon: const Icon(Icons.add_alarm, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (upcoming.isEmpty)
            Text('No reminders yet — tap Add to set an alarm for anything.',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant))
          else
            for (final r in upcoming.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(r.repeatDaily ? Icons.repeat : Icons.circle_outlined,
                        size: 14, color: context.colors.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(r.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(
                      r.repeatDaily
                          ? TimeOfDay.fromDateTime(r.remindAt).format(context)
                          : _MaterialLocalizationsShort.rel(context, r.remindAt),
                      style: context.textStyles.labelSmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Tiny helper for a compact relative date/time label.
class _MaterialLocalizationsShort {
  static String rel(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final t = TimeOfDay.fromDateTime(dt).format(context);
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return t;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
    if (isTomorrow) return 'Tmrw $t';
    return '${MaterialLocalizations.of(context).formatShortDate(dt)} $t';
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

/// A horizontal row of quick-access pill chips for the most-used daily tools —
/// mirroring the reference's friendly shortcut chips under the greeting.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, Color, String)>[
      (Icons.child_care_rounded, 'Kick count', AppColors.secondary,
          AppRoutes.kickCounterName),
      (Icons.timer_rounded, 'Contractions', AppColors.tertiary,
          AppRoutes.contractionTimerName),
      (Icons.event_available_rounded, 'Appointments', AppColors.ringSegments[0],
          AppRoutes.appointmentsName),
      (Icons.chat_bubble_rounded, 'Ask Mira', AppColors.primary,
          AppRoutes.aiAssistantName),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (icon, label, color, route) = actions[i];
          return _ActionChip(
            icon: icon,
            label: label,
            color: color,
            onTap: () => context.pushNamed(route),
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      elevation: 1.5,
      shadowColor: AppColors.secondary.withValues(alpha: 0.18),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: context.textStyles.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The friendly "baby size" card — a fruit metaphor plus the baby's estimated
/// length and weight this week, styled after the reference growth card.
class _BabySizeCard extends ConsumerWidget {
  const _BabySizeCard({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content =
        ref.watch(weekContentProvider(pregnancy.currentWeek)).valueOrNull;
    final size = content?.sizeComparison;
    if (content == null || size == null || size.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      color: AppColors.babyBlush,
      onTap: () => context.go(AppRoutes.tracker),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco_rounded,
                    color: AppColors.ringSegments[0], size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week, baby is about the size of',
                        style: context.textStyles.bodySmall?.copyWith(
                            color: AppColors.primaryDark
                                .withValues(alpha: 0.75))),
                    Text('a ${size.toLowerCase()}',
                        style: context.textStyles.titleLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          if (content.lengthLabel != null || content.weightLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (content.lengthLabel != null)
                  Expanded(
                    child: _BabyStat(
                      icon: Icons.straighten_rounded,
                      label: 'Length',
                      value: content.lengthLabel!,
                    ),
                  ),
                if (content.lengthLabel != null && content.weightLabel != null)
                  const SizedBox(width: AppSpacing.md),
                if (content.weightLabel != null)
                  Expanded(
                    child: _BabyStat(
                      icon: Icons.monitor_weight_rounded,
                      label: 'Weight',
                      value: content.weightLabel!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BabyStat extends StatelessWidget {
  const _BabyStat(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: context.textStyles.bodySmall?.copyWith(
                      color: AppColors.primaryDark.withValues(alpha: 0.7))),
              Text(value,
                  style: context.textStyles.titleSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A day-specific snapshot of where the pregnancy is *today*: which day of the
/// current week, weeks completed, days to go, baby's size, and one gentle focus
/// for the day. This is the "information of the day" tied to the live status.
class _TodayInfoCard extends ConsumerWidget {
  const _TodayInfoCard({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(dailyFocusProvider);
    final size =
        ref.watch(weekContentProvider(pregnancy.currentWeek)).valueOrNull?.sizeComparison;
    final onColor = context.colors.onSecondaryContainer;

    return AppCard(
      color: context.colors.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_outlined, color: onColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.dashTodayHeader(
                      pregnancy.dayOfCurrentWeek, pregnancy.currentWeek),
                  style: context.textStyles.titleMedium?.copyWith(color: onColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.l10n.daysToGo(pregnancy.daysRemaining)} · ${pregnancy.trimester.label}'
            '${size != null && size.isNotEmpty ? ' · ${context.l10n.dashBabySize(size)}' : ''}',
            style: context.textStyles.bodyMedium?.copyWith(color: onColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.spa_outlined, size: 18, color: onColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  focus,
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: onColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A daily uplifting note — a wholesome joke / happy line to make mum smile.
class _SmileCard extends StatelessWidget {
  const _SmileCard({required this.smile});
  final String smile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.tertiaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mood, color: context.colors.onTertiaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.dashSmileTitle,
                    style: context.textStyles.titleSmall
                        ?.copyWith(color: context.colors.onTertiaryContainer)),
                const SizedBox(height: 2),
                Text(smile,
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.colors.onTertiaryContainer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pregnancy myth of the day" — a rotating myth with the evidence-based fact,
/// plus an on-demand AI explanation of where the myth likely came from.
class _MythCard extends ConsumerStatefulWidget {
  const _MythCard({required this.myth, required this.fact});
  final String myth;
  final String fact;

  @override
  ConsumerState<_MythCard> createState() => _MythCardState();
}

class _MythCardState extends ConsumerState<_MythCard> {
  bool _loading = false;
  MythExplanation? _explanation;
  String? _error;

  Future<void> _explain(String myth, String fact) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(documentAiRepositoryProvider).explainMyth(
            myth: myth,
            fact: fact,
          );
      if (mounted) setState(() => _explanation = r);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is StateError ? e.message : 'Could not load the explanation.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the AI stage-aware myth (tailored to trimester/condition); fall
    // back to the static rotating myth while it loads or if AI is unavailable.
    final stage = ref.watch(stageMythProvider);
    final ai = stage.valueOrNull;
    final myth = ai?.myth ?? widget.myth;
    final fact = ai?.fact ?? widget.fact;
    final exp = _explanation;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: context.colors.tertiary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Myth of the day',
                    style: context.textStyles.titleSmall),
              ),
              if (ai != null)
                Text('for week ${_weekBadge(ai)}',
                    style: context.textStyles.labelSmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _line(context, Icons.close_rounded, context.colors.error, 'Myth',
              myth,
              strike: true),
          const SizedBox(height: AppSpacing.sm),
          _line(context, Icons.check_rounded, AppColors.success, 'Fact', fact),
          const SizedBox(height: AppSpacing.md),

          // AI stage-myth already includes the origin.
          if (ai != null) ...[
            if (ai.origin.isNotEmpty)
              _expBlock(context, '🌱 Where it came from', ai.origin),
            if (ai.takeaway.isNotEmpty)
              _expBlock(context, '💡 Takeaway', ai.takeaway),
            const SizedBox(height: AppSpacing.xs),
            AiDisclaimer(ai.disclaimer),
          ]
          // Static fallback: offer an on-demand AI origin explanation.
          else if (exp != null) ...[
            _expBlock(context, '🌱 Where it came from', exp.origin),
            _expBlock(context, '✅ The truth', exp.truth),
            if (exp.takeaway.isNotEmpty)
              _expBlock(context, '💡 Takeaway', exp.takeaway),
            const SizedBox(height: AppSpacing.xs),
            AiDisclaimer(exp.disclaimer),
          ] else if (_loading || stage.isLoading) ...[
            Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                    stage.isLoading
                        ? 'Finding a myth for your stage…'
                        : 'Asking Mira…',
                    style: context.textStyles.bodySmall),
              ],
            ),
          ] else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(_error!,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: context.colors.error)),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => _explain(myth, fact),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Where did this come from?'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _weekBadge(DailyMyth _) {
    final w = ref.read(aiContextProvider)['currentWeek'];
    return w == null ? '' : '$w';
  }

  Widget _line(BuildContext context, IconData icon, Color color, String label,
      String text,
      {bool strike = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: context.textStyles.bodyMedium
                  ?.copyWith(color: context.colors.onSurface),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                  text: text,
                  style: strike
                      ? TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: context.colors.onSurfaceVariant)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _expBlock(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: context.textStyles.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(body, style: context.textStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ThisWeekCard extends ConsumerWidget {
  const _ThisWeekCard({required this.week});
  final int week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(weekContentProvider(week));
    return AppCard(
      onTap: () => context.go(AppRoutes.tracker),
      child: contentAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (content) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                      context.l10n.dashThisWeekSize(content.sizeComparison),
                      style: context.textStyles.titleMedium),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content.babyDevelopment,
              style: context.textStyles.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.dashOpenWeekTracker,
                style: context.textStyles.labelLarge
                    ?.copyWith(color: context.colors.primary)),
          ],
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final String quote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.primaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote,
              color: context.colors.onPrimaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(quote,
                style: context.textStyles.titleMedium?.copyWith(
                    color: context.colors.onPrimaryContainer,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.restaurant_menu, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.dashNutritionTip,
                    style: context.textStyles.titleSmall),
                const SizedBox(height: 2),
                Text(tip, style: context.textStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact live summary of today's medicines, water and next appointment.
class _TodayStrip extends ConsumerWidget {
  const _TodayStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherence = ref.watch(todayAdherenceProvider);
    final water = ref.watch(todayWaterProvider).valueOrNull;
    final appts = ref.watch(appointmentsProvider).valueOrNull ?? const [];
    final nextAppt =
        appts.where((a) => a.isUpcoming).isEmpty ? null : appts.firstWhere((a) => a.isUpcoming);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.medication_outlined,
                label: context.l10n.dashMedicines,
                value: adherence.total == 0
                    ? '—'
                    : '${adherence.taken}/${adherence.total}',
                color: context.colors.primaryContainer,
                onColor: context.colors.onPrimaryContainer,
                onTap: () => context.pushNamed(AppRoutes.medicinesName),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                icon: Icons.water_drop_outlined,
                label: context.l10n.dashWater,
                value: water == null
                    ? '—'
                    : '${water.glasses}/${water.goalGlasses}',
                color: context.colors.tertiaryContainer,
                onColor: context.colors.onTertiaryContainer,
                onTap: () => context.pushNamed(AppRoutes.waterName),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _StatCard(
          icon: Icons.event_outlined,
          label: context.l10n.dashNextAppointment,
          value: nextAppt == null
              ? context.l10n.dashNoneScheduled
              : '${nextAppt.title} · '
                  '${MaterialLocalizations.of(context).formatShortDate(nextAppt.dateTime)}',
          wide: true,
          color: context.colors.secondaryContainer,
          onColor: context.colors.onSecondaryContainer,
          onTap: () => context.pushNamed(AppRoutes.appointmentsName),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.color,
    this.onColor,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? color;
  final Color? onColor;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final fg = onColor ?? context.colors.onSurface;
    final iconColor = onColor ?? context.colors.primary;
    return AppCard(
      color: color,
      onTap: onTap,
      child: wide
          ? Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: fg)),
                      Text(value,
                          style: context.textStyles.titleSmall
                              ?.copyWith(color: fg),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: fg),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(height: AppSpacing.sm),
                Text(value,
                    style: context.textStyles.titleLarge?.copyWith(color: fg)),
                Text(label,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: fg.withValues(alpha: 0.85))),
              ],
            ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
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
