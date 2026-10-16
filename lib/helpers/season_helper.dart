import 'package:trashifier_app/models/season.dart';

/// Picks the seasonal theme and the special calendar days.
///
/// Keep the month rules in sync with `seasonFor` in TrashifierWidget.kt, which
/// themes the home screen widgets.
class SeasonHelper {
  /// Halloween all of October, Christmas all of December, unless [override]
  /// forces one (or none).
  static Season seasonFor(DateTime date, SeasonOverride override) {
    switch (override) {
      case SeasonOverride.normal:
        return Season.none;
      case SeasonOverride.halloween:
        return Season.halloween;
      case SeasonOverride.christmas:
        return Season.christmas;
      case SeasonOverride.auto:
        if (date.month == DateTime.october) return Season.halloween;
        if (date.month == DateTime.december) return Season.christmas;
        return Season.none;
    }
  }

  /// The special day on [date], if the active [season] decorates it.
  static SpecialDay? specialDayFor(DateTime date, Season season) {
    switch (season) {
      case Season.halloween:
        if (date.month == DateTime.october && date.day == 31) {
          return SpecialDay.halloween;
        }
        return null;
      case Season.christmas:
        if (date.month != DateTime.december) return null;
        switch (date.day) {
          case 24:
            return SpecialDay.christmasEve;
          case 25:
            return SpecialDay.christmasDay;
          case 26:
            return SpecialDay.boxingDay;
          case 31:
            return SpecialDay.newYearsEve;
        }
        return null;
      case Season.none:
        return null;
    }
  }

  static BuddyCostume costumeFor(Season season) {
    switch (season) {
      case Season.halloween:
        return BuddyCostume.pumpkin;
      case Season.christmas:
        return BuddyCostume.santa;
      case Season.none:
        return BuddyCostume.normal;
    }
  }

  /// Storage form of [override]; also read by the Android widgets.
  static String encodeOverride(SeasonOverride override) => override.name;

  /// Unknown or missing values fall back to [SeasonOverride.auto].
  static SeasonOverride decodeOverride(String? value) {
    for (final override in SeasonOverride.values) {
      if (override.name == value) return override;
    }
    return SeasonOverride.auto;
  }
}
