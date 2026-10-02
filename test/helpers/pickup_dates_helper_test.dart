import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('PickupDatesHelper', () {
    final day = DateTime(2025, 10, 5);

    Map<TrashType, List<DateTime>> dates() => {
      TrashType.plastic: [DateTime(2025, 10, 1), day],
      TrashType.paper: [day],
      TrashType.trash: [DateTime(2025, 10, 12)],
      TrashType.bio: [],
    };

    group('typesOn', () {
      test('returns every type collected that day', () {
        expect(
          PickupDatesHelper.typesOn(dates(), day),
          equals({TrashType.plastic, TrashType.paper}),
        );
      });

      test('matches by calendar day, ignoring time and UTC', () {
        expect(
          PickupDatesHelper.typesOn(dates(), DateTime.utc(2025, 10, 5, 9)),
          equals({TrashType.plastic, TrashType.paper}),
        );
      });

      test('is empty for a day without pickups', () {
        expect(
          PickupDatesHelper.typesOn(dates(), DateTime(2025, 10, 6)),
          isEmpty,
        );
      });
    });

    group('setTypesForDay', () {
      test('returns no changes when the selection is unchanged', () {
        expect(
          PickupDatesHelper.setTypesForDay(dates(), day, {
            TrashType.plastic,
            TrashType.paper,
          }),
          isEmpty,
        );
      });

      test('adds and removes only the affected types', () {
        final changes = PickupDatesHelper.setTypesForDay(dates(), day, {
          TrashType.plastic,
          TrashType.bio,
        });

        expect(changes.keys.toSet(), equals({TrashType.paper, TrashType.bio}));
        expect(changes[TrashType.paper], isEmpty);
        expect(changes[TrashType.bio], equals([day]));
      });

      test('keeps other dates and sorts the result', () {
        final changes = PickupDatesHelper.setTypesForDay(
          dates(),
          DateTime(2025, 10, 3),
          {TrashType.plastic, TrashType.paper},
        );

        expect(
          changes[TrashType.plastic],
          equals([DateTime(2025, 10, 1), DateTime(2025, 10, 3), day]),
        );
      });

      test('stores the day as a local calendar day', () {
        final changes = PickupDatesHelper.setTypesForDay(
          dates(),
          DateTime.utc(2025, 10, 20, 15),
          {TrashType.trash},
        );

        expect(
          changes[TrashType.trash],
          equals([DateTime(2025, 10, 12), DateTime(2025, 10, 20)]),
        );
        expect(changes[TrashType.trash]!.last.isUtc, isFalse);
      });

      test('clearing the selection removes the day everywhere', () {
        final changes = PickupDatesHelper.setTypesForDay(dates(), day, {});

        expect(changes[TrashType.plastic], equals([DateTime(2025, 10, 1)]));
        expect(changes[TrashType.paper], isEmpty);
        expect(changes.containsKey(TrashType.trash), isFalse);
      });
    });
  });
}
