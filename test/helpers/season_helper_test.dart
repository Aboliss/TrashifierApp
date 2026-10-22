import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/season_helper.dart';
import 'package:trashifier_app/models/season.dart';

void main() {
  group('SeasonHelper', () {
    group('seasonFor', () {
      test('auto follows the month, including the first and last days', () {
        final cases = {
          DateTime(2026, 9, 30, 23, 59): Season.none,
          DateTime(2026, 10, 1): Season.halloween,
          DateTime(2026, 10, 31, 23, 59): Season.halloween,
          DateTime(2026, 11, 1): Season.none,
          DateTime(2026, 11, 30, 23, 59): Season.none,
          DateTime(2026, 12, 1): Season.christmas,
          DateTime(2026, 12, 31, 23, 59): Season.christmas,
          DateTime(2027, 1, 1): Season.none,
          DateTime(2027, 6, 15): Season.none,
        };
        cases.forEach((date, season) {
          expect(
            SeasonHelper.seasonFor(date, SeasonOverride.auto),
            season,
            reason: '$date',
          );
        });
      });

      test('normal turns the season off, even in October and December', () {
        for (final date in [
          DateTime(2026, 10, 31),
          DateTime(2026, 12, 25),
          DateTime(2026, 3, 1),
        ]) {
          expect(
            SeasonHelper.seasonFor(date, SeasonOverride.normal),
            Season.none,
          );
        }
      });

      test('halloween and christmas force their season all year', () {
        for (final date in [
          DateTime(2026, 3, 1),
          DateTime(2026, 10, 15),
          DateTime(2026, 12, 25),
        ]) {
          expect(
            SeasonHelper.seasonFor(date, SeasonOverride.halloween),
            Season.halloween,
          );
          expect(
            SeasonHelper.seasonFor(date, SeasonOverride.christmas),
            Season.christmas,
          );
        }
      });
    });

    group('specialDayFor', () {
      test('Halloween is Oct 31 only', () {
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 10, 31), Season.halloween),
          SpecialDay.halloween,
        );
        expect(
          SeasonHelper.specialDayFor(
            DateTime(2026, 10, 31, 22, 30),
            Season.halloween,
          ),
          SpecialDay.halloween,
        );
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 10, 30), Season.halloween),
          isNull,
        );
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 11, 1), Season.halloween),
          isNull,
        );
        // Day 31 of another month is not Halloween.
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 12, 31), Season.halloween),
          isNull,
        );
      });

      test('the Christmas days', () {
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 12, 24), Season.christmas),
          SpecialDay.christmasEve,
        );
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 12, 25), Season.christmas),
          SpecialDay.christmasDay,
        );
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 12, 26), Season.christmas),
          SpecialDay.boxingDay,
        );
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 12, 31), Season.christmas),
          SpecialDay.newYearsEve,
        );
      });

      test('other days around Christmas are not special', () {
        for (final date in [
          DateTime(2026, 12, 1),
          DateTime(2026, 12, 23),
          DateTime(2026, 12, 27),
          DateTime(2026, 12, 30),
          DateTime(2027, 1, 1),
          // Same day numbers in other months.
          DateTime(2026, 11, 24),
          DateTime(2026, 1, 25),
          DateTime(2026, 10, 31),
        ]) {
          expect(
            SeasonHelper.specialDayFor(date, Season.christmas),
            isNull,
            reason: '$date',
          );
        }
      });

      test('special days need their own season', () {
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 10, 31), Season.christmas),
          isNull,
        );
        expect(
          SeasonHelper.specialDayFor(DateTime(2026, 10, 31), Season.none),
          isNull,
        );
        for (final day in [24, 25, 26, 31]) {
          final date = DateTime(2026, 12, day);
          expect(
            SeasonHelper.specialDayFor(date, Season.halloween),
            isNull,
            reason: '$date',
          );
          expect(
            SeasonHelper.specialDayFor(date, Season.none),
            isNull,
            reason: '$date',
          );
        }
      });

      test('labels', () {
        expect(SpecialDay.halloween.label, 'Halloween');
        expect(SpecialDay.christmasEve.label, 'Christmas Eve');
        expect(SpecialDay.christmasDay.label, 'Christmas Day');
        expect(SpecialDay.boxingDay.label, 'Boxing Day');
        expect(SpecialDay.newYearsEve.label, 'New Year’s Eve');
      });
    });

    test('costumeFor', () {
      expect(SeasonHelper.costumeFor(Season.none), BuddyCostume.normal);
      expect(SeasonHelper.costumeFor(Season.halloween), BuddyCostume.pumpkin);
      expect(SeasonHelper.costumeFor(Season.christmas), BuddyCostume.santa);
    });

    group('override storage', () {
      test('every override survives a round trip', () {
        for (final override in SeasonOverride.values) {
          expect(
            SeasonHelper.decodeOverride(SeasonHelper.encodeOverride(override)),
            override,
          );
        }
      });

      test('uses the enum names the Android widgets read', () {
        expect(SeasonHelper.encodeOverride(SeasonOverride.auto), 'auto');
        expect(SeasonHelper.encodeOverride(SeasonOverride.normal), 'normal');
        expect(
          SeasonHelper.encodeOverride(SeasonOverride.halloween),
          'halloween',
        );
        expect(
          SeasonHelper.encodeOverride(SeasonOverride.christmas),
          'christmas',
        );
      });

      test('missing or unknown values fall back to auto', () {
        for (final value in [null, '', 'easter', 'Christmas', ' halloween']) {
          expect(
            SeasonHelper.decodeOverride(value),
            SeasonOverride.auto,
            reason: '$value',
          );
        }
      });
    });
  });
}
