import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cute_doodles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../doctor/presentation/doctor_providers.dart';

enum ToolCategory {
  all('All', Icons.grid_view_rounded, Color(0xFFC48B9F)),
  medical('Medical & Health', Icons.medical_services_rounded, Color(0xFFE87A90)),
  baby('Baby & Tracking', Icons.child_care_rounded, Color(0xFF7FC8A0)),
  habits('Daily Habits', Icons.water_drop_rounded, Color(0xFF5CB8E4)),
  ai('Smart AI & Prep', Icons.auto_awesome_rounded, Color(0xFFA78BFA)),
  family('Family & Memories', Icons.favorite_rounded, Color(0xFFF49D6E));

  const ToolCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _ToolItem {
  const _ToolItem({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.category,
    required this.color,
    this.subtitle,
    this.badge,
  });

  final String Function(AppLocalizations) label;
  final IconData icon;
  final void Function(BuildContext) onTap;
  final ToolCategory category;
  final Color color;
  final String? subtitle;
  final String? badge;
}

/// Categorized Tools Screen with search, filter chips, and cute vector doodles.
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  ToolCategory _selectedCategory = ToolCategory.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static final List<_ToolItem> _allTools = [
    // 🩺 Medical & Health
    _ToolItem(
      label: (l) => l.toolsMedicines,
      subtitle: 'Track pills & prenatal vitamins',
      icon: Icons.medication_liquid_rounded,
      category: ToolCategory.medical,
      color: const Color(0xFFE87A90),
      onTap: (c) => c.pushNamed(AppRoutes.medicinesName),
    ),
    _ToolItem(
      label: (l) => l.toolsAppointments,
      subtitle: 'Doctor visits & ultrasound scans',
      icon: Icons.event_note_rounded,
      category: ToolCategory.medical,
      color: const Color(0xFF9D71E8),
      onTap: (c) => c.pushNamed(AppRoutes.appointmentsName),
    ),
    _ToolItem(
      label: (l) => l.toolsBloodPressure,
      subtitle: 'Log systolic & diastolic readings',
      icon: Icons.monitor_heart_rounded,
      category: ToolCategory.medical,
      color: const Color(0xFFE86A5E),
      onTap: (c) => c.pushNamed(AppRoutes.bloodPressureName),
    ),
    _ToolItem(
      label: (l) => l.toolsBloodSugar,
      subtitle: 'Fasting & post-meal glucose tracker',
      icon: Icons.bloodtype_rounded,
      category: ToolCategory.medical,
      color: const Color(0xFFE07A5F),
      onTap: (c) => c.pushNamed(AppRoutes.bloodSugarName),
    ),
    _ToolItem(
      label: (l) => l.toolsVaccinations,
      subtitle: 'Maternal immunization schedule',
      icon: Icons.vaccines_rounded,
      category: ToolCategory.medical,
      color: const Color(0xFF2E9E6B),
      onTap: (c) => c.pushNamed(AppRoutes.vaccinationsName),
    ),
    _ToolItem(
      label: (l) => 'Blood Donors',
      subtitle: 'Emergency nearby blood donor directory',
      icon: Icons.local_hospital_rounded,
      category: ToolCategory.medical,
      color: const Color(0xFFD90429),
      onTap: (c) => c.pushNamed(AppRoutes.bloodDonorsName),
    ),

    // 👶 Baby & Tracking
    _ToolItem(
      label: (l) => l.toolsKickCounter,
      subtitle: 'Count baby kicks & activity sessions',
      icon: Icons.child_care_rounded,
      category: ToolCategory.baby,
      color: const Color(0xFF7FC8A0),
      onTap: (c) => c.pushNamed(AppRoutes.kickCounterName),
    ),
    _ToolItem(
      label: (l) => l.toolsContractions,
      subtitle: 'Interval timer & labor progress',
      icon: Icons.timer_outlined,
      category: ToolCategory.baby,
      color: const Color(0xFFE5989B),
      onTap: (c) => c.pushNamed(AppRoutes.contractionTimerName),
    ),
    _ToolItem(
      label: (l) => l.toolsBabyNames,
      subtitle: 'Discover & vote on favorite names',
      icon: Icons.bookmark_rounded,
      category: ToolCategory.baby,
      color: const Color(0xFFF4A261),
      onTap: (c) => c.pushNamed(AppRoutes.babyNamesName),
    ),
    _ToolItem(
      label: (l) => l.toolsBirthPlan,
      subtitle: 'Create & export your delivery plan',
      icon: Icons.checklist_rtl_rounded,
      category: ToolCategory.baby,
      color: const Color(0xFF588157),
      onTap: (c) => c.pushNamed(AppRoutes.birthPlanName),
    ),
    _ToolItem(
      label: (l) => l.toolsWeekTracker,
      subtitle: 'Explore 40 weeks baby milestones',
      icon: Icons.calendar_today_rounded,
      category: ToolCategory.baby,
      color: const Color(0xFF6B9080),
      onTap: (c) => c.go(AppRoutes.tracker),
    ),

    // 💧 Daily Habits & Care
    _ToolItem(
      label: (l) => l.toolsWater,
      subtitle: 'Daily hydration tracker (glasses)',
      icon: Icons.water_drop_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFF3A86FF),
      onTap: (c) => c.pushNamed(AppRoutes.waterName),
    ),
    _ToolItem(
      label: (l) => l.toolsSymptoms,
      subtitle: 'Log nausea, cramps, back pain & notes',
      icon: Icons.healing_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFFFB8500),
      onTap: (c) => c.pushNamed(AppRoutes.symptomsName),
    ),
    _ToolItem(
      label: (l) => l.toolsWeight,
      subtitle: 'Monitor healthy trimester weight gain',
      icon: Icons.monitor_weight_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFF8338EC),
      onTap: (c) => c.pushNamed(AppRoutes.weightName),
    ),
    _ToolItem(
      label: (l) => l.toolsSleep,
      subtitle: 'Log sleep hours & sleep quality',
      icon: Icons.bedtime_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFF3F37C9),
      onTap: (c) => c.pushNamed(AppRoutes.sleepName),
    ),
    _ToolItem(
      label: (l) => l.toolsNutrition,
      subtitle: 'Healthy pregnancy recipes & food guide',
      icon: Icons.restaurant_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFF2A9D8F),
      onTap: (c) => c.pushNamed(AppRoutes.nutritionName),
    ),
    _ToolItem(
      label: (l) => l.toolsExercise,
      subtitle: 'Safe trimester workouts & prenatal yoga',
      icon: Icons.fitness_center_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFFE76F51),
      onTap: (c) => c.pushNamed(AppRoutes.exerciseName),
    ),
    _ToolItem(
      label: (l) => 'Mood Calendar',
      subtitle: 'Daily emotional tracking & check-ins',
      icon: Icons.mood_rounded,
      category: ToolCategory.habits,
      color: const Color(0xFFFFB703),
      onTap: (c) => c.pushNamed(AppRoutes.moodCalendarName),
    ),

    // ✨ Smart AI & Prep
    _ToolItem(
      label: (l) => l.toolsAiHealth,
      subtitle: 'Ask Mira maternal wellness assistant',
      icon: Icons.auto_awesome_rounded,
      category: ToolCategory.ai,
      color: const Color(0xFF8338EC),
      badge: 'AI',
      onTap: (c) => c.pushNamed(AppRoutes.aiToolsName),
    ),
    _ToolItem(
      label: (l) => 'Prescription Scanner',
      subtitle: 'Scan doctor scripts with camera AI',
      icon: Icons.document_scanner_rounded,
      category: ToolCategory.ai,
      color: const Color(0xFF4361EE),
      badge: 'Smart',
      onTap: (c) => c.pushNamed(AppRoutes.prescriptionScanName),
    ),
    _ToolItem(
      label: (l) => 'Lab Report Analyzer',
      subtitle: 'Understand lab results & values',
      icon: Icons.science_rounded,
      category: ToolCategory.ai,
      color: const Color(0xFF7209B7),
      badge: 'Smart',
      onTap: (c) => c.pushNamed(AppRoutes.labAnalysisName),
    ),
    _ToolItem(
      label: (l) => l.toolsHospitalBag,
      subtitle: 'Checklist for mom, baby & partner',
      icon: Icons.luggage_rounded,
      category: ToolCategory.ai,
      color: const Color(0xFFF72585),
      onTap: (c) => c.pushNamed(AppRoutes.hospitalBagName),
    ),
    _ToolItem(
      label: (l) => l.toolsShopping,
      subtitle: 'Nursery essentials & baby registry',
      icon: Icons.shopping_bag_rounded,
      category: ToolCategory.ai,
      color: const Color(0xFFB5179E),
      onTap: (c) => c.pushNamed(AppRoutes.shoppingName),
    ),

    // 🌸 Family & Memories
    _ToolItem(
      label: (l) => l.toolsMemories,
      subtitle: 'Bump photos & ultrasound scrapbook',
      icon: Icons.photo_library_rounded,
      category: ToolCategory.family,
      color: const Color(0xFFF472B6),
      onTap: (c) => c.pushNamed(AppRoutes.memoriesName),
    ),
    _ToolItem(
      label: (l) => l.toolsJournal,
      subtitle: 'Write thoughts, letters & milestones',
      icon: Icons.menu_book_rounded,
      category: ToolCategory.family,
      color: const Color(0xFFFB7185),
      onTap: (c) => c.pushNamed(AppRoutes.journalName),
    ),
    _ToolItem(
      label: (l) => l.toolsPartnerFamily,
      subtitle: 'Invite partner & loved ones to sync',
      icon: Icons.favorite_rounded,
      category: ToolCategory.family,
      color: const Color(0xFFE11D48),
      onTap: (c) => c.pushNamed(AppRoutes.partnerName),
    ),
    _ToolItem(
      label: (l) => l.toolsCommunity,
      subtitle: 'Connect with fellow expecting mothers',
      icon: Icons.forum_rounded,
      category: ToolCategory.family,
      color: const Color(0xFFDB2777),
      onTap: (c) => c.pushNamed(AppRoutes.communityName),
    ),
    _ToolItem(
      label: (l) => 'Reminders',
      subtitle: 'Manage all notifications & alarms',
      icon: Icons.alarm_rounded,
      category: ToolCategory.family,
      color: const Color(0xFF9333EA),
      onTap: (c) => c.pushNamed(AppRoutes.remindersName),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAdmin = ref.watch(isAdminProvider);
    final isDoctor = ref.watch(isDoctorProvider);

    final tools = [
      if (isAdmin)
        _ToolItem(
          label: (l) => 'Admin Console',
          subtitle: 'System metrics & user management',
          icon: Icons.admin_panel_settings_rounded,
          category: ToolCategory.medical,
          color: const Color(0xFF475569),
          badge: 'Admin',
          onTap: (c) => c.pushNamed(AppRoutes.adminName),
        ),
      if (isDoctor)
        _ToolItem(
          label: (l) => l.toolsDoctorPortal,
          subtitle: 'Patient review & clinical portal',
          icon: Icons.medical_services_rounded,
          category: ToolCategory.medical,
          color: const Color(0xFF0284C7),
          badge: 'Doctor',
          onTap: (c) => c.pushNamed(AppRoutes.doctorPortalName),
        ),
      ..._allTools,
    ];

    // Filter tools by category and search query
    final filteredTools = tools.where((tool) {
      final matchesCategory = _selectedCategory == ToolCategory.all ||
          tool.category == _selectedCategory;
      final labelText = tool.label(l10n).toLowerCase();
      final subtitleText = (tool.subtitle ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          labelText.contains(query) ||
          subtitleText.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              l10n.navTools,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            CuteSparkle(size: 16, color: scheme.primary),
          ],
        ),

        actions: [
          IconButton(
            tooltip: l10n.emergency,
            onPressed: () => context.pushNamed(AppRoutes.emergencyName),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE86A5E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Color(0xFFE86A5E), size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Box
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search tools, trackers & guides...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8C6875).withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: scheme.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: CuteFlower(size: 16, petalColor: scheme.primary),
                        ),
                  filled: true,
                  fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: BorderSide(
                      color: scheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Horizontal Category Pills
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: ToolCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = ToolCategory.values[idx];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : scheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? scheme.outlineVariant : cat.color.withValues(alpha: 0.25)),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Results count / Category header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    _selectedCategory == ToolCategory.all
                        ? 'All Tools (${filteredTools.length})'
                        : '${_selectedCategory.label} (${filteredTools.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCategory != ToolCategory.all ||
                      _searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = ToolCategory.all;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: Text(
                        'Reset Filters',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          // Categorized Tools Grid
          filteredTools.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        CuteSparkle(size: 36, color: scheme.primary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No tools found for "$_searchQuery"',
                          style: context.textStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Try searching for another keyword or change the category filter.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    120,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.isCompact ? 2 : 4,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: context.isCompact ? 1.05 : 1.15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = filteredTools[index];
                        return _CategorizedToolCard(
                          tool: tool,
                          index: index,
                        );
                      },
                      childCount: filteredTools.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CategorizedToolCard extends StatelessWidget {
  const _CategorizedToolCard({
    required this.tool,
    required this.index,
  });

  final _ToolItem tool;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return AnimatedEntrance(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => tool.onTap(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceContainer : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : tool.color.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? scheme.outlineVariant
                    : tool.color.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon bubble
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tool.color.withValues(alpha: 0.14),
                          border: Border.all(
                            color: tool.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(tool.icon, size: 22, color: tool.color),
                      ),
                      const Spacer(),
                      if (tool.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: tool.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tool.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        CuteSparkle(
                          size: 14,
                          color: tool.color.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    tool.label(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

