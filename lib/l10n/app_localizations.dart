import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get appTitle;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get settings;

  /// No description provided for @themeStyle.
  ///
  /// In en, this message translates to:
  /// **'Theme Style'**
  String get themeStyle;

  /// No description provided for @appearanceMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance Mode'**
  String get appearanceMode;

  /// No description provided for @systemAuto.
  ///
  /// In en, this message translates to:
  /// **'System (auto)'**
  String get systemAuto;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @usingSystemSize.
  ///
  /// In en, this message translates to:
  /// **'Using system size'**
  String get usingSystemSize;

  /// No description provided for @resetToSystem.
  ///
  /// In en, this message translates to:
  /// **'Reset to System'**
  String get resetToSystem;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @flowIntensity.
  ///
  /// In en, this message translates to:
  /// **'Flow Intensity'**
  String get flowIntensity;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @pain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get pain;

  /// No description provided for @overallFeeling.
  ///
  /// In en, this message translates to:
  /// **'Overall Feeling'**
  String get overallFeeling;

  /// No description provided for @themeMandyRed.
  ///
  /// In en, this message translates to:
  /// **'Mandy Red'**
  String get themeMandyRed;

  /// No description provided for @themeRedWine.
  ///
  /// In en, this message translates to:
  /// **'Red Wine'**
  String get themeRedWine;

  /// No description provided for @themeDeepPurple.
  ///
  /// In en, this message translates to:
  /// **'Deep Purple'**
  String get themeDeepPurple;

  /// No description provided for @themeSakura.
  ///
  /// In en, this message translates to:
  /// **'Sakura'**
  String get themeSakura;

  /// No description provided for @themePurpleBrown.
  ///
  /// In en, this message translates to:
  /// **'Purple Brown'**
  String get themePurpleBrown;

  /// No description provided for @themeJungle.
  ///
  /// In en, this message translates to:
  /// **'Jungle'**
  String get themeJungle;

  /// No description provided for @themeShadBlue.
  ///
  /// In en, this message translates to:
  /// **'Shad Blue'**
  String get themeShadBlue;

  /// No description provided for @themeSanJuanBlue.
  ///
  /// In en, this message translates to:
  /// **'San Juan Blue'**
  String get themeSanJuanBlue;

  /// No description provided for @themeIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get themeIndigo;

  /// No description provided for @themeBrandBlue.
  ///
  /// In en, this message translates to:
  /// **'Brand Blue'**
  String get themeBrandBlue;

  /// No description provided for @themePurpleM3.
  ///
  /// In en, this message translates to:
  /// **'Purple M3'**
  String get themePurpleM3;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get home;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'phase'**
  String get phase;

  /// No description provided for @tracker.
  ///
  /// In en, this message translates to:
  /// **'tracker'**
  String get tracker;

  /// No description provided for @menstruation.
  ///
  /// In en, this message translates to:
  /// **'Menstruation'**
  String get menstruation;

  /// No description provided for @follicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get follicular;

  /// No description provided for @ovulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get ovulation;

  /// No description provided for @luteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get luteal;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @selectPhase.
  ///
  /// In en, this message translates to:
  /// **'Select Phase'**
  String get selectPhase;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cycleStats.
  ///
  /// In en, this message translates to:
  /// **'Cycle Stats'**
  String get cycleStats;

  /// No description provided for @currentCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Current Cycle Day'**
  String get currentCycleDay;

  /// No description provided for @daysUntilPeriod.
  ///
  /// In en, this message translates to:
  /// **'Days Until Period'**
  String get daysUntilPeriod;

  /// No description provided for @averageCycleLength.
  ///
  /// In en, this message translates to:
  /// **'Average Cycle Length'**
  String get averageCycleLength;

  /// No description provided for @noEntry.
  ///
  /// In en, this message translates to:
  /// **'No entry for this day'**
  String get noEntry;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @noPhase.
  ///
  /// In en, this message translates to:
  /// **'No phase'**
  String get noPhase;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap any day to start tracking your cycle'**
  String get emptyStateMessage;

  /// No description provided for @editAdd.
  ///
  /// In en, this message translates to:
  /// **'Edit / Add'**
  String get editAdd;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @flow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get flow;

  /// No description provided for @feeling.
  ///
  /// In en, this message translates to:
  /// **'Feeling'**
  String get feeling;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @calendarFormatMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarFormatMonth;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarFormatWeek;

  /// No description provided for @calendarFormatTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 Weeks'**
  String get calendarFormatTwoWeeks;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @weekendDays.
  ///
  /// In en, this message translates to:
  /// **'weekend days'**
  String get weekendDays;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get confirm;

  /// SnackBar message after selecting the first day in range edit mode
  ///
  /// In en, this message translates to:
  /// **'✓ First day selected — now tap the ending day'**
  String get firstDaySelectedMessage;

  /// Option in phase selection dialog to remove/clear the phase from selected range
  ///
  /// In en, this message translates to:
  /// **'None (Clear)'**
  String get noneClear;

  /// Button text when user chooses to clear/remove the phase
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Placeholder text when a value (mood, pain, etc.) is not available
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// Tooltip for the edit mode toggle button when mode is currently active
  ///
  /// In en, this message translates to:
  /// **'Exit edit mode'**
  String get exitEditMode;

  /// Tooltip for the edit mode toggle button when mode is inactive
  ///
  /// In en, this message translates to:
  /// **'Edit mode (mark ranges)'**
  String get editModeRanges;

  /// Tooltip for the temporary clear-all entries button
  ///
  /// In en, this message translates to:
  /// **'Clear all (temp test)'**
  String get clearAllTest;

  /// Title of confirmation dialog for clearing all calendar entries
  ///
  /// In en, this message translates to:
  /// **'Clear Calendar?'**
  String get clearCalendar;

  /// Warning message in the clear-all confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL entries.\nOnly for testing!'**
  String get clearCalendarWarning;

  /// Banner text shown when edit/range mode is active but no start day selected
  ///
  /// In en, this message translates to:
  /// **'Edit mode ON • Tap first day'**
  String get editModeOnTapFirst;

  /// Banner text after first day is selected in edit mode
  ///
  /// In en, this message translates to:
  /// **'Tap ending day (or same day for single-day)'**
  String get tapEndingDay;

  /// Unit label appended to average cycle length value
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @flowLight.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get flowLight;

  /// No description provided for @flowMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get flowMedium;

  /// No description provided for @flowHeavy.
  ///
  /// In en, this message translates to:
  /// **'heavy'**
  String get flowHeavy;

  /// No description provided for @flowSpotting.
  ///
  /// In en, this message translates to:
  /// **'spotting'**
  String get flowSpotting;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry?'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry? This cannot be undone.'**
  String get deleteEntryConfirm;

  /// No description provided for @everythingOptional.
  ///
  /// In en, this message translates to:
  /// **'Everything here is optional — you can save with just the date if you want 💕'**
  String get everythingOptional;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @flowDescription.
  ///
  /// In en, this message translates to:
  /// **'Flow Description'**
  String get flowDescription;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @addPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Add photos of your day or symptoms 💕'**
  String get addPhotosHint;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Write your notes here...'**
  String get notesHint;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved successfully'**
  String get entrySaved;

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated successfully'**
  String get entryUpdated;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get moodAmazing;

  /// No description provided for @energyVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get energyVeryLow;

  /// No description provided for @energyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get energyLow;

  /// No description provided for @energyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get energyMedium;

  /// No description provided for @energyHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get energyHigh;

  /// No description provided for @energyVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get energyVeryHigh;

  /// No description provided for @noPain.
  ///
  /// In en, this message translates to:
  /// **'No Pain'**
  String get noPain;

  /// No description provided for @cramps.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get cramps;

  /// No description provided for @bloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get bloating;

  /// No description provided for @headache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get headache;

  /// No description provided for @breastTenderness.
  ///
  /// In en, this message translates to:
  /// **'Breast Tenderness'**
  String get breastTenderness;

  /// No description provided for @fatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get fatigue;

  /// No description provided for @nausea.
  ///
  /// In en, this message translates to:
  /// **'Nausea'**
  String get nausea;

  /// No description provided for @moodSwings.
  ///
  /// In en, this message translates to:
  /// **'Mood Swings'**
  String get moodSwings;

  /// No description provided for @acne.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get acne;

  /// No description provided for @backPain.
  ///
  /// In en, this message translates to:
  /// **'Back Pain'**
  String get backPain;

  /// No description provided for @cravings.
  ///
  /// In en, this message translates to:
  /// **'Cravings'**
  String get cravings;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please enable camera or photo access in settings.'**
  String get permissionDenied;

  /// No description provided for @smartPredictions.
  ///
  /// In en, this message translates to:
  /// **'Smart Predictions'**
  String get smartPredictions;

  /// No description provided for @automaticPhasesMaker.
  ///
  /// In en, this message translates to:
  /// **'Automatic Phases Maker'**
  String get automaticPhasesMaker;

  /// No description provided for @futurePredictions.
  ///
  /// In en, this message translates to:
  /// **'Future predictions'**
  String get futurePredictions;

  /// No description provided for @fillPastGaps.
  ///
  /// In en, this message translates to:
  /// **'Fill past gaps'**
  String get fillPastGaps;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get allMonths;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @protectPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Protect my period days'**
  String get protectPeriodDays;

  /// No description provided for @protectPeriodDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Never change any day I marked as menstruation'**
  String get protectPeriodDaysDesc;

  /// No description provided for @protectMenstruation.
  ///
  /// In en, this message translates to:
  /// **'Protect menstruation'**
  String get protectMenstruation;

  /// No description provided for @protectMenstruationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never overwrite days you marked as period'**
  String get protectMenstruationSubtitle;

  /// No description provided for @learnFromBody.
  ///
  /// In en, this message translates to:
  /// **'Learn from my body signals'**
  String get learnFromBody;

  /// No description provided for @learnFromBodyDesc.
  ///
  /// In en, this message translates to:
  /// **'Use energy and symptom patterns to improve predictions (optional)'**
  String get learnFromBodyDesc;

  /// No description provided for @learnFromBodySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust predictions based on your symptom patterns'**
  String get learnFromBodySubtitle;

  /// No description provided for @applyPredictions.
  ///
  /// In en, this message translates to:
  /// **'Apply Predictions'**
  String get applyPredictions;

  /// No description provided for @phasesApplied.
  ///
  /// In en, this message translates to:
  /// **'Phases applied ❤️'**
  String get phasesApplied;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @undoSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Undo successful'**
  String get undoSuccessful;

  /// No description provided for @noPeriodDataYet.
  ///
  /// In en, this message translates to:
  /// **'No period data yet'**
  String get noPeriodDataYet;

  /// No description provided for @periodLengthDays.
  ///
  /// In en, this message translates to:
  /// **'Period length (days)'**
  String get periodLengthDays;

  /// No description provided for @cycleLengthDays.
  ///
  /// In en, this message translates to:
  /// **'Cycle length (days)'**
  String get cycleLengthDays;

  /// No description provided for @lastPeriodDate.
  ///
  /// In en, this message translates to:
  /// **'Last period date'**
  String get lastPeriodDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewDescription.
  ///
  /// In en, this message translates to:
  /// **'Predictions will be shown with lighter colors'**
  String get previewDescription;

  /// No description provided for @predictionsApplied.
  ///
  /// In en, this message translates to:
  /// **'Predictions Applied'**
  String get predictionsApplied;

  /// No description provided for @learnFromBodySignals.
  ///
  /// In en, this message translates to:
  /// **'learn from body signals'**
  String get learnFromBodySignals;

  /// No description provided for @autoPhases.
  ///
  /// In en, this message translates to:
  /// **'auto phases'**
  String get autoPhases;

  /// No description provided for @noPeriodDetected.
  ///
  /// In en, this message translates to:
  /// **'No period detected'**
  String get noPeriodDetected;

  /// No description provided for @lastPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Last period start'**
  String get lastPeriodStart;

  /// No description provided for @previewChanges.
  ///
  /// In en, this message translates to:
  /// **'preview changes'**
  String get previewChanges;

  /// SnackBar message when future predictions are cleared
  ///
  /// In en, this message translates to:
  /// **'Future predictions cleared successfully'**
  String get futureCleared;

  /// Button text to clear all future (predicted) phase entries
  ///
  /// In en, this message translates to:
  /// **'Clear Future Predictions'**
  String get clearFuturePredictions;

  /// Help text for the future predictions slider
  ///
  /// In en, this message translates to:
  /// **'How many months ahead to predict your cycle'**
  String get futurePredictionsHelp;

  /// Help text for the fill past gaps slider
  ///
  /// In en, this message translates to:
  /// **'Fill in past months with predicted phases (useful if you just started tracking)'**
  String get fillPastGapsHelp;

  /// Dialog title asking if user wants to auto-predict phases after saving entry
  ///
  /// In en, this message translates to:
  /// **'Want me to update future predictions now?'**
  String get wantToUpdatePredictions;

  /// Checkbox label in the auto-predict reminder dialog
  ///
  /// In en, this message translates to:
  /// **'Yes, remember my choice'**
  String get rememberMyChoice;

  /// Affirmative button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Negative button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
