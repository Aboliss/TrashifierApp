// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get binPlastic => 'Plasty';

  @override
  String get binPaper => 'Papier';

  @override
  String get binTrash => 'Komunálny odpad';

  @override
  String get binBio => 'Bioodpad';

  @override
  String get binShortPlastic => 'Plasty';

  @override
  String get binShortPaper => 'Papier';

  @override
  String get binShortTrash => 'Odpad';

  @override
  String get binShortBio => 'Bio';

  @override
  String get binHintPlastic => 'Fľaše, obaly';

  @override
  String get binHintPaper => 'Krabice, noviny';

  @override
  String get binHintTrash => 'Všetko ostatné';

  @override
  String get binHintBio => 'Kuchyňa a záhrada';

  @override
  String get notificationTitlePlastic => 'Plasty idú von';

  @override
  String get notificationTitlePaper => 'Papier ide von';

  @override
  String get notificationTitleTrash => 'Komunálny odpad ide von';

  @override
  String get notificationTitleBio => 'Bioodpad ide von';

  @override
  String get notificationBodyPlastic => 'Nezabudni vyložiť nádobu na plasty!';

  @override
  String get notificationBodyPaper => 'Nezabudni vyložiť nádobu na papier!';

  @override
  String get notificationBodyTrash =>
      'Nezabudni vyložiť nádobu na komunálny odpad!';

  @override
  String get notificationBodyBio => 'Nezabudni vyložiť nádobu na bioodpad!';

  @override
  String get headlineNothingPlanned => 'Zatiaľ žiadne naplánované vývozy';

  @override
  String get moodSpooky => 'Strašidelný deň smetiakov';

  @override
  String get moodJolly => 'Sviatočný deň smetiakov';

  @override
  String get moodBig => 'Veľký deň smetiakov';

  @override
  String get moodNormal => 'Deň smetiakov';

  @override
  String headlineToday(String mood) {
    return '$mood je dnes!';
  }

  @override
  String headlineTomorrow(String mood) {
    return '$mood je zajtra!';
  }

  @override
  String headlineThisWeek(String weekday) {
    return 'Smetiaky von: $weekday';
  }

  @override
  String get headlineQuietWeek => 'Pokojný týždeň pre smetiaky';

  @override
  String get today => 'Dnes';

  @override
  String get tomorrow => 'Zajtra';

  @override
  String get yesterday => 'Včera';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'O $count dní',
      many: 'O $count dní',
      few: 'O $count dni',
      one: 'O 1 deň',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pred $count dňami',
      many: 'Pred $count dňami',
      few: 'Pred $count dňami',
      one: 'Pred 1 dňom',
    );
    return '$_temp0';
  }

  @override
  String inDaysBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'o $count dní',
      many: 'o $count dní',
      few: 'o $count dni',
      one: 'o 1 deň',
    );
    return '$_temp0';
  }

  @override
  String reminderTonight(String time) {
    return 'Pripomienka dnes večer o $time';
  }

  @override
  String reminderToday(String time) {
    return 'Pripomienka dnes o $time';
  }

  @override
  String reminderTomorrow(String time) {
    return 'Pripomienka zajtra o $time';
  }

  @override
  String reminderOnDay(String weekday, String time) {
    return 'Pripomienka: $weekday o $time';
  }

  @override
  String get pickupIsToday => 'Vývoz je dnes';

  @override
  String get putBinsOutTonight => 'Dnes večer vylož nádoby';

  @override
  String emptyCardHintDayBefore(String time) {
    return 'Pridaj dni vývozu a Bin Buddy ťa upozorní deň vopred o $time.';
  }

  @override
  String emptyCardHintPickupDay(String time) {
    return 'Pridaj dni vývozu a Bin Buddy ťa upozorní v deň vývozu o $time.';
  }

  @override
  String dayRemindersDayBefore(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pripomienok deň vopred o $time, jedna pre každú nádobu.',
      many: '$count pripomienok deň vopred o $time, jedna pre každú nádobu.',
      few: '$count pripomienky deň vopred o $time, jedna pre každú nádobu.',
      one: 'Jedna pripomienka deň vopred o $time.',
      zero: 'Žiadne nádoby, žiadna pripomienka.',
    );
    return '$_temp0';
  }

  @override
  String dayRemindersPickupDay(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pripomienok v deň vývozu o $time, jedna pre každú nádobu.',
      many: '$count pripomienok v deň vývozu o $time, jedna pre každú nádobu.',
      few: '$count pripomienky v deň vývozu o $time, jedna pre každú nádobu.',
      one: 'Jedna pripomienka v deň vývozu o $time.',
      zero: 'Žiadne nádoby, žiadna pripomienka.',
    );
    return '$_temp0';
  }

  @override
  String get nextPickupEyebrow => 'NAJBLIŽŠÍ VÝVOZ';

  @override
  String get nothingPlanned => 'Nič naplánované';

  @override
  String get addPickups => 'Pridať vývozy';

  @override
  String get next7Days => 'Najbližších 7 dní';

  @override
  String dayWithBins(String date, String bins) {
    return '$date: $bins';
  }

  @override
  String get comingUp => 'Nadchádzajúce';

  @override
  String get nothingElsePlanned => 'Nič ďalšie zatiaľ nie je naplánované.';

  @override
  String get remove => 'Odstrániť';

  @override
  String removeBinOnDay(String bin, String weekday) {
    return 'Odstrániť $bin ($weekday)';
  }

  @override
  String removedSnack(String bin, String date) {
    return 'Odstránené: $bin, $date';
  }

  @override
  String get undo => 'Vrátiť';

  @override
  String get saveFailed => 'Dátumy sa nepodarilo uložiť.';

  @override
  String get navHome => 'Domov';

  @override
  String get navCalendar => 'Kalendár';

  @override
  String get swipeHint => 'Potiahni doľava pre kalendár';

  @override
  String get settings => 'Nastavenia';

  @override
  String get back => 'Späť';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get save => 'Uložiť';

  @override
  String get done => 'Hotovo';

  @override
  String get addPickupsHint =>
      'Vyber nádobu a potom ťukni na všetky jej dni vývozu.';

  @override
  String upcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count naplánovaných',
      many: '$count naplánovaných',
      few: '$count naplánované',
      one: '$count naplánovaný',
      zero: 'Nič naplánované',
    );
    return '$_temp0';
  }

  @override
  String get whichBinsGoOut => 'Ktoré nádoby idú von?';

  @override
  String get clearDay => 'Vymazať deň';

  @override
  String saveBins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uložiť $count nádob',
      many: 'Uložiť $count nádob',
      few: 'Uložiť $count nádoby',
      one: 'Uložiť 1 nádobu',
    );
    return '$_temp0';
  }

  @override
  String binDays(String bin) {
    return 'Dni vývozu: $bin';
  }

  @override
  String get tapDaysHint => 'Ťukaním na dni ich pridáš alebo odstrániš';

  @override
  String changeAdded(int count) {
    return 'Nové: +$count';
  }

  @override
  String changeRemoved(int count) {
    return 'Odstránené: $count';
  }

  @override
  String addDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pridať $count dní',
      many: 'Pridať $count dní',
      few: 'Pridať $count dni',
      one: 'Pridať 1 deň',
    );
    return '$_temp0';
  }

  @override
  String removeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odstrániť $count dní',
      many: 'Odstrániť $count dní',
      few: 'Odstrániť $count dni',
      one: 'Odstrániť 1 deň',
    );
    return '$_temp0';
  }

  @override
  String get saveChanges => 'Uložiť zmeny';

  @override
  String get previousMonth => 'Predchádzajúci mesiac';

  @override
  String get nextMonth => 'Nasledujúci mesiac';

  @override
  String get filterAll => 'Všetko';

  @override
  String get edit => 'Upraviť';

  @override
  String get noBinsThisDay =>
      'Žiadne nádoby nejdú von. Ťukni na Upraviť a nejaké pridaj.';

  @override
  String get specialHalloween => 'Halloween';

  @override
  String get specialChristmasEve => 'Štedrý deň';

  @override
  String get specialChristmasDay => 'Prvý sviatok vianočný';

  @override
  String get specialBoxingDay => 'Druhý sviatok vianočný';

  @override
  String get specialNewYearsEve => 'Silvester';

  @override
  String get sectionReminders => 'PRIPOMIENKY';

  @override
  String get remindMe => 'Pripomenúť';

  @override
  String get theDayBefore => 'Deň vopred';

  @override
  String get onPickupDay => 'V deň vývozu';

  @override
  String get time => 'Čas';

  @override
  String get reminderTime => 'Čas pripomienky';

  @override
  String reminderTimeA11y(String time) {
    return 'Čas pripomienky, $time';
  }

  @override
  String get nextReminderLabel => 'Ďalšia pripomienka: ';

  @override
  String nextReminderAt(String date, String time) {
    return '$date o $time';
  }

  @override
  String get nextReminderNone =>
      'Zatiaľ nie je naplánovaná žiadna pripomienka. Pridaj vývozy na stránke Domov.';

  @override
  String get sectionAppearance => 'VZHĽAD';

  @override
  String get language => 'Jazyk';

  @override
  String get phoneLanguage => 'Jazyk telefónu';

  @override
  String phoneLanguageNow(String language) {
    return 'Jazyk telefónu ($language)';
  }

  @override
  String get languageHint => 'Platí aj pre widgety a pripomienky.';

  @override
  String get theme => 'Téma';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Svetlá';

  @override
  String get themeDark => 'Tmavá';

  @override
  String get seasonalThemes => 'Sezónne témy';

  @override
  String get sectionBackup => 'ZÁLOHA';

  @override
  String get exportBackup => 'Exportovať zálohu';

  @override
  String get exportBackupHint => 'Ulož všetky dátumy vývozu do súboru';

  @override
  String get importTitle => 'Importovať';

  @override
  String get importHint => 'Zo zálohy, zdieľaného súboru alebo QR kódu';

  @override
  String get backupSaved => 'Záloha uložená';

  @override
  String get sectionShare => 'ZDIEĽAJ S DOMÁCNOSŤOU';

  @override
  String get sendAsFile => 'Poslať ako súbor';

  @override
  String get showQrCode => 'Zobraziť QR kód';

  @override
  String get shareHint =>
      'Jednorazová kópia tvojich nadchádzajúcich vývozov. Ak ich neskôr zmeníš, zdieľaj ich znova.';

  @override
  String get shareTitle => 'Harmonogram vývozov z Trashifiera';

  @override
  String get nothingToShare =>
      'Zatiaľ nemáš žiadne nadchádzajúce vývozy na zdieľanie';

  @override
  String get licenses => 'Licencie';

  @override
  String get importSheetHint =>
      'Dátumy môžeš pridať k svojim alebo nimi svoje nahradiť.';

  @override
  String get fromFile => 'Zo súboru';

  @override
  String get fromFileHint => 'Záloha alebo harmonogram, ktorý ti niekto poslal';

  @override
  String get scanQrCode => 'Naskenovať QR kód';

  @override
  String get scanQrCodeHint => 'Cez „Zobraziť QR kód“ na druhom telefóne';

  @override
  String get scannerUnavailable =>
      'QR skener nie je dostupný. Potrebuje služby Google Play a pri prvom použití aj internetové pripojenie.';

  @override
  String get importFromFile => 'ZO SÚBORU';

  @override
  String get importFromLink => 'Z ODKAZU';

  @override
  String get importFromQr => 'Z QR KÓDU';

  @override
  String importCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importovať $count vývozov?',
      many: 'Importovať $count vývozov?',
      few: 'Importovať $count vývozy?',
      one: 'Importovať 1 vývoz?',
    );
    return '$_temp0';
  }

  @override
  String skippedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count záznamov je neplatných, preskočíme ich.',
      many: '$count záznamov je neplatných, preskočíme ich.',
      few: '$count záznamy sú neplatné, preskočíme ich.',
      one: '1 záznam je neplatný, preskočíme ho.',
    );
    return '$_temp0';
  }

  @override
  String currentPickups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Teraz máš $count vývozov. „Pridať“ ich ponechá, „Nahradiť všetko“ ich najprv odstráni.',
      many:
          'Teraz máš $count vývozov. „Pridať“ ich ponechá, „Nahradiť všetko“ ich najprv odstráni.',
      few:
          'Teraz máš $count vývozy. „Pridať“ ich ponechá, „Nahradiť všetko“ ich najprv odstráni.',
      one:
          'Teraz máš 1 vývoz. „Pridať“ ho ponechá, „Nahradiť všetko“ ho najprv odstráni.',
    );
    return '$_temp0';
  }

  @override
  String get addToMine => 'Pridať';

  @override
  String get replaceAll => 'Nahradiť všetko';

  @override
  String get importButton => 'Importovať';

  @override
  String importedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importovaných $count vývozov',
      many: 'Importovaných $count vývozov',
      few: 'Importované $count vývozy',
      one: 'Importovaný 1 vývoz',
    );
    return '$_temp0';
  }

  @override
  String get errorNotTrashifier => 'Toto nie je harmonogram z Trashifiera.';

  @override
  String get errorNewerVersion =>
      'Tento harmonogram je z novšej verzie Trashifiera. Najprv aktualizuj aplikáciu.';

  @override
  String get errorTooLarge => 'Súbor je príliš veľký na harmonogram.';

  @override
  String get errorInvalid =>
      'Tento harmonogram je poškodený a nedá sa importovať.';

  @override
  String get errorEmpty => 'Tento harmonogram neobsahuje žiadne vývozy.';

  @override
  String get errorUnavailable => 'Na tomto telefóne nie je dostupné.';

  @override
  String get errorFileFailed => 'Súbor sa nepodarilo prečítať ani zapísať.';

  @override
  String get qrTitle => 'Naskenuj a skopíruj harmonogram';

  @override
  String qrSubtitle(int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nadchádzajúcich vývozov · $range',
      many: '$count nadchádzajúcich vývozov · $range',
      few: '$count nadchádzajúce vývozy · $range',
      one: '1 nadchádzajúci vývoz · $range',
    );
    return '$_temp0';
  }

  @override
  String qrA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'QR kód s $count nadchádzajúcimi vývozmi',
      many: 'QR kód s $count nadchádzajúcimi vývozmi',
      few: 'QR kód s $count nadchádzajúcimi vývozmi',
      one: 'QR kód s 1 nadchádzajúcim vývozom',
    );
    return '$_temp0';
  }

  @override
  String get qrHint =>
      'Na druhom telefóne otvor Trashifier › Nastavenia › Importovať › Naskenovať QR kód. Pred importom sa vždy opýta.';
}
