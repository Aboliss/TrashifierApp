import 'package:trashifier_app/l10n/l10n.dart';

/// A seasonal look for the whole app.
enum Season { none, halloween, christmas }

/// What the debug panel forces; [auto] picks the season from the date.
enum SeasonOverride { auto, normal, halloween, christmas }

/// Days that get their own drawing in the calendar while their season is on.
enum SpecialDay {
  halloween,
  christmasEve,
  christmasDay,
  boxingDay,
  newYearsEve;

  /// The day's name in the app language.
  String get label {
    final l = L10n.current;
    switch (this) {
      case SpecialDay.halloween:
        return l.specialHalloween;
      case SpecialDay.christmasEve:
        return l.specialChristmasEve;
      case SpecialDay.christmasDay:
        return l.specialChristmasDay;
      case SpecialDay.boxingDay:
        return l.specialBoxingDay;
      case SpecialDay.newYearsEve:
        return l.specialNewYearsEve;
    }
  }
}

/// Bin Buddy's outfit for a season.
enum BuddyCostume { normal, pumpkin, santa }
