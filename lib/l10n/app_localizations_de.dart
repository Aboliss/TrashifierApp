// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get binPlastic => 'Plastik';

  @override
  String get binPaper => 'Papier';

  @override
  String get binTrash => 'Restmüll';

  @override
  String get binBio => 'Biomüll';

  @override
  String get binShortPlastic => 'Plastik';

  @override
  String get binShortPaper => 'Papier';

  @override
  String get binShortTrash => 'Restmüll';

  @override
  String get binShortBio => 'Bio';

  @override
  String get binHintPlastic => 'Flaschen, Verpackungen';

  @override
  String get binHintPaper => 'Kartons, Zeitungen';

  @override
  String get binHintTrash => 'Alles andere';

  @override
  String get binHintBio => 'Küche und Garten';

  @override
  String get notificationTitlePlastic => 'Plastik kommt raus';

  @override
  String get notificationTitlePaper => 'Papier kommt raus';

  @override
  String get notificationTitleTrash => 'Restmüll kommt raus';

  @override
  String get notificationTitleBio => 'Biomüll kommt raus';

  @override
  String get notificationBodyPlastic =>
      'Denk dran, deine Plastiktonne rauszustellen!';

  @override
  String get notificationBodyPaper =>
      'Denk dran, deine Papiertonne rauszustellen!';

  @override
  String get notificationBodyTrash =>
      'Denk dran, deine Restmülltonne rauszustellen!';

  @override
  String get notificationBodyBio => 'Denk dran, deine Biotonne rauszustellen!';

  @override
  String get headlineNothingPlanned => 'Noch keine Tonnen geplant';

  @override
  String get moodSpooky => 'Gruseliger Tonnentag';

  @override
  String get moodJolly => 'Festlicher Tonnentag';

  @override
  String get moodBig => 'Großer Tonnentag';

  @override
  String get moodNormal => 'Tonnentag';

  @override
  String headlineToday(String mood) {
    return 'Heute: $mood!';
  }

  @override
  String headlineTomorrow(String mood) {
    return 'Morgen: $mood!';
  }

  @override
  String headlineThisWeek(String weekday) {
    return 'Tonnen raus am $weekday';
  }

  @override
  String get headlineQuietWeek => 'Eine ruhige Tonnenwoche';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get yesterday => 'Gestern';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Tagen',
      one: 'In 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen',
      one: 'Vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String inDaysBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count Tagen',
      one: 'in 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String reminderTonight(String time) {
    return 'Erinnerung heute Abend um $time';
  }

  @override
  String reminderToday(String time) {
    return 'Erinnerung heute um $time';
  }

  @override
  String reminderTomorrow(String time) {
    return 'Erinnerung morgen um $time';
  }

  @override
  String reminderOnDay(String weekday, String time) {
    return 'Erinnerung am $weekday um $time';
  }

  @override
  String get pickupIsToday => 'Abholung ist heute';

  @override
  String get putBinsOutTonight => 'Stell die Tonnen heute Abend raus';

  @override
  String emptyCardHintDayBefore(String time) {
    return 'Trag deine Abholtage ein und Bin Buddy erinnert dich am Vortag um $time.';
  }

  @override
  String emptyCardHintPickupDay(String time) {
    return 'Trag deine Abholtage ein und Bin Buddy erinnert dich am Abholtag um $time.';
  }

  @override
  String dayRemindersDayBefore(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erinnerungen am Vortag um $time, eine pro Tonne.',
      one: 'Eine Erinnerung am Vortag um $time.',
      zero: 'Keine Tonnen, keine Erinnerung.',
    );
    return '$_temp0';
  }

  @override
  String dayRemindersPickupDay(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erinnerungen am Abholtag um $time, eine pro Tonne.',
      one: 'Eine Erinnerung am Abholtag um $time.',
      zero: 'Keine Tonnen, keine Erinnerung.',
    );
    return '$_temp0';
  }

  @override
  String get nextPickupEyebrow => 'NÄCHSTE ABHOLUNG';

  @override
  String get nothingPlanned => 'Nichts geplant';

  @override
  String get addPickups => 'Abholtage eintragen';

  @override
  String get next7Days => 'Nächste 7 Tage';

  @override
  String dayWithBins(String date, String bins) {
    return '$date: $bins';
  }

  @override
  String get comingUp => 'Demnächst';

  @override
  String get nothingElsePlanned => 'Sonst ist noch nichts geplant.';

  @override
  String get remove => 'Entfernen';

  @override
  String removeBinOnDay(String bin, String weekday) {
    return '$bin am $weekday entfernen';
  }

  @override
  String removedSnack(String bin, String date) {
    return '$bin am $date entfernt';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get saveFailed => 'Die Termine konnten nicht gespeichert werden.';

  @override
  String get navHome => 'Start';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get swipeHint => 'Nach links wischen für den Kalender';

  @override
  String get settings => 'Einstellungen';

  @override
  String get back => 'Zurück';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get done => 'Fertig';

  @override
  String get addPickupsHint =>
      'Wähl eine Tonne und tippe dann alle ihre Abholtage an.';

  @override
  String upcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geplant',
      zero: 'Nichts geplant',
    );
    return '$_temp0';
  }

  @override
  String get whichBinsGoOut => 'Welche Tonnen kommen raus?';

  @override
  String get clearDay => 'Tag leeren';

  @override
  String saveBins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tonnen speichern',
      one: '1 Tonne speichern',
    );
    return '$_temp0';
  }

  @override
  String binDays(String bin) {
    return '$bin-Tage';
  }

  @override
  String get tapDaysHint =>
      'Tippe Tage an, um sie hinzuzufügen oder zu entfernen';

  @override
  String changeAdded(int count) {
    return '+$count neu';
  }

  @override
  String changeRemoved(int count) {
    return '$count entfernt';
  }

  @override
  String addDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage hinzufügen',
      one: '1 Tag hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String removeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage entfernen',
      one: '1 Tag entfernen',
    );
    return '$_temp0';
  }

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get filterAll => 'Alle';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get noBinsThisDay =>
      'Keine Tonnen an diesem Tag. Tippe auf Bearbeiten, um welche hinzuzufügen.';

  @override
  String get specialHalloween => 'Halloween';

  @override
  String get specialChristmasEve => 'Heiligabend';

  @override
  String get specialChristmasDay => '1. Weihnachtsfeiertag';

  @override
  String get specialBoxingDay => '2. Weihnachtsfeiertag';

  @override
  String get specialNewYearsEve => 'Silvester';

  @override
  String get sectionReminders => 'ERINNERUNGEN';

  @override
  String get remindMe => 'Erinnere mich';

  @override
  String get theDayBefore => 'Am Vortag';

  @override
  String get onPickupDay => 'Am Abholtag';

  @override
  String get time => 'Uhrzeit';

  @override
  String get reminderTime => 'Erinnerungszeit';

  @override
  String reminderTimeA11y(String time) {
    return 'Erinnerungszeit, $time';
  }

  @override
  String get nextReminderLabel => 'Nächste Erinnerung: ';

  @override
  String nextReminderAt(String date, String time) {
    return '$date um $time';
  }

  @override
  String get nextReminderNone =>
      'Noch keine Erinnerung geplant. Trag auf Start Abholtage ein.';

  @override
  String get sectionAppearance => 'DARSTELLUNG';

  @override
  String get language => 'Sprache';

  @override
  String get phoneLanguage => 'Handysprache';

  @override
  String phoneLanguageNow(String language) {
    return 'Handysprache ($language)';
  }

  @override
  String get languageHint => 'Gilt auch für die Widgets und Erinnerungen.';

  @override
  String get theme => 'Design';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get seasonalThemes => 'Saisonale Designs';

  @override
  String get sectionBackup => 'BACKUP';

  @override
  String get exportBackup => 'Backup exportieren';

  @override
  String get exportBackupHint => 'Alle Abholtermine in einer Datei sichern';

  @override
  String get importTitle => 'Importieren';

  @override
  String get importHint =>
      'Aus einem Backup, einer geteilten Datei oder einem QR-Code';

  @override
  String get backupSaved => 'Backup gespeichert';

  @override
  String get sectionShare => 'MIT DEINEM HAUSHALT TEILEN';

  @override
  String get sendAsFile => 'Als Datei senden';

  @override
  String get showQrCode => 'QR-Code zeigen';

  @override
  String get shareHint =>
      'Eine einmalige Kopie deiner anstehenden Abholtermine. Wenn du sie später änderst, teile sie erneut.';

  @override
  String get shareTitle => 'Trashifier-Abholplan';

  @override
  String get nothingToShare => 'Noch keine anstehenden Abholtermine zum Teilen';

  @override
  String get licenses => 'Lizenzen';

  @override
  String get importSheetHint =>
      'Du kannst die Termine zu deinen hinzufügen oder deine damit ersetzen.';

  @override
  String get fromFile => 'Aus einer Datei';

  @override
  String get fromFileHint =>
      'Ein Backup oder ein Plan, den dir jemand geschickt hat';

  @override
  String get scanQrCode => 'QR-Code scannen';

  @override
  String get scanQrCodeHint => 'Über „QR-Code zeigen“ auf dem anderen Handy';

  @override
  String get scannerUnavailable =>
      'Der QR-Scanner ist nicht verfügbar. Er braucht die Google Play-Dienste und beim ersten Mal eine Internetverbindung.';

  @override
  String get importFromFile => 'AUS EINER DATEI';

  @override
  String get importFromLink => 'AUS EINEM LINK';

  @override
  String get importFromQr => 'AUS EINEM QR-CODE';

  @override
  String importCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abholtermine importieren?',
      one: '1 Abholtermin importieren?',
    );
    return '$_temp0';
  }

  @override
  String skippedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge sind ungültig und werden übersprungen.',
      one: '1 Eintrag ist ungültig und wird übersprungen.',
    );
    return '$_temp0';
  }

  @override
  String currentPickups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Du hast gerade $count Abholtermine. „Ergänzen“ behält sie, „Alle ersetzen“ entfernt sie vorher.',
      one:
          'Du hast gerade 1 Abholtermin. „Ergänzen“ behält ihn, „Alle ersetzen“ entfernt ihn vorher.',
    );
    return '$_temp0';
  }

  @override
  String get addToMine => 'Ergänzen';

  @override
  String get replaceAll => 'Alle ersetzen';

  @override
  String get importButton => 'Importieren';

  @override
  String importedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abholtermine importiert',
      one: '1 Abholtermin importiert',
    );
    return '$_temp0';
  }

  @override
  String get errorNotTrashifier => 'Das ist kein Trashifier-Plan.';

  @override
  String get errorNewerVersion =>
      'Dieser Plan stammt aus einer neueren Trashifier-Version. Aktualisiere zuerst die App.';

  @override
  String get errorTooLarge => 'Die Datei ist zu groß für einen Plan.';

  @override
  String get errorInvalid =>
      'Dieser Plan ist beschädigt und kann nicht importiert werden.';

  @override
  String get errorEmpty => 'Dieser Plan enthält keine Abholtermine.';

  @override
  String get errorUnavailable => 'Auf diesem Handy nicht verfügbar.';

  @override
  String get errorFileFailed =>
      'Die Datei konnte nicht gelesen oder geschrieben werden.';

  @override
  String get qrTitle => 'Scannen, um den Plan zu kopieren';

  @override
  String qrSubtitle(int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anstehende Abholtermine · $range',
      one: '1 anstehender Abholtermin · $range',
    );
    return '$_temp0';
  }

  @override
  String qrA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'QR-Code mit $count anstehenden Abholterminen',
      one: 'QR-Code mit 1 anstehenden Abholtermin',
    );
    return '$_temp0';
  }

  @override
  String get qrHint =>
      'Öffne auf dem anderen Handy Trashifier › Einstellungen › Importieren › QR-Code scannen. Die App fragt vor dem Import immer nach.';
}
