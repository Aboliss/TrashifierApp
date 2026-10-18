import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_sk.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('sk'),
  ];

  /// No description provided for @binPlastic.
  ///
  /// In en, this message translates to:
  /// **'Plastic'**
  String get binPlastic;

  /// No description provided for @binPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get binPaper;

  /// No description provided for @binTrash.
  ///
  /// In en, this message translates to:
  /// **'General trash'**
  String get binTrash;

  /// No description provided for @binBio.
  ///
  /// In en, this message translates to:
  /// **'Bio waste'**
  String get binBio;

  /// No description provided for @binShortPlastic.
  ///
  /// In en, this message translates to:
  /// **'Plastic'**
  String get binShortPlastic;

  /// No description provided for @binShortPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get binShortPaper;

  /// No description provided for @binShortTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get binShortTrash;

  /// No description provided for @binShortBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get binShortBio;

  /// No description provided for @binHintPlastic.
  ///
  /// In en, this message translates to:
  /// **'Bottles, packaging'**
  String get binHintPlastic;

  /// No description provided for @binHintPaper.
  ///
  /// In en, this message translates to:
  /// **'Boxes, newspapers'**
  String get binHintPaper;

  /// No description provided for @binHintTrash.
  ///
  /// In en, this message translates to:
  /// **'Everything else'**
  String get binHintTrash;

  /// No description provided for @binHintBio.
  ///
  /// In en, this message translates to:
  /// **'Food and garden'**
  String get binHintBio;

  /// No description provided for @notificationTitlePlastic.
  ///
  /// In en, this message translates to:
  /// **'Plastic goes out'**
  String get notificationTitlePlastic;

  /// No description provided for @notificationTitlePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper goes out'**
  String get notificationTitlePaper;

  /// No description provided for @notificationTitleTrash.
  ///
  /// In en, this message translates to:
  /// **'General trash goes out'**
  String get notificationTitleTrash;

  /// No description provided for @notificationTitleBio.
  ///
  /// In en, this message translates to:
  /// **'Bio waste goes out'**
  String get notificationTitleBio;

  /// No description provided for @notificationBodyPlastic.
  ///
  /// In en, this message translates to:
  /// **'Remember to take out your plastic bin!'**
  String get notificationBodyPlastic;

  /// No description provided for @notificationBodyPaper.
  ///
  /// In en, this message translates to:
  /// **'Remember to take out your paper bin!'**
  String get notificationBodyPaper;

  /// No description provided for @notificationBodyTrash.
  ///
  /// In en, this message translates to:
  /// **'Remember to take out your trash bin!'**
  String get notificationBodyTrash;

  /// No description provided for @notificationBodyBio.
  ///
  /// In en, this message translates to:
  /// **'Remember to take out your bio bin!'**
  String get notificationBodyBio;

  /// No description provided for @headlineNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'No bins planned yet'**
  String get headlineNothingPlanned;

  /// No description provided for @moodSpooky.
  ///
  /// In en, this message translates to:
  /// **'Spooky bin day'**
  String get moodSpooky;

  /// No description provided for @moodJolly.
  ///
  /// In en, this message translates to:
  /// **'Jolly bin day'**
  String get moodJolly;

  /// No description provided for @moodBig.
  ///
  /// In en, this message translates to:
  /// **'Big bin day'**
  String get moodBig;

  /// No description provided for @moodNormal.
  ///
  /// In en, this message translates to:
  /// **'Bin day'**
  String get moodNormal;

  /// No description provided for @headlineToday.
  ///
  /// In en, this message translates to:
  /// **'{mood} today!'**
  String headlineToday(String mood);

  /// No description provided for @headlineTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{mood} tomorrow!'**
  String headlineTomorrow(String mood);

  /// No description provided for @headlineThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Bins out on {weekday}'**
  String headlineThisWeek(String weekday);

  /// No description provided for @headlineQuietWeek.
  ///
  /// In en, this message translates to:
  /// **'A quiet week for bins'**
  String get headlineQuietWeek;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 day} other{In {count} days}}'**
  String inDays(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// Short badge on Coming up rows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String inDaysBadge(int count);

  /// No description provided for @reminderTonight.
  ///
  /// In en, this message translates to:
  /// **'Reminder tonight at {time}'**
  String reminderTonight(String time);

  /// No description provided for @reminderToday.
  ///
  /// In en, this message translates to:
  /// **'Reminder today at {time}'**
  String reminderToday(String time);

  /// No description provided for @reminderTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Reminder tomorrow at {time}'**
  String reminderTomorrow(String time);

  /// No description provided for @reminderOnDay.
  ///
  /// In en, this message translates to:
  /// **'Reminder on {weekday} at {time}'**
  String reminderOnDay(String weekday, String time);

  /// No description provided for @pickupIsToday.
  ///
  /// In en, this message translates to:
  /// **'Pickup is today'**
  String get pickupIsToday;

  /// No description provided for @putBinsOutTonight.
  ///
  /// In en, this message translates to:
  /// **'Put the bins out tonight'**
  String get putBinsOutTonight;

  /// No description provided for @emptyCardHintDayBefore.
  ///
  /// In en, this message translates to:
  /// **'Add your collection days and Bin Buddy will remind you the day before at {time}.'**
  String emptyCardHintDayBefore(String time);

  /// No description provided for @emptyCardHintPickupDay.
  ///
  /// In en, this message translates to:
  /// **'Add your collection days and Bin Buddy will remind you on pickup day at {time}.'**
  String emptyCardHintPickupDay(String time);

  /// No description provided for @dayRemindersDayBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No bins, no reminder.} =1{One reminder the day before at {time}.} other{{count} reminders the day before at {time}, one per bin.}}'**
  String dayRemindersDayBefore(int count, String time);

  /// No description provided for @dayRemindersPickupDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No bins, no reminder.} =1{One reminder on pickup day at {time}.} other{{count} reminders on pickup day at {time}, one per bin.}}'**
  String dayRemindersPickupDay(int count, String time);

  /// No description provided for @nextPickupEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NEXT PICKUP'**
  String get nextPickupEyebrow;

  /// No description provided for @nothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get nothingPlanned;

  /// No description provided for @addPickups.
  ///
  /// In en, this message translates to:
  /// **'Add pickups'**
  String get addPickups;

  /// No description provided for @next7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get next7Days;

  /// Screen reader label of a day in the week strip.
  ///
  /// In en, this message translates to:
  /// **'{date}: {bins}'**
  String dayWithBins(String date, String bins);

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @nothingElsePlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing else planned yet.'**
  String get nothingElsePlanned;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeBinOnDay.
  ///
  /// In en, this message translates to:
  /// **'Remove {bin} on {weekday}'**
  String removeBinOnDay(String bin, String weekday);

  /// No description provided for @removedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed {bin} on {date}'**
  String removedSnack(String bin, String date);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the dates.'**
  String get saveFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left for the calendar'**
  String get swipeHint;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addPickupsHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a bin, then tap all of its collection days.'**
  String get addPickupsHint;

  /// No description provided for @upcomingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing planned} other{{count} upcoming}}'**
  String upcomingCount(int count);

  /// No description provided for @whichBinsGoOut.
  ///
  /// In en, this message translates to:
  /// **'Which bins go out?'**
  String get whichBinsGoOut;

  /// No description provided for @clearDay.
  ///
  /// In en, this message translates to:
  /// **'Clear day'**
  String get clearDay;

  /// No description provided for @saveBins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save 1 bin} other{Save {count} bins}}'**
  String saveBins(int count);

  /// Title of the multi-date picker, e.g. Plastic days.
  ///
  /// In en, this message translates to:
  /// **'{bin} days'**
  String binDays(String bin);

  /// No description provided for @tapDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Tap days to add or remove'**
  String get tapDaysHint;

  /// No description provided for @changeAdded.
  ///
  /// In en, this message translates to:
  /// **'+{count} new'**
  String changeAdded(int count);

  /// No description provided for @changeRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count} removed'**
  String changeRemoved(int count);

  /// No description provided for @addDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 day} other{Add {count} days}}'**
  String addDays(int count);

  /// No description provided for @removeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Remove 1 day} other{Remove {count} days}}'**
  String removeDays(int count);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @noBinsThisDay.
  ///
  /// In en, this message translates to:
  /// **'No bins go out. Tap Edit to add some.'**
  String get noBinsThisDay;

  /// No description provided for @specialHalloween.
  ///
  /// In en, this message translates to:
  /// **'Halloween'**
  String get specialHalloween;

  /// No description provided for @specialChristmasEve.
  ///
  /// In en, this message translates to:
  /// **'Christmas Eve'**
  String get specialChristmasEve;

  /// No description provided for @specialChristmasDay.
  ///
  /// In en, this message translates to:
  /// **'Christmas Day'**
  String get specialChristmasDay;

  /// No description provided for @specialBoxingDay.
  ///
  /// In en, this message translates to:
  /// **'Boxing Day'**
  String get specialBoxingDay;

  /// No description provided for @specialNewYearsEve.
  ///
  /// In en, this message translates to:
  /// **'New Year’s Eve'**
  String get specialNewYearsEve;

  /// No description provided for @sectionReminders.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get sectionReminders;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @theDayBefore.
  ///
  /// In en, this message translates to:
  /// **'The day before'**
  String get theDayBefore;

  /// No description provided for @onPickupDay.
  ///
  /// In en, this message translates to:
  /// **'On pickup day'**
  String get onPickupDay;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @reminderTimeA11y.
  ///
  /// In en, this message translates to:
  /// **'Reminder time, {time}'**
  String reminderTimeA11y(String time);

  /// No description provided for @nextReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Next reminder: '**
  String get nextReminderLabel;

  /// No description provided for @nextReminderAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String nextReminderAt(String date, String time);

  /// No description provided for @nextReminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder planned yet. Add pickups on Home.'**
  String get nextReminderNone;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get sectionAppearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @phoneLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get phoneLanguage;

  /// No description provided for @phoneLanguageNow.
  ///
  /// In en, this message translates to:
  /// **'Phone language ({language})'**
  String phoneLanguageNow(String language);

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Also used by the widgets and reminders.'**
  String get languageHint;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

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

  /// No description provided for @seasonalThemes.
  ///
  /// In en, this message translates to:
  /// **'Seasonal themes'**
  String get seasonalThemes;

  /// No description provided for @sectionBackup.
  ///
  /// In en, this message translates to:
  /// **'BACKUP'**
  String get sectionBackup;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @exportBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Save all pickup dates to a file'**
  String get exportBackupHint;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'From a backup, a shared file or a QR code'**
  String get importHint;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @sectionShare.
  ///
  /// In en, this message translates to:
  /// **'SHARE WITH YOUR HOUSEHOLD'**
  String get sectionShare;

  /// No description provided for @sendAsFile.
  ///
  /// In en, this message translates to:
  /// **'Send as file'**
  String get sendAsFile;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showQrCode;

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'A one-time copy of your upcoming pickups. If you change them later, share again.'**
  String get shareHint;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Trashifier schedule'**
  String get shareTitle;

  /// No description provided for @nothingToShare.
  ///
  /// In en, this message translates to:
  /// **'No upcoming pickups to share yet'**
  String get nothingToShare;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @importSheetHint.
  ///
  /// In en, this message translates to:
  /// **'You can choose to add the dates to yours or replace them.'**
  String get importSheetHint;

  /// No description provided for @fromFile.
  ///
  /// In en, this message translates to:
  /// **'From a file'**
  String get fromFile;

  /// No description provided for @fromFileHint.
  ///
  /// In en, this message translates to:
  /// **'A backup or a schedule someone sent you'**
  String get fromFileHint;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code'**
  String get scanQrCode;

  /// No description provided for @scanQrCodeHint.
  ///
  /// In en, this message translates to:
  /// **'From Show QR code on the other phone'**
  String get scanQrCodeHint;

  /// No description provided for @scannerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The QR scanner isn’t available. It needs Google Play services and, the first time, an internet connection.'**
  String get scannerUnavailable;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'FROM A FILE'**
  String get importFromFile;

  /// No description provided for @importFromLink.
  ///
  /// In en, this message translates to:
  /// **'FROM A LINK'**
  String get importFromLink;

  /// No description provided for @importFromQr.
  ///
  /// In en, this message translates to:
  /// **'FROM A QR CODE'**
  String get importFromQr;

  /// No description provided for @importCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import 1 pickup?} other{Import {count} pickups?}}'**
  String importCount(int count);

  /// No description provided for @skippedEntries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry was not valid and will be skipped.} other{{count} entries were not valid and will be skipped.}}'**
  String skippedEntries(int count);

  /// No description provided for @currentPickups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 pickup now. Add to mine keeps it; Replace all removes it first.} other{You have {count} pickups now. Add to mine keeps them; Replace all removes them first.}}'**
  String currentPickups(int count);

  /// No description provided for @addToMine.
  ///
  /// In en, this message translates to:
  /// **'Add to mine'**
  String get addToMine;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get replaceAll;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importedSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 pickup} other{Imported {count} pickups}}'**
  String importedSnack(int count);

  /// No description provided for @errorNotTrashifier.
  ///
  /// In en, this message translates to:
  /// **'That isn’t a Trashifier schedule.'**
  String get errorNotTrashifier;

  /// No description provided for @errorNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This schedule is from a newer Trashifier. Update the app first.'**
  String get errorNewerVersion;

  /// No description provided for @errorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large to be a schedule.'**
  String get errorTooLarge;

  /// No description provided for @errorInvalid.
  ///
  /// In en, this message translates to:
  /// **'This schedule is damaged and can’t be imported.'**
  String get errorInvalid;

  /// No description provided for @errorEmpty.
  ///
  /// In en, this message translates to:
  /// **'This schedule has no pickups.'**
  String get errorEmpty;

  /// No description provided for @errorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this phone.'**
  String get errorUnavailable;

  /// No description provided for @errorFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read or write the file.'**
  String get errorFileFailed;

  /// No description provided for @qrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to copy the schedule'**
  String get qrTitle;

  /// No description provided for @qrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 upcoming pickup · {range}} other{{count} upcoming pickups · {range}}}'**
  String qrSubtitle(int count, String range);

  /// No description provided for @qrA11y.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{QR code with 1 upcoming pickup} other{QR code with {count} upcoming pickups}}'**
  String qrA11y(int count);

  /// No description provided for @qrHint.
  ///
  /// In en, this message translates to:
  /// **'On the other phone, open Trashifier › Settings › Import › Scan a QR code. It asks before importing anything.'**
  String get qrHint;
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
      <String>['de', 'en', 'es', 'sk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'sk':
      return AppLocalizationsSk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
