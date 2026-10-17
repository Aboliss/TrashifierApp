import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('NotificationHelper', () {
    // Fixed "now" so results don't depend on when the tests run.
    final now = DateTime(2025, 10, 1, 12, 0);

    Map<TrashType, List<DateTime>> dates({
      List<DateTime> plastic = const [],
      List<DateTime> paper = const [],
      List<DateTime> trash = const [],
      List<DateTime> bio = const [],
    }) {
      return {
        TrashType.plastic: plastic,
        TrashType.paper: paper,
        TrashType.trash: trash,
        TrashType.bio: bio,
      };
    }

    group('notificationId', () {
      test('is unique per date and type on the same day', () {
        final day = DateTime(2025, 10, 5);
        final ids = TrashType.values
            .map((type) => NotificationHelper.notificationId(day, type))
            .toSet();

        expect(ids.length, equals(TrashType.values.length));
      });

      test('ignores time and UTC flag', () {
        expect(
          NotificationHelper.notificationId(
            DateTime.utc(2025, 10, 5),
            TrashType.bio,
          ),
          equals(
            NotificationHelper.notificationId(
              DateTime(2025, 10, 5, 15, 30),
              TrashType.bio,
            ),
          ),
        );
      });

      test('fits in a 32-bit int', () {
        final id = NotificationHelper.notificationId(
          DateTime(2099, 12, 31),
          TrashType.bio,
        );
        expect(id, lessThan(2147483647));
      });

      test('can be decoded back', () {
        final id = NotificationHelper.notificationId(
          DateTime(2025, 10, 5),
          TrashType.paper,
        );
        final decoded = NotificationHelper.decodeNotificationId(id);

        expect(decoded, isNotNull);
        expect(decoded!.type, equals(TrashType.paper));
        expect(decoded.pickupDate, equals(DateTime(2025, 10, 5)));
      });

      test('decoding uses the given reminder settings', () {
        final id = NotificationHelper.notificationId(
          DateTime(2025, 10, 5),
          TrashType.bio,
        );
        expect(
          NotificationHelper.decodeNotificationId(id)!.time,
          DateTime(2025, 10, 4, 19),
        );
        expect(
          NotificationHelper.decodeNotificationId(
            id,
            const ReminderSettings(daysBefore: 0, hour: 6, minute: 30),
          )!.time,
          DateTime(2025, 10, 5, 6, 30),
        );
      });

      test('decoding rejects foreign IDs', () {
        expect(NotificationHelper.decodeNotificationId(999), isNull);
        expect(NotificationHelper.decodeNotificationId(-5), isNull);
      });
    });

    group('planReminders', () {
      test('schedules the evening before at the reminder hour', () {
        final plan = NotificationHelper.planReminders(
          dates(plastic: [DateTime(2025, 10, 5)]),
          now: now,
        );

        expect(plan.length, equals(1));
        expect(plan.first.time, equals(DateTime(2025, 10, 4, 19, 0)));
      });

      test('crosses month boundaries', () {
        final plan = NotificationHelper.planReminders(
          dates(paper: [DateTime(2025, 11, 1)]),
          now: now,
        );

        expect(plan.first.time, equals(DateTime(2025, 10, 31, 19, 0)));
      });

      test('spaces same-day bins by the gap, in type order', () {
        final day = DateTime(2025, 10, 5);
        final plan = NotificationHelper.planReminders(
          dates(bio: [day], plastic: [day], paper: [day]),
          now: now,
        );

        expect(plan.map((r) => r.type).toList(), [
          TrashType.plastic,
          TrashType.paper,
          TrashType.bio,
        ]);
        expect(plan[0].time, equals(DateTime(2025, 10, 4, 19, 0, 0)));
        expect(plan[1].time, equals(DateTime(2025, 10, 4, 19, 0, 20)));
        expect(plan[2].time, equals(DateTime(2025, 10, 4, 19, 0, 40)));
        expect(plan.map((r) => r.id).toSet().length, equals(3));
      });

      test('skips reminders whose time has passed', () {
        final plan = NotificationHelper.planReminders(
          dates(
            trash: [
              DateTime(2025, 9, 30), // reminder was yesterday
              DateTime(2025, 10, 1), // reminder was yesterday evening
              DateTime(2025, 10, 2), // reminder tonight
            ],
          ),
          now: now,
        );

        expect(plan.length, equals(1));
        expect(plan.first.pickupDate, equals(DateTime(2025, 10, 2)));
      });

      test('treats UTC dates from the calendar as calendar days', () {
        final plan = NotificationHelper.planReminders(
          dates(plastic: [DateTime.utc(2025, 10, 5)]),
          now: now,
        );

        expect(plan.first.pickupDate, equals(DateTime(2025, 10, 5)));
        expect(plan.first.time, equals(DateTime(2025, 10, 4, 19, 0)));
      });

      test('is sorted soonest first and respects the limit', () {
        final plan = NotificationHelper.planReminders(
          dates(
            paper: [DateTime(2025, 10, 20), DateTime(2025, 10, 6)],
            plastic: [DateTime(2025, 10, 13)],
          ),
          now: now,
          limit: 2,
        );

        expect(plan.map((r) => r.pickupDate).toList(), [
          DateTime(2025, 10, 6),
          DateTime(2025, 10, 13),
        ]);
      });

      test('uses a custom time the day before', () {
        final plan = NotificationHelper.planReminders(
          dates(plastic: [DateTime(2025, 10, 5)]),
          now: now,
          settings: const ReminderSettings(daysBefore: 1, hour: 21, minute: 15),
        );

        expect(plan.single.time, equals(DateTime(2025, 10, 4, 21, 15)));
      });

      test('on pickup day, spacing same-day bins from the chosen time', () {
        final day = DateTime(2025, 10, 5);
        final plan = NotificationHelper.planReminders(
          dates(plastic: [day], bio: [day]),
          now: now,
          settings: const ReminderSettings(daysBefore: 0, hour: 6, minute: 30),
        );

        expect(plan.map((r) => r.time).toList(), [
          DateTime(2025, 10, 5, 6, 30, 0),
          DateTime(2025, 10, 5, 6, 30, 20),
        ]);
        expect(plan.every((r) => r.pickupDate == day), isTrue);
      });

      test('on pickup day, keeps today\'s reminder until it fires', () {
        const morning = ReminderSettings(daysBefore: 0, hour: 6, minute: 30);
        final today = dates(trash: [DateTime(2025, 10, 1)]);

        // 12:00 is past 6:30; at 6:00 it is still ahead.
        expect(
          NotificationHelper.planReminders(today, now: now, settings: morning),
          isEmpty,
        );
        final early = NotificationHelper.planReminders(
          today,
          now: DateTime(2025, 10, 1, 6),
          settings: morning,
        );
        expect(early.single.time, equals(DateTime(2025, 10, 1, 6, 30)));
      });

      test('on pickup day, crosses month boundaries correctly', () {
        final plan = NotificationHelper.planReminders(
          dates(paper: [DateTime(2025, 11, 1)]),
          now: now,
          settings: const ReminderSettings(daysBefore: 0, hour: 7, minute: 0),
        );

        expect(plan.single.time, equals(DateTime(2025, 11, 1, 7, 0)));
      });

      test('reminderTime defaults to the evening before', () {
        expect(
          NotificationHelper.reminderTime(DateTime(2025, 10, 5), 1),
          equals(DateTime(2025, 10, 4, 19, 0, 20)),
        );
      });

      test('deduplicates repeated dates', () {
        final plan = NotificationHelper.planReminders(
          dates(bio: [DateTime(2025, 10, 5), DateTime(2025, 10, 5, 8)]),
          now: now,
        );

        expect(plan.length, equals(1));
      });
    });
  });
}
