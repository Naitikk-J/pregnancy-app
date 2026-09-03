import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/ai_tools/presentation/ai_tools_hub_screen.dart';
import '../../features/ai_tools/presentation/meal_planner_screen.dart';
import '../../features/ai_tools/presentation/symptom_checker_screen.dart';
import '../../features/ai_tools/presentation/weekly_summary_screen.dart';
import '../../features/ai_tools/presentation/wellness_plan_screen.dart';
import '../../features/app_shell/presentation/main_shell.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import '../../features/baby_names/presentation/ai_name_ideas_screen.dart';
import '../../features/baby_names/presentation/baby_names_screen.dart';
import '../../features/birth_plan/presentation/birth_plan_screen.dart';
import '../../features/blood_donors/presentation/blood_donors_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/doctor/presentation/doctor_portal_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_carousel_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/blood_pressure/presentation/bp_screen.dart';
import '../../features/blood_sugar/presentation/glucose_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/care/presentation/care_hub_screen.dart';
import '../../features/contractions/presentation/contraction_timer_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/exercise/presentation/exercise_screen.dart';
import '../../features/hospital_bag/presentation/hospital_bag_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/kick_counter/presentation/kick_counter_screen.dart';
import '../../features/medicine/presentation/medicine_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/memories/presentation/memories_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/mood/presentation/mood_calendar_screen.dart';
import '../../features/nutrition/presentation/nutrition_screen.dart';
import '../../features/partner/presentation/partner_screen.dart';
import '../../features/document_scan/presentation/lab_analysis_screen.dart';
import '../../features/document_scan/presentation/prescription_scan_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/reports/presentation/health_report_screen.dart';
import '../../features/reports/presentation/reports_hub_screen.dart';
import '../../features/reports/presentation/report_screen.dart';
import '../../features/sleep/presentation/sleep_screen.dart';
import '../../features/vaccination/presentation/vaccination_screen.dart';
import '../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../features/profile/presentation/screens/edit_pregnancy_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_tab_screen.dart';
import '../../features/recovery/presentation/pregnancy_recovery_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/symptoms/presentation/symptoms_screen.dart';
import '../../features/tools/presentation/tools_screen.dart';
import '../../features/water/presentation/water_screen.dart';
import '../../features/week_tracker/presentation/screens/week_tracker_screen.dart';
import '../../features/weight/presentation/weight_screen.dart';
import '../di/providers.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Central router. A [_RouterNotifier] listens to [authUserProvider] and drives
/// GoRouter's `refreshListenable` + `redirect`, so navigation reacts to
/// sign-in, sign-out and onboarding completion automatically.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  final analytics = ref.watch(analyticsServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [analytics.navigatorObserver],
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),

      // --- Auth & onboarding ---
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingCarouselScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        name: AppRoutes.phoneAuthName,
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: AppRoutes.profileSetupName,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // --- Full-screen pushed routes (cover the bottom nav) ---
      GoRoute(
        path: AppRoutes.emergency,
        name: AppRoutes.emergencyName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: AppRoutes.medicines,
        name: AppRoutes.medicinesName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MedicineScreen(),
      ),
      GoRoute(
        path: AppRoutes.appointments,
        name: AppRoutes.appointmentsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.symptoms,
        name: AppRoutes.symptomsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SymptomsScreen(),
      ),
      GoRoute(
        path: AppRoutes.water,
        name: AppRoutes.waterName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WaterScreen(),
      ),
      GoRoute(
        path: AppRoutes.weight,
        name: AppRoutes.weightName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeightScreen(),
      ),
      GoRoute(
        path: AppRoutes.kickCounter,
        name: AppRoutes.kickCounterName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KickCounterScreen(),
      ),
      GoRoute(
        path: AppRoutes.contractionTimer,
        name: AppRoutes.contractionTimerName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContractionTimerScreen(),
      ),
      GoRoute(
        path: AppRoutes.movementReport,
        name: AppRoutes.movementReportName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MovementReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.bloodPressure,
        name: AppRoutes.bloodPressureName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BpScreen(),
      ),
      GoRoute(
        path: AppRoutes.bloodSugar,
        name: AppRoutes.bloodSugarName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GlucoseScreen(),
      ),
      GoRoute(
        path: AppRoutes.sleep,
        name: AppRoutes.sleepName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SleepScreen(),
      ),
      GoRoute(
        path: AppRoutes.vaccinations,
        name: AppRoutes.vaccinationsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VaccinationScreen(),
      ),
      GoRoute(
        path: AppRoutes.hospitalBag,
        name: AppRoutes.hospitalBagName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HospitalBagScreen(),
      ),
      GoRoute(
        path: AppRoutes.healthReport,
        name: AppRoutes.healthReportName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HealthReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: AppRoutes.reportsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.insights,
        name: AppRoutes.insightsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: AppRoutes.prescriptionScan,
        name: AppRoutes.prescriptionScanName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrescriptionScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.labAnalysis,
        name: AppRoutes.labAnalysisName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LabAnalysisScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiTools,
        name: AppRoutes.aiToolsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiToolsHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.symptomChecker,
        name: AppRoutes.symptomCheckerName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SymptomCheckerScreen(),
      ),
      GoRoute(
        path: AppRoutes.mealPlanner,
        name: AppRoutes.mealPlannerName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MealPlannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.wellnessPlan,
        name: AppRoutes.wellnessPlanName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WellnessPlanScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklySummary,
        name: AppRoutes.weeklySummaryName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeeklySummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.nutrition,
        name: AppRoutes.nutritionName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        path: AppRoutes.exercise,
        name: AppRoutes.exerciseName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        name: AppRoutes.calendarName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.journal,
        name: AppRoutes.journalName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: AppRoutes.moodCalendar,
        name: AppRoutes.moodCalendarName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MoodCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: AppRoutes.adminName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        name: AppRoutes.remindersName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: AppRoutes.partner,
        name: AppRoutes.partnerName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PartnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        name: AppRoutes.aiAssistantName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.community,
        name: AppRoutes.communityName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: AppRoutes.babyNames,
        name: AppRoutes.babyNamesName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BabyNamesScreen(),
      ),
      GoRoute(
        path: AppRoutes.nameIdeas,
        name: AppRoutes.nameIdeasName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiNameIdeasScreen(),
      ),
      GoRoute(
        path: AppRoutes.birthPlan,
        name: AppRoutes.birthPlanName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BirthPlanScreen(),
      ),
      GoRoute(
        path: AppRoutes.doctorPortal,
        name: AppRoutes.doctorPortalName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DoctorPortalScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopping,
        name: AppRoutes.shoppingName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShoppingScreen(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        name: AppRoutes.premiumName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: AppRoutes.memories,
        name: AppRoutes.memoriesName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MemoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.fixAccess,
        name: AppRoutes.fixAccessName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PregnancyRecoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.bloodDonors,
        name: AppRoutes.bloodDonorsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BloodDonorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileTabScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.editProfileName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editPregnancy,
        name: AppRoutes.editPregnancyName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditPregnancyScreen(),
      ),

      // --- Main tabbed shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tracker,
                name: AppRoutes.trackerName,
                builder: (context, state) => const WeekTrackerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.care,
                name: AppRoutes.careName,
                builder: (context, state) => const CareHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tools,
                name: AppRoutes.toolsName,
                builder: (context, state) => const ToolsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});

/// Bridges Riverpod auth state to GoRouter and centralizes redirect rules.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _sub = _ref.listen(
      authUserProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<Object?> _sub;

  static const _authRoutes = {
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.phoneAuth,
  };

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authUserProvider);
    final loc = state.matchedLocation;
    final atSplash = loc == AppRoutes.splash;
    final atAuthRoute = _authRoutes.contains(loc);

    // Still resolving the very first auth state → show the splash.
    if (auth.isLoading && !auth.hasValue) {
      return atSplash ? null : AppRoutes.splash;
    }
    // An auth error with no user → treat as signed-out and send to login,
    // never leave the user stuck on the splash.
    if (auth.hasError && !auth.hasValue) {
      return atAuthRoute ? null : AppRoutes.onboarding;
    }

    final user = auth.valueOrNull;

    if (user == null) {
      return atAuthRoute ? null : AppRoutes.onboarding;
    }

    if (!user.onboardingComplete) {
      return loc == AppRoutes.profileSetup ? null : AppRoutes.profileSetup;
    }

    if (atSplash || atAuthRoute || loc == AppRoutes.profileSetup) {
      return AppRoutes.home;
    }
    return null;
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
