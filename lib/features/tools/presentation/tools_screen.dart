import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../doctor/presentation/doctor_providers.dart';

/// A rotating palette so the Tools grid reads as colourful and friendly rather
/// than a wall of identical teal icons.
const List<Color> _toolColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.tertiary,
  Color(0xFF7FC8A0),
  Color(0xFF6FD0C0),
  Color(0xFFF0857D),
  Color(0xFFF4B36B),
  Color(0xFFA99BE0),
];

/// A coloured, softly-glowing icon bubble that pops in with a gentle spring —
/// the redesigned, animated Tools-grid icon.
class _ToolIconBubble extends StatefulWidget {
  const _ToolIconBubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_ToolIconBubble> createState() => _ToolIconBubbleState();
}

class _ToolIconBubbleState extends State<_ToolIconBubble> {
  double _scale = 0.6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withValues(alpha: 0.28),
              widget.color.withValues(alpha: 0.14),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(widget.icon, size: 26, color: widget.color),
      ),
    );
  }
}

/// A tool descriptor. New tools are added here as each feature phase ships, so
/// the grid only ever shows things that actually work. [label] resolves against
/// the active locale so the grid is fully localized.
class _Tool {
  const _Tool(this.label, this.icon, this.onTap);
  final String Function(AppLocalizations) label;
  final IconData icon;
  final void Function(BuildContext) onTap;
}

/// The Tools tab: a grid of quick-access tools. Grows each phase.
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  static final List<_Tool> _tools = [
    _Tool((l) => l.toolsMedicines, Icons.medication,
        (c) => c.pushNamed(AppRoutes.medicinesName)),
    _Tool((l) => l.toolsAppointments, Icons.event_note,
        (c) => c.pushNamed(AppRoutes.appointmentsName)),
    _Tool((l) => l.toolsSymptoms, Icons.healing,
        (c) => c.pushNamed(AppRoutes.symptomsName)),
    _Tool((l) => l.toolsWater, Icons.water_drop,
        (c) => c.pushNamed(AppRoutes.waterName)),
    _Tool((l) => l.toolsWeight, Icons.monitor_weight,
        (c) => c.pushNamed(AppRoutes.weightName)),
    _Tool((l) => l.toolsKickCounter, Icons.child_care,
        (c) => c.pushNamed(AppRoutes.kickCounterName)),
    _Tool((l) => l.toolsContractions, Icons.timelapse,
        (c) => c.pushNamed(AppRoutes.contractionTimerName)),
    _Tool((l) => l.toolsReport, Icons.assessment,
        (c) => c.pushNamed(AppRoutes.movementReportName)),
    _Tool((l) => l.toolsBloodPressure, Icons.favorite_outline,
        (c) => c.pushNamed(AppRoutes.bloodPressureName)),
    _Tool((l) => l.toolsBloodSugar, Icons.bloodtype_outlined,
        (c) => c.pushNamed(AppRoutes.bloodSugarName)),
    _Tool((l) => l.toolsSleep, Icons.bedtime_outlined,
        (c) => c.pushNamed(AppRoutes.sleepName)),
    _Tool((l) => l.toolsVaccinations, Icons.vaccines_outlined,
        (c) => c.pushNamed(AppRoutes.vaccinationsName)),
    _Tool((l) => l.toolsHospitalBag, Icons.luggage_outlined,
        (c) => c.pushNamed(AppRoutes.hospitalBagName)),
    _Tool((l) => l.toolsReportsInsights, Icons.assessment_outlined,
        (c) => c.pushNamed(AppRoutes.reportsName)),
    _Tool((l) => l.toolsNutrition, Icons.restaurant_outlined,
        (c) => c.pushNamed(AppRoutes.nutritionName)),
    _Tool((l) => l.toolsExercise, Icons.fitness_center_outlined,
        (c) => c.pushNamed(AppRoutes.exerciseName)),
    _Tool((l) => l.toolsCalendar, Icons.event_outlined,
        (c) => c.pushNamed(AppRoutes.calendarName)),
    _Tool((l) => l.toolsJournal, Icons.menu_book_outlined,
        (c) => c.pushNamed(AppRoutes.journalName)),
    _Tool((l) => 'Mood calendar', Icons.mood,
        (c) => c.pushNamed(AppRoutes.moodCalendarName)),
    _Tool((l) => 'Reminders', Icons.alarm,
        (c) => c.pushNamed(AppRoutes.remindersName)),
    _Tool((l) => l.toolsMemories, Icons.photo_library_outlined,
        (c) => c.pushNamed(AppRoutes.memoriesName)),
    _Tool((l) => l.toolsPartnerFamily, Icons.people_outline,
        (c) => c.pushNamed(AppRoutes.partnerName)),
    _Tool((l) => l.toolsAiHealth, Icons.auto_awesome,
        (c) => c.pushNamed(AppRoutes.aiToolsName)),
    _Tool((l) => l.toolsCommunity, Icons.forum_outlined,
        (c) => c.pushNamed(AppRoutes.communityName)),
    _Tool((l) => l.toolsBabyNames, Icons.badge_outlined,
        (c) => c.pushNamed(AppRoutes.babyNamesName)),
    _Tool((l) => l.toolsBirthPlan, Icons.checklist_rtl_outlined,
        (c) => c.pushNamed(AppRoutes.birthPlanName)),
    _Tool((l) => l.toolsShopping, Icons.shopping_cart_outlined,
        (c) => c.pushNamed(AppRoutes.shoppingName)),
    _Tool((l) => l.toolsPremium, Icons.workspace_premium_outlined,
        (c) => c.pushNamed(AppRoutes.premiumName)),
    _Tool((l) => l.toolsWeekTracker, Icons.calendar_month,
        (c) => c.go(AppRoutes.tracker)),
    _Tool((l) => l.toolsEmergency, Icons.emergency,
        (c) => c.pushNamed(AppRoutes.emergencyName)),
    _Tool((l) => 'Blood donors', Icons.bloodtype_outlined,
        (c) => c.pushNamed(AppRoutes.bloodDonorsName)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tools = [
      if (ref.watch(isAdminProvider))
        _Tool((l) => 'Admin', Icons.admin_panel_settings_outlined,
            (c) => c.pushNamed(AppRoutes.adminName)),
      if (ref.watch(isDoctorProvider))
        _Tool((l) => l.toolsDoctorPortal, Icons.medical_services_outlined,
            (c) => c.pushNamed(AppRoutes.doctorPortalName)),
      ..._tools,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTools)),
      body: GridView.count(
        crossAxisCount: context.isCompact ? 2 : 4,
        padding: const EdgeInsets.all(AppSpacing.lg),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        children: [
          for (final (i, tool) in tools.indexed)
            AnimatedEntrance(
              index: i,
              child: AppCard(
                onTap: () => tool.onTap(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ToolIconBubble(icon: tool.icon, color: _toolColors[i % _toolColors.length]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(tool.label(l10n),
                        textAlign: TextAlign.center,
                        style: context.textStyles.titleSmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
