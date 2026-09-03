import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../appointments/presentation/appointment_providers.dart';
import '../../emergency/presentation/emergency_providers.dart';
import '../../medicine/presentation/medicine_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../../water/presentation/water_providers.dart';

/// Care Hub: Centralized medical and wellness center.
///
/// Houses vitals logging, medicines, doctor appointments, lab scans,
/// and emergency access in a calm, uncluttered "Serene Bloom" layout.
class CareHubScreen extends ConsumerWidget {
  const CareHubScreen({super.key});

  Future<void> _dialAmbulance(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '108');
    if (!await launchUrl(uri) && context.mounted) {
      context.showSnack('Could not dial ambulance (108).', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(activePregnancyProvider).valueOrNull;
    final waterState = ref.watch(todayWaterProvider).valueOrNull;
    final doses = ref.watch(todayDosesProvider);
    final allAppointments = ref.watch(appointmentsProvider).valueOrNull ?? const [];
    final primaryContact = ref.watch(primaryContactProvider);

    final pendingDoses = doses.where((d) => d.status != DoseStatus.taken).length;
    final upcoming = allAppointments.where((a) => a.isUpcoming).toList();
    final nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
    final waterPercent = (waterState != null && waterState.goalMl > 0)
        ? (waterState.consumedMl / waterState.goalMl).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Care & Health Hub',
          style: context.textStyles.titleLarge?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency SOS',
            onPressed: () => context.pushNamed(AppRoutes.emergencyName),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sos_rounded,
                color: context.colors.error,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          120,
        ),
        children: [
          // ==================== 1. EMERGENCY FAST ACTION BANNER ====================
          _EmergencyFastBanner(
            onSosTap: () => context.pushNamed(AppRoutes.emergencyName),
            onAmbulanceTap: () => _dialAmbulance(context),
            primaryContactPhone: primaryContact?.phone,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 2. DAILY VITALS & HEALTH LOGS ====================
          _SectionTitle(
            title: 'Daily Health Vitals',
            subtitle: 'Log and monitor your clinical stats',
            actionLabel: 'View All',
            onActionTap: () => context.pushNamed(AppRoutes.reportsName),
          ),
          const SizedBox(height: AppSpacing.md),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.25,
            children: [
              _VitalCard(
                title: 'Water Intake',
                value: '${waterState?.consumedMl ?? 0} ml',
                subtitle: 'Goal: ${(waterState?.goalMl ?? 2500) / 1000} L',
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF38BDF8),
                progress: waterPercent,
                onTap: () => context.pushNamed(AppRoutes.waterName),
              ),
              _VitalCard(
                title: 'Blood Pressure',
                value: 'Check BP',
                subtitle: 'Log systolic/diastolic',
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFF43F5E),
                onTap: () => context.pushNamed(AppRoutes.bloodPressureName),
              ),
              _VitalCard(
                title: 'Blood Sugar',
                value: 'Glucose log',
                subtitle: 'Fasting / Post-meal',
                icon: Icons.bloodtype_rounded,
                iconColor: const Color(0xFFE87A90),
                onTap: () => context.pushNamed(AppRoutes.bloodSugarName),
              ),
              _VitalCard(
                title: 'Weight Tracker',
                value: 'Weight gain',
                subtitle: 'Track healthy curve',
                icon: Icons.monitor_weight_rounded,
                iconColor: const Color(0xFF10B981),
                onTap: () => context.pushNamed(AppRoutes.weightName),
              ),
              _VitalCard(
                title: 'Sleep Tracker',
                value: 'Rest log',
                subtitle: 'Quality & bedtime',
                icon: Icons.bedtime_rounded,
                iconColor: const Color(0xFF8B5CF6),
                onTap: () => context.pushNamed(AppRoutes.sleepName),
              ),
              _VitalCard(
                title: 'Symptoms',
                value: 'Log symptom',
                subtitle: 'Track daily changes',
                icon: Icons.healing_rounded,
                iconColor: const Color(0xFFF59E0B),
                onTap: () => context.pushNamed(AppRoutes.symptomsName),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 3. MEDICINES & REMINDERS ====================
          _SectionTitle(
            title: 'Medicines & Care Schedule',
            subtitle: 'Stay on track with prescribed doses',
            actionLabel: 'Manage',
            onActionTap: () => context.pushNamed(AppRoutes.medicinesName),
          ),
          const SizedBox(height: AppSpacing.md),

          AppCard(
            onTap: () => context.pushNamed(AppRoutes.medicinesName),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingDoses == 0
                            ? 'All doses completed for today! 🎉'
                            : '$pendingDoses dose${pendingDoses == 1 ? '' : 's'} remaining today',
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to view schedule and log intake',
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
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 4. APPOINTMENTS & DOCTOR ====================
          _SectionTitle(
            title: 'Doctor & Hospital Visits',
            subtitle: 'Upcoming prenatal checkups',
            actionLabel: 'Calendar',
            onActionTap: () => context.pushNamed(AppRoutes.appointmentsName),
          ),
          const SizedBox(height: AppSpacing.md),

          AppCard(
            onTap: () => context.pushNamed(AppRoutes.appointmentsName),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextAppointment != null
                            ? 'Next: ${nextAppointment.title}'
                            : (pregnancy?.doctorName != null
                                ? 'Dr. ${pregnancy!.doctorName}'
                                : 'No upcoming visits scheduled'),
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pregnancy?.hospital ?? 'Tap to schedule appointments & reminders',
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
          ),

          const SizedBox(height: AppSpacing.xl),

          // ==================== 5. SMART MEDICAL SCANS & REPORTS ====================
          _SectionTitle(
            title: 'Medical Scans & Reports',
            subtitle: 'AI analysis and clinical export',
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _FeatureActionTile(
                  title: 'Prescription Scan',
                  subtitle: 'AI Medicine Decoder',
                  icon: Icons.document_scanner_rounded,
                  iconColor: const Color(0xFF6366F1),
                  onTap: () => context.pushNamed(AppRoutes.prescriptionScanName),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FeatureActionTile(
                  title: 'Lab Analysis',
                  subtitle: 'Blood & Urine Tests',
                  icon: Icons.biotech_rounded,
                  iconColor: const Color(0xFFEC4899),
                  onTap: () => context.pushNamed(AppRoutes.labAnalysisName),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _FeatureActionTile(
                  title: 'Health Report',
                  subtitle: 'Export PDF for Doctor',
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  onTap: () => context.pushNamed(AppRoutes.healthReportName),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FeatureActionTile(
                  title: 'Blood Donors',
                  subtitle: 'Emergency Network',
                  icon: Icons.volunteer_activism_rounded,
                  iconColor: const Color(0xFFEF4444),
                  onTap: () => context.pushNamed(AppRoutes.bloodDonorsName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- Helper Widgets ----------------

class _EmergencyFastBanner extends StatelessWidget {
  const _EmergencyFastBanner({
    required this.onSosTap,
    required this.onAmbulanceTap,
    this.primaryContactPhone,
  });

  final VoidCallback onSosTap;
  final VoidCallback onAmbulanceTap;
  final String? primaryContactPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE11D48),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency & Urgent Help',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                    Text(
                      '1-Tap SOS alert and direct medical hotlines',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF9F1239).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSosTap,
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text('Trigger SOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAmbulanceTap,
                  icon: const Icon(Icons.local_hospital_rounded, size: 18),
                  label: const Text('Call 108'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9F1239),
                    side: const BorderSide(color: Color(0xFFFDA4AF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.progress,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                title,
                style: context.textStyles.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.textStyles.bodySmall?.copyWith(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureActionTile extends StatelessWidget {
  const _FeatureActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
