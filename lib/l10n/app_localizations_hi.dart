// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'प्रेगनेंसी कम्पैनियन';

  @override
  String get tagline => 'आपकी यात्रा, हमारी देखभाल';

  @override
  String get actionContinue => 'जारी रखें';

  @override
  String get actionNext => 'आगे';

  @override
  String get actionBack => 'पीछे';

  @override
  String get actionSkip => 'छोड़ें';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionRetry => 'पुनः प्रयास करें';

  @override
  String get actionDelete => 'हटाएँ';

  @override
  String get navHome => 'होम';

  @override
  String get navTracker => 'ट्रैकर';

  @override
  String get navTools => 'टूल्स';

  @override
  String get navCommunity => 'समुदाय';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String weekLabel(int number) {
    return 'सप्ताह $number';
  }

  @override
  String daysToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन शेष',
      one: '$count दिन शेष',
      zero: 'आज नियत है',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get emergency => 'आपातकाल';

  @override
  String get medicalDisclaimer =>
      'यह ऐप सामान्य जानकारी प्रदान करता है और पेशेवर चिकित्सा सलाह का विकल्प नहीं है। हमेशा अपने डॉक्टर से परामर्श करें।';

  @override
  String dashGreeting(String name) {
    return 'नमस्ते, $name 👋';
  }

  @override
  String get dashLoadingJourney => 'आपकी यात्रा लोड हो रही है…';

  @override
  String dashTodayHeader(int day, int week) {
    return 'आज · सप्ताह $week का दिन $day';
  }

  @override
  String dashBabySize(String size) {
    return 'शिशु का आकार $size जितना है';
  }

  @override
  String get dashSmileTitle => 'आज के लिए एक छोटी सी मुस्कान';

  @override
  String dashThisWeekSize(String size) {
    return 'इस सप्ताह · आकार $size जितना';
  }

  @override
  String get dashOpenWeekTracker => 'सप्ताह ट्रैकर खोलें →';

  @override
  String get dashNutritionTip => 'पोषण सुझाव';

  @override
  String get dashMedicines => 'दवाइयाँ';

  @override
  String get dashWater => 'पानी';

  @override
  String get dashNextAppointment => 'अगली अपॉइंटमेंट';

  @override
  String get dashNoneScheduled => 'कोई निर्धारित नहीं';

  @override
  String get dashEmergencyBanner =>
      'आपातकाल और SOS — ज़रूरत पड़ने पर तुरंत मदद';

  @override
  String dashSosRaised(String name) {
    return '$name ने SOS भेजा है — मदद के लिए टैप करें';
  }

  @override
  String get dashResolve => 'हल करें';

  @override
  String dashProgressJourney(int percent) {
    return 'आपकी यात्रा का $percent%';
  }

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileYourProfile => 'आपकी प्रोफ़ाइल';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get sectionPregnancy => 'गर्भावस्था';

  @override
  String get fieldCurrentWeek => 'वर्तमान सप्ताह';

  @override
  String get fieldDueDate => 'नियत तिथि';

  @override
  String get fieldRisk => 'जोखिम';

  @override
  String get fieldDoctor => 'डॉक्टर';

  @override
  String get fieldHospital => 'अस्पताल';

  @override
  String get fieldBloodGroup => 'रक्त समूह';

  @override
  String get profileEditPregnancy => 'गर्भावस्था विवरण संपादित करें';

  @override
  String get sectionAppearance => 'रूप-रंग';

  @override
  String get settingTheme => 'थीम';

  @override
  String get settingLanguage => 'भाषा';

  @override
  String get settingTextSize => 'टेक्स्ट आकार';

  @override
  String get sectionAbout => 'जानकारी';

  @override
  String get aboutPrivacy => 'गोपनीयता नीति';

  @override
  String get aboutTerms => 'सेवा की शर्तें';

  @override
  String get actionSignOut => 'साइन आउट';

  @override
  String get actionDeleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountTitle => 'खाता हटाएँ?';

  @override
  String get deleteAccountBody =>
      'इससे आपका खाता और डेटा स्थायी रूप से हट जाएगा। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get deleteAccountPasswordLabel =>
      'पुष्टि के लिए अपना पासवर्ड दर्ज करें';

  @override
  String get deleteAccountReauthNote =>
      'जारी रखने के लिए आपसे आपकी पहचान की पुष्टि करने को कहा जाएगा।';

  @override
  String get deleteAccountError =>
      'खाता नहीं हटाया जा सका। कृपया फिर से प्रयास करें।';

  @override
  String get avatarChangePhoto => 'फ़ोटो बदलें';

  @override
  String get avatarRemovePhoto => 'फ़ोटो हटाएँ';

  @override
  String get toolsMedicines => 'दवाइयाँ';

  @override
  String get toolsAppointments => 'अपॉइंटमेंट';

  @override
  String get toolsSymptoms => 'लक्षण';

  @override
  String get toolsWater => 'पानी';

  @override
  String get toolsWeight => 'वज़न';

  @override
  String get toolsKickCounter => 'किक काउंटर';

  @override
  String get toolsContractions => 'संकुचन';

  @override
  String get toolsReport => 'रिपोर्ट';

  @override
  String get toolsBloodPressure => 'रक्तचाप';

  @override
  String get toolsBloodSugar => 'रक्त शर्करा';

  @override
  String get toolsSleep => 'नींद';

  @override
  String get toolsVaccinations => 'टीकाकरण';

  @override
  String get toolsHospitalBag => 'अस्पताल बैग';

  @override
  String get toolsReportsInsights => 'रिपोर्ट और अंतर्दृष्टि';

  @override
  String get toolsNutrition => 'पोषण';

  @override
  String get toolsExercise => 'व्यायाम';

  @override
  String get toolsCalendar => 'कैलेंडर';

  @override
  String get toolsJournal => 'डायरी';

  @override
  String get toolsMemories => 'यादें';

  @override
  String get toolsPartnerFamily => 'साथी और परिवार';

  @override
  String get toolsAiHealth => 'AI स्वास्थ्य टूल्स';

  @override
  String get toolsCommunity => 'समुदाय';

  @override
  String get toolsBabyNames => 'शिशु नाम';

  @override
  String get toolsBirthPlan => 'जन्म योजना';

  @override
  String get toolsShopping => 'खरीदारी सूची';

  @override
  String get toolsPremium => 'प्रीमियम';

  @override
  String get toolsWeekTracker => 'सप्ताह ट्रैकर';

  @override
  String get toolsEmergency => 'आपातकाल';

  @override
  String get toolsDoctorPortal => 'डॉक्टर पोर्टल';
}
