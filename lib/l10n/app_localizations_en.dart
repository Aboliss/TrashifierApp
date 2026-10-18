// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get binPlastic => 'Plastic';

  @override
  String get binPaper => 'Paper';

  @override
  String get binTrash => 'General trash';

  @override
  String get binBio => 'Bio waste';

  @override
  String get binShortPlastic => 'Plastic';

  @override
  String get binShortPaper => 'Paper';

  @override
  String get binShortTrash => 'Trash';

  @override
  String get binShortBio => 'Bio';

  @override
  String get binHintPlastic => 'Bottles, packaging';

  @override
  String get binHintPaper => 'Boxes, newspapers';

  @override
  String get binHintTrash => 'Everything else';

  @override
  String get binHintBio => 'Food and garden';

  @override
  String get notificationTitlePlastic => 'Plastic goes out';

  @override
  String get notificationTitlePaper => 'Paper goes out';

  @override
  String get notificationTitleTrash => 'General trash goes out';

  @override
  String get notificationTitleBio => 'Bio waste goes out';

  @override
  String get notificationBodyPlastic =>
      'Remember to take out your plastic bin!';

  @override
  String get notificationBodyPaper => 'Remember to take out your paper bin!';

  @override
  String get notificationBodyTrash => 'Remember to take out your trash bin!';

  @override
  String get notificationBodyBio => 'Remember to take out your bio bin!';

  @override
  String get headlineNothingPlanned => 'No bins planned yet';

  @override
  String get moodSpooky => 'Spooky bin day';

  @override
  String get moodJolly => 'Jolly bin day';

  @override
  String get moodBig => 'Big bin day';

  @override
  String get moodNormal => 'Bin day';

  @override
  String headlineToday(String mood) {
    return '$mood today!';
  }

  @override
  String headlineTomorrow(String mood) {
    return '$mood tomorrow!';
  }

  @override
  String headlineThisWeek(String weekday) {
    return 'Bins out on $weekday';
  }

  @override
  String get headlineQuietWeek => 'A quiet week for bins';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String inDaysBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String reminderTonight(String time) {
    return 'Reminder tonight at $time';
  }

  @override
  String reminderToday(String time) {
    return 'Reminder today at $time';
  }

  @override
  String reminderTomorrow(String time) {
    return 'Reminder tomorrow at $time';
  }

  @override
  String reminderOnDay(String weekday, String time) {
    return 'Reminder on $weekday at $time';
  }

  @override
  String get pickupIsToday => 'Pickup is today';

  @override
  String get putBinsOutTonight => 'Put the bins out tonight';

  @override
  String emptyCardHintDayBefore(String time) {
    return 'Add your collection days and Bin Buddy will remind you the day before at $time.';
  }

  @override
  String emptyCardHintPickupDay(String time) {
    return 'Add your collection days and Bin Buddy will remind you on pickup day at $time.';
  }

  @override
  String dayRemindersDayBefore(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders the day before at $time, one per bin.',
      one: 'One reminder the day before at $time.',
      zero: 'No bins, no reminder.',
    );
    return '$_temp0';
  }

  @override
  String dayRemindersPickupDay(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders on pickup day at $time, one per bin.',
      one: 'One reminder on pickup day at $time.',
      zero: 'No bins, no reminder.',
    );
    return '$_temp0';
  }

  @override
  String get nextPickupEyebrow => 'NEXT PICKUP';

  @override
  String get nothingPlanned => 'Nothing planned';

  @override
  String get addPickups => 'Add pickups';

  @override
  String get next7Days => 'Next 7 days';

  @override
  String dayWithBins(String date, String bins) {
    return '$date: $bins';
  }

  @override
  String get comingUp => 'Coming up';

  @override
  String get nothingElsePlanned => 'Nothing else planned yet.';

  @override
  String get remove => 'Remove';

  @override
  String removeBinOnDay(String bin, String weekday) {
    return 'Remove $bin on $weekday';
  }

  @override
  String removedSnack(String bin, String date) {
    return 'Removed $bin on $date';
  }

  @override
  String get undo => 'Undo';

  @override
  String get saveFailed => 'Couldn’t save the dates.';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get swipeHint => 'Swipe left for the calendar';

  @override
  String get settings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get addPickupsHint =>
      'Pick a bin, then tap all of its collection days.';

  @override
  String upcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming',
      zero: 'Nothing planned',
    );
    return '$_temp0';
  }

  @override
  String get whichBinsGoOut => 'Which bins go out?';

  @override
  String get clearDay => 'Clear day';

  @override
  String saveBins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count bins',
      one: 'Save 1 bin',
    );
    return '$_temp0';
  }

  @override
  String binDays(String bin) {
    return '$bin days';
  }

  @override
  String get tapDaysHint => 'Tap days to add or remove';

  @override
  String changeAdded(int count) {
    return '+$count new';
  }

  @override
  String changeRemoved(int count) {
    return '$count removed';
  }

  @override
  String addDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count days',
      one: 'Add 1 day',
    );
    return '$_temp0';
  }

  @override
  String removeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count days',
      one: 'Remove 1 day',
    );
    return '$_temp0';
  }

  @override
  String get saveChanges => 'Save changes';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get filterAll => 'All';

  @override
  String get edit => 'Edit';

  @override
  String get noBinsThisDay => 'No bins go out. Tap Edit to add some.';

  @override
  String get specialHalloween => 'Halloween';

  @override
  String get specialChristmasEve => 'Christmas Eve';

  @override
  String get specialChristmasDay => 'Christmas Day';

  @override
  String get specialBoxingDay => 'Boxing Day';

  @override
  String get specialNewYearsEve => 'New Year’s Eve';

  @override
  String get sectionReminders => 'REMINDERS';

  @override
  String get remindMe => 'Remind me';

  @override
  String get theDayBefore => 'The day before';

  @override
  String get onPickupDay => 'On pickup day';

  @override
  String get time => 'Time';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String reminderTimeA11y(String time) {
    return 'Reminder time, $time';
  }

  @override
  String get nextReminderLabel => 'Next reminder: ';

  @override
  String nextReminderAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get nextReminderNone =>
      'No reminder planned yet. Add pickups on Home.';

  @override
  String get sectionAppearance => 'APPEARANCE';

  @override
  String get language => 'Language';

  @override
  String get phoneLanguage => 'Phone language';

  @override
  String phoneLanguageNow(String language) {
    return 'Phone language ($language)';
  }

  @override
  String get languageHint => 'Also used by the widgets and reminders.';

  @override
  String get theme => 'Theme';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get seasonalThemes => 'Seasonal themes';

  @override
  String get sectionBackup => 'BACKUP';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get exportBackupHint => 'Save all pickup dates to a file';

  @override
  String get importTitle => 'Import';

  @override
  String get importHint => 'From a backup, a shared file or a QR code';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get sectionShare => 'SHARE WITH YOUR HOUSEHOLD';

  @override
  String get sendAsFile => 'Send as file';

  @override
  String get showQrCode => 'Show QR code';

  @override
  String get shareHint =>
      'A one-time copy of your upcoming pickups. If you change them later, share again.';

  @override
  String get shareTitle => 'Trashifier schedule';

  @override
  String get nothingToShare => 'No upcoming pickups to share yet';

  @override
  String get licenses => 'Licenses';

  @override
  String get importSheetHint =>
      'You can choose to add the dates to yours or replace them.';

  @override
  String get fromFile => 'From a file';

  @override
  String get fromFileHint => 'A backup or a schedule someone sent you';

  @override
  String get scanQrCode => 'Scan a QR code';

  @override
  String get scanQrCodeHint => 'From Show QR code on the other phone';

  @override
  String get scannerUnavailable =>
      'The QR scanner isn’t available. It needs Google Play services and, the first time, an internet connection.';

  @override
  String get importFromFile => 'FROM A FILE';

  @override
  String get importFromLink => 'FROM A LINK';

  @override
  String get importFromQr => 'FROM A QR CODE';

  @override
  String importCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count pickups?',
      one: 'Import 1 pickup?',
    );
    return '$_temp0';
  }

  @override
  String skippedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries were not valid and will be skipped.',
      one: '1 entry was not valid and will be skipped.',
    );
    return '$_temp0';
  }

  @override
  String currentPickups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You have $count pickups now. Add to mine keeps them; Replace all removes them first.',
      one:
          'You have 1 pickup now. Add to mine keeps it; Replace all removes it first.',
    );
    return '$_temp0';
  }

  @override
  String get addToMine => 'Add to mine';

  @override
  String get replaceAll => 'Replace all';

  @override
  String get importButton => 'Import';

  @override
  String importedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count pickups',
      one: 'Imported 1 pickup',
    );
    return '$_temp0';
  }

  @override
  String get errorNotTrashifier => 'That isn’t a Trashifier schedule.';

  @override
  String get errorNewerVersion =>
      'This schedule is from a newer Trashifier. Update the app first.';

  @override
  String get errorTooLarge => 'That file is too large to be a schedule.';

  @override
  String get errorInvalid => 'This schedule is damaged and can’t be imported.';

  @override
  String get errorEmpty => 'This schedule has no pickups.';

  @override
  String get errorUnavailable => 'Not available on this phone.';

  @override
  String get errorFileFailed => 'Couldn’t read or write the file.';

  @override
  String get qrTitle => 'Scan to copy the schedule';

  @override
  String qrSubtitle(int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming pickups · $range',
      one: '1 upcoming pickup · $range',
    );
    return '$_temp0';
  }

  @override
  String qrA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'QR code with $count upcoming pickups',
      one: 'QR code with 1 upcoming pickup',
    );
    return '$_temp0';
  }

  @override
  String get qrHint =>
      'On the other phone, open Trashifier › Settings › Import › Scan a QR code. It asks before importing anything.';

  @override
  String notificationTitleCustom(String bin) {
    return '$bin goes out';
  }

  @override
  String notificationBodyCustom(String bin) {
    return 'Remember to take out your $bin bin!';
  }

  @override
  String get sectionBins => 'BINS';

  @override
  String get addBin => 'Add a bin';

  @override
  String get binsHint =>
      'Drag to reorder. Hidden bins keep their dates but don’t show or remind. Up to 10 bins.';

  @override
  String get binsFull => 'That’s 10 bins, the most there can be.';

  @override
  String get binHidden => 'Hidden';

  @override
  String showBin(String bin) {
    return 'Show $bin';
  }

  @override
  String hideBin(String bin) {
    return 'Hide $bin';
  }

  @override
  String editBinA11y(String bin) {
    return 'Edit $bin';
  }

  @override
  String get newBinEyebrow => 'NEW BIN';

  @override
  String get editBinEyebrow => 'EDIT BIN';

  @override
  String get binName => 'Name';

  @override
  String get binNameHint => 'e.g. Glass';

  @override
  String binNameDefault(String name) {
    return 'Leave empty for “$name”';
  }

  @override
  String get binColor => 'Color';

  @override
  String get binIcon => 'Icon';

  @override
  String binColorA11y(int number) {
    return 'Color $number';
  }

  @override
  String binIconA11y(int number) {
    return 'Icon $number';
  }

  @override
  String get addBinButton => 'Add bin';

  @override
  String get deleteBin => 'Delete bin';

  @override
  String deleteBinTitle(String bin) {
    return 'Delete $bin?';
  }

  @override
  String deleteBinBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The bin and its $count pickup dates are deleted.',
      one: 'The bin and its 1 pickup date are deleted.',
      zero: 'The bin is removed.',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String binDeleted(String bin) {
    return '$bin deleted';
  }

  @override
  String importNewBins(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adds $count new bins: $names.',
      one: 'Adds 1 new bin: $names.',
    );
    return '$_temp0';
  }

  @override
  String importNoRoom(String names) {
    return 'No room for $names: that’s 10 bins already. Its dates are skipped.';
  }
}
