import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Companion'**
  String get appName;

  /// Splash screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Your journey, cared for'**
  String get tagline;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTracker.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get navTracker;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Current pregnancy week
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String weekLabel(int number);

  /// Days remaining until due date
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Due today} one{{count} day to go} other{{count} days to go}}'**
  String daysToGo(int count);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app provides general information and is not a substitute for professional medical advice. Always consult your doctor.'**
  String get medicalDisclaimer;

  /// Home screen greeting
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String dashGreeting(String name);

  /// No description provided for @dashLoadingJourney.
  ///
  /// In en, this message translates to:
  /// **'Loading your journey…'**
  String get dashLoadingJourney;

  /// No description provided for @dashTodayHeader.
  ///
  /// In en, this message translates to:
  /// **'Today · Day {day} of week {week}'**
  String dashTodayHeader(int day, int week);

  /// No description provided for @dashBabySize.
  ///
  /// In en, this message translates to:
  /// **'baby is the size of a {size}'**
  String dashBabySize(String size);

  /// No description provided for @dashSmileTitle.
  ///
  /// In en, this message translates to:
  /// **'A little smile for today'**
  String get dashSmileTitle;

  /// No description provided for @dashThisWeekSize.
  ///
  /// In en, this message translates to:
  /// **'This week · size of {size}'**
  String dashThisWeekSize(String size);

  /// No description provided for @dashOpenWeekTracker.
  ///
  /// In en, this message translates to:
  /// **'Open week tracker →'**
  String get dashOpenWeekTracker;

  /// No description provided for @dashNutritionTip.
  ///
  /// In en, this message translates to:
  /// **'Nutrition tip'**
  String get dashNutritionTip;

  /// No description provided for @dashMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get dashMedicines;

  /// No description provided for @dashWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get dashWater;

  /// No description provided for @dashNextAppointment.
  ///
  /// In en, this message translates to:
  /// **'Next appointment'**
  String get dashNextAppointment;

  /// No description provided for @dashNoneScheduled.
  ///
  /// In en, this message translates to:
  /// **'None scheduled'**
  String get dashNoneScheduled;

  /// No description provided for @dashEmergencyBanner.
  ///
  /// In en, this message translates to:
  /// **'Emergency & SOS — quick help when you need it'**
  String get dashEmergencyBanner;

  /// No description provided for @dashSosRaised.
  ///
  /// In en, this message translates to:
  /// **'{name} raised an SOS — tap for help'**
  String dashSosRaised(String name);

  /// No description provided for @dashResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get dashResolve;

  /// No description provided for @dashProgressJourney.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your journey'**
  String dashProgressJourney(int percent);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileYourProfile;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @sectionPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy'**
  String get sectionPregnancy;

  /// No description provided for @fieldCurrentWeek.
  ///
  /// In en, this message translates to:
  /// **'Current week'**
  String get fieldCurrentWeek;

  /// No description provided for @fieldDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get fieldDueDate;

  /// No description provided for @fieldRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get fieldRisk;

  /// No description provided for @fieldDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get fieldDoctor;

  /// No description provided for @fieldHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get fieldHospital;

  /// No description provided for @fieldBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get fieldBloodGroup;

  /// No description provided for @profileEditPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Edit pregnancy details'**
  String get profileEditPregnancy;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @settingTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingTheme;

  /// No description provided for @settingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// No description provided for @settingTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingTextSize;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacy;

  /// No description provided for @aboutTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get aboutTerms;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @actionDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get actionDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and data. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountReauthNote.
  ///
  /// In en, this message translates to:
  /// **'You’ll be asked to confirm your identity to continue.'**
  String get deleteAccountReauthNote;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account. Please try again.'**
  String get deleteAccountError;

  /// No description provided for @avatarChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get avatarChangePhoto;

  /// No description provided for @avatarRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get avatarRemovePhoto;

  /// No description provided for @toolsMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get toolsMedicines;

  /// No description provided for @toolsAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get toolsAppointments;

  /// No description provided for @toolsSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get toolsSymptoms;

  /// No description provided for @toolsWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get toolsWater;

  /// No description provided for @toolsWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get toolsWeight;

  /// No description provided for @toolsKickCounter.
  ///
  /// In en, this message translates to:
  /// **'Kick counter'**
  String get toolsKickCounter;

  /// No description provided for @toolsContractions.
  ///
  /// In en, this message translates to:
  /// **'Contractions'**
  String get toolsContractions;

  /// No description provided for @toolsReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get toolsReport;

  /// No description provided for @toolsBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get toolsBloodPressure;

  /// No description provided for @toolsBloodSugar.
  ///
  /// In en, this message translates to:
  /// **'Blood sugar'**
  String get toolsBloodSugar;

  /// No description provided for @toolsSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get toolsSleep;

  /// No description provided for @toolsVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get toolsVaccinations;

  /// No description provided for @toolsHospitalBag.
  ///
  /// In en, this message translates to:
  /// **'Hospital bag'**
  String get toolsHospitalBag;

  /// No description provided for @toolsReportsInsights.
  ///
  /// In en, this message translates to:
  /// **'Reports & Insights'**
  String get toolsReportsInsights;

  /// No description provided for @toolsNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get toolsNutrition;

  /// No description provided for @toolsExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get toolsExercise;

  /// No description provided for @toolsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get toolsCalendar;

  /// No description provided for @toolsJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get toolsJournal;

  /// No description provided for @toolsMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get toolsMemories;

  /// No description provided for @toolsPartnerFamily.
  ///
  /// In en, this message translates to:
  /// **'Partner & family'**
  String get toolsPartnerFamily;

  /// No description provided for @toolsAiHealth.
  ///
  /// In en, this message translates to:
  /// **'AI health tools'**
  String get toolsAiHealth;

  /// No description provided for @toolsCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get toolsCommunity;

  /// No description provided for @toolsBabyNames.
  ///
  /// In en, this message translates to:
  /// **'Baby names'**
  String get toolsBabyNames;

  /// No description provided for @toolsBirthPlan.
  ///
  /// In en, this message translates to:
  /// **'Birth plan'**
  String get toolsBirthPlan;

  /// No description provided for @toolsShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get toolsShopping;

  /// No description provided for @toolsPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get toolsPremium;

  /// No description provided for @toolsWeekTracker.
  ///
  /// In en, this message translates to:
  /// **'Week tracker'**
  String get toolsWeekTracker;

  /// No description provided for @toolsEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get toolsEmergency;

  /// No description provided for @toolsDoctorPortal.
  ///
  /// In en, this message translates to:
  /// **'Doctor portal'**
  String get toolsDoctorPortal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
