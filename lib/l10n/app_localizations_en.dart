// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pregnancy Companion';

  @override
  String get tagline => 'Your journey, cared for';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionDelete => 'Delete';

  @override
  String get navHome => 'Home';

  @override
  String get navTracker => 'Tracker';

  @override
  String get navTools => 'Tools';

  @override
  String get navCommunity => 'Community';

  @override
  String get navProfile => 'Profile';

  @override
  String weekLabel(int number) {
    return 'Week $number';
  }

  @override
  String daysToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days to go',
      one: '$count day to go',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get emergency => 'Emergency';

  @override
  String get medicalDisclaimer =>
      'This app provides general information and is not a substitute for professional medical advice. Always consult your doctor.';

  @override
  String dashGreeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get dashLoadingJourney => 'Loading your journey…';

  @override
  String dashTodayHeader(int day, int week) {
    return 'Today · Day $day of week $week';
  }

  @override
  String dashBabySize(String size) {
    return 'baby is the size of a $size';
  }

  @override
  String get dashSmileTitle => 'A little smile for today';

  @override
  String dashThisWeekSize(String size) {
    return 'This week · size of $size';
  }

  @override
  String get dashOpenWeekTracker => 'Open week tracker →';

  @override
  String get dashNutritionTip => 'Nutrition tip';

  @override
  String get dashMedicines => 'Medicines';

  @override
  String get dashWater => 'Water';

  @override
  String get dashNextAppointment => 'Next appointment';

  @override
  String get dashNoneScheduled => 'None scheduled';

  @override
  String get dashEmergencyBanner =>
      'Emergency & SOS — quick help when you need it';

  @override
  String dashSosRaised(String name) {
    return '$name raised an SOS — tap for help';
  }

  @override
  String get dashResolve => 'Resolve';

  @override
  String dashProgressJourney(int percent) {
    return '$percent% of your journey';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileYourProfile => 'Your profile';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get sectionPregnancy => 'Pregnancy';

  @override
  String get fieldCurrentWeek => 'Current week';

  @override
  String get fieldDueDate => 'Due date';

  @override
  String get fieldRisk => 'Risk';

  @override
  String get fieldDoctor => 'Doctor';

  @override
  String get fieldHospital => 'Hospital';

  @override
  String get fieldBloodGroup => 'Blood group';

  @override
  String get profileEditPregnancy => 'Edit pregnancy details';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get settingTheme => 'Theme';

  @override
  String get settingLanguage => 'Language';

  @override
  String get settingTextSize => 'Text size';

  @override
  String get sectionAbout => 'About';

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutTerms => 'Terms of service';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and data. This cannot be undone.';

  @override
  String get deleteAccountPasswordLabel => 'Enter your password to confirm';

  @override
  String get deleteAccountReauthNote =>
      'You’ll be asked to confirm your identity to continue.';

  @override
  String get deleteAccountError =>
      'Could not delete account. Please try again.';

  @override
  String get avatarChangePhoto => 'Change photo';

  @override
  String get avatarRemovePhoto => 'Remove photo';

  @override
  String get toolsMedicines => 'Medicines';

  @override
  String get toolsAppointments => 'Appointments';

  @override
  String get toolsSymptoms => 'Symptoms';

  @override
  String get toolsWater => 'Water';

  @override
  String get toolsWeight => 'Weight';

  @override
  String get toolsKickCounter => 'Kick counter';

  @override
  String get toolsContractions => 'Contractions';

  @override
  String get toolsReport => 'Report';

  @override
  String get toolsBloodPressure => 'Blood pressure';

  @override
  String get toolsBloodSugar => 'Blood sugar';

  @override
  String get toolsSleep => 'Sleep';

  @override
  String get toolsVaccinations => 'Vaccinations';

  @override
  String get toolsHospitalBag => 'Hospital bag';

  @override
  String get toolsReportsInsights => 'Reports & Insights';

  @override
  String get toolsNutrition => 'Nutrition';

  @override
  String get toolsExercise => 'Exercise';

  @override
  String get toolsCalendar => 'Calendar';

  @override
  String get toolsJournal => 'Journal';

  @override
  String get toolsMemories => 'Memories';

  @override
  String get toolsPartnerFamily => 'Partner & family';

  @override
  String get toolsAiHealth => 'AI health tools';

  @override
  String get toolsCommunity => 'Community';

  @override
  String get toolsBabyNames => 'Baby names';

  @override
  String get toolsBirthPlan => 'Birth plan';

  @override
  String get toolsShopping => 'Shopping list';

  @override
  String get toolsPremium => 'Premium';

  @override
  String get toolsWeekTracker => 'Week tracker';

  @override
  String get toolsEmergency => 'Emergency';

  @override
  String get toolsDoctorPortal => 'Doctor portal';
}
