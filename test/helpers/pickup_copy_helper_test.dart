import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('PickupCopyHelper', () {
    // Thursday, Oct 15 2026, 10:00.
    final now = DateTime(2026, 10, 15, 10);

    PickupDay day(int dayOfMonth, List<TrashType> types) =>
        PickupDay(DateTime(2026, 10, dayOfMonth), types);

    group('headline', () {
      test('nothing planned', () {
        expect(PickupCopyHelper.headline(null, now), 'No bins planned yet');
      });

      test('today and tomorrow, one or several bins', () {
        expect(
          PickupCopyHelper.headline(day(15, [TrashType.bio]), now),
          'Bin day today!',
        );
        expect(
          PickupCopyHelper.headline(
            day(16, [TrashType.plastic, TrashType.paper]),
            now,
          ),
          'Big bin day tomorrow!',
        );
      });

      test('later this week names the weekday', () {
        expect(
          PickupCopyHelper.headline(day(20, [TrashType.bio]), now),
          'Bins out on Tuesday',
        );
      });

      test('a week or more away', () {
        expect(
          PickupCopyHelper.headline(day(23, [TrashType.trash]), now),
          'A quiet week for bins',
        );
      });

      group('in season', () {
        test('Halloween makes today and tomorrow spooky', () {
          expect(
            PickupCopyHelper.headline(
              day(15, [TrashType.bio]),
              now,
              Season.halloween,
            ),
            'Spooky bin day today!',
          );
          expect(
            PickupCopyHelper.headline(
              day(16, [TrashType.plastic, TrashType.paper]),
              now,
              Season.halloween,
            ),
            'Spooky bin day tomorrow!',
          );
        });

        test('Christmas makes today and tomorrow jolly', () {
          expect(
            PickupCopyHelper.headline(
              day(15, [TrashType.bio, TrashType.trash]),
              now,
              Season.christmas,
            ),
            'Jolly bin day today!',
          );
          expect(
            PickupCopyHelper.headline(
              day(16, [TrashType.paper]),
              now,
              Season.christmas,
            ),
            'Jolly bin day tomorrow!',
          );
        });

        test('no season keeps the usual wording', () {
          expect(
            PickupCopyHelper.headline(
              day(15, [TrashType.bio]),
              now,
              Season.none,
            ),
            'Bin day today!',
          );
          expect(
            PickupCopyHelper.headline(
              day(16, [TrashType.plastic, TrashType.paper]),
              now,
              Season.none,
            ),
            'Big bin day tomorrow!',
          );
        });

        test('later pickups keep the usual wording', () {
          for (final season in Season.values) {
            expect(
              PickupCopyHelper.headline(day(20, [TrashType.bio]), now, season),
              'Bins out on Tuesday',
              reason: '$season',
            );
            expect(
              PickupCopyHelper.headline(
                day(23, [TrashType.trash]),
                now,
                season,
              ),
              'A quiet week for bins',
              reason: '$season',
            );
            expect(
              PickupCopyHelper.headline(null, now, season),
              'No bins planned yet',
              reason: '$season',
            );
          }
        });
      });
    });

    test('relativeDay', () {
      expect(
        PickupCopyHelper.relativeDay(DateTime(2026, 10, 15), now),
        'Today',
      );
      expect(
        PickupCopyHelper.relativeDay(DateTime(2026, 10, 16), now),
        'Tomorrow',
      );
      expect(
        PickupCopyHelper.relativeDay(DateTime(2026, 10, 20), now),
        'In 5 days',
      );
      expect(
        PickupCopyHelper.relativeDay(DateTime(2026, 10, 14), now),
        'Yesterday',
      );
      expect(
        PickupCopyHelper.relativeDay(DateTime(2026, 10, 12), now),
        '3 days ago',
      );
    });

    group('reminderLine', () {
      test('tomorrow before and after the reminder time', () {
        final tomorrow = day(16, [TrashType.paper]);
        expect(
          PickupCopyHelper.reminderLine(tomorrow, now),
          'Reminder tonight at 7:00 PM',
        );
        expect(
          PickupCopyHelper.reminderLine(tomorrow, DateTime(2026, 10, 15, 20)),
          'Put the bins out tonight',
        );
      });

      test('later pickups name the evening before', () {
        expect(
          PickupCopyHelper.reminderLine(day(20, [TrashType.bio]), now),
          'Reminder on Monday at 7:00 PM',
        );
      });

      test('today', () {
        expect(
          PickupCopyHelper.reminderLine(day(15, [TrashType.bio]), now),
          'Pickup is today',
        );
      });
    });

    test('formatHour', () {
      expect(PickupCopyHelper.formatHour(19), '7:00 PM');
      expect(PickupCopyHelper.formatHour(0), '12:00 AM');
      expect(PickupCopyHelper.formatHour(12), '12:00 PM');
      expect(PickupCopyHelper.formatHour(7), '7:00 AM');
    });
  });
}
