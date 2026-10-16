/// A seasonal look for the whole app.
enum Season { none, halloween, christmas }

/// What the debug panel forces; [auto] picks the season from the date.
enum SeasonOverride { auto, normal, halloween, christmas }

/// Days that get their own drawing in the calendar while their season is on.
enum SpecialDay {
  halloween('Halloween'),
  christmasEve('Christmas Eve'),
  christmasDay('Christmas Day'),
  boxingDay('Boxing Day'),
  newYearsEve("New Year's Eve");

  final String label;

  const SpecialDay(this.label);
}

/// Bin Buddy's outfit for a season.
enum BuddyCostume { normal, pumpkin, santa }
