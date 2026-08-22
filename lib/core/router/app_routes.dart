/// Centralized route paths & names. Referencing these constants instead of raw
/// strings keeps navigation refactor-safe and enables deep links.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String splashName = 'splash';

  // Auth & onboarding (implemented in Phase 3)
  static const String onboarding = '/onboarding';
  static const String onboardingName = 'onboarding';
  static const String login = '/login';
  static const String loginName = 'login';
  static const String register = '/register';
  static const String registerName = 'register';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordName = 'forgotPassword';
  static const String phoneAuth = '/phone';
  static const String phoneAuthName = 'phoneAuth';
  static const String profileSetup = '/profile-setup';
  static const String profileSetupName = 'profileSetup';

  // Main app shell tabs
  static const String home = '/home';
  static const String homeName = 'home';
  static const String tracker = '/tracker';
  static const String trackerName = 'tracker';
  static const String tools = '/tools';
  static const String toolsName = 'tools';
  static const String profile = '/profile';
  static const String profileName = 'profile';
  static const String editProfile = '/edit-profile';
  static const String editProfileName = 'editProfile';
  static const String editPregnancy = '/edit-pregnancy';
  static const String editPregnancyName = 'editPregnancy';

  // Pushed (full-screen) routes
  static const String emergency = '/emergency';
  static const String emergencyName = 'emergency';

  // Trackers (pushed full-screen from Tools / dashboard)
  static const String medicines = '/medicines';
  static const String medicinesName = 'medicines';
  static const String appointments = '/appointments';
  static const String appointmentsName = 'appointments';
  static const String symptoms = '/symptoms';
  static const String symptomsName = 'symptoms';
  static const String water = '/water';
  static const String waterName = 'water';
  static const String weight = '/weight';
  static const String weightName = 'weight';
  static const String kickCounter = '/kick-counter';
  static const String kickCounterName = 'kickCounter';
  static const String contractionTimer = '/contraction-timer';
  static const String contractionTimerName = 'contractionTimer';
  static const String movementReport = '/movement-report';
  static const String movementReportName = 'movementReport';
  static const String bloodPressure = '/blood-pressure';
  static const String bloodPressureName = 'bloodPressure';
  static const String bloodSugar = '/blood-sugar';
  static const String bloodSugarName = 'bloodSugar';
  static const String sleep = '/sleep';
  static const String sleepName = 'sleep';
  static const String vaccinations = '/vaccinations';
  static const String vaccinationsName = 'vaccinations';
  static const String hospitalBag = '/hospital-bag';
  static const String hospitalBagName = 'hospitalBag';
  static const String healthReport = '/health-report';
  static const String healthReportName = 'healthReport';
  static const String reports = '/reports';
  static const String reportsName = 'reports';
  static const String insights = '/insights';
  static const String insightsName = 'insights';
  static const String prescriptionScan = '/scan-prescription';
  static const String prescriptionScanName = 'prescriptionScan';
  static const String labAnalysis = '/analyze-lab';
  static const String labAnalysisName = 'labAnalysis';
  static const String nutrition = '/nutrition';
  static const String nutritionName = 'nutrition';
  static const String exercise = '/exercise';
  static const String exerciseName = 'exercise';
  static const String calendar = '/calendar';
  static const String calendarName = 'calendar';
  static const String journal = '/journal';
  static const String journalName = 'journal';
  static const String moodCalendar = '/mood-calendar';
  static const String moodCalendarName = 'moodCalendar';
  static const String partner = '/partner';
  static const String partnerName = 'partner';
  static const String aiAssistant = '/assistant';
  static const String aiAssistantName = 'aiAssistant';
  static const String aiTools = '/ai-tools';
  static const String aiToolsName = 'aiTools';
  static const String symptomChecker = '/symptom-checker';
  static const String symptomCheckerName = 'symptomChecker';
  static const String mealPlanner = '/meal-planner';
  static const String mealPlannerName = 'mealPlanner';
  static const String wellnessPlan = '/wellness-plan';
  static const String wellnessPlanName = 'wellnessPlan';
  static const String weeklySummary = '/weekly-summary';
  static const String weeklySummaryName = 'weeklySummary';
  static const String community = '/community';
  static const String communityName = 'community';
  static const String babyNames = '/baby-names';
  static const String babyNamesName = 'babyNames';
  static const String nameIdeas = '/name-ideas';
  static const String nameIdeasName = 'nameIdeas';
  static const String birthPlan = '/birth-plan';
  static const String birthPlanName = 'birthPlan';
  static const String doctorPortal = '/doctor';
  static const String doctorPortalName = 'doctorPortal';
  static const String shopping = '/shopping';
  static const String shoppingName = 'shopping';
  static const String premium = '/premium';
  static const String premiumName = 'premium';
  static const String memories = '/memories';
  static const String memoriesName = 'memories';
  static const String fixAccess = '/fix-access';
  static const String fixAccessName = 'fixAccess';
  static const String bloodDonors = '/blood-donors';
  static const String bloodDonorsName = 'bloodDonors';
  static const String admin = '/admin';
  static const String adminName = 'admin';
  static const String reminders = '/reminders-list';
  static const String remindersName = 'remindersList';
}
