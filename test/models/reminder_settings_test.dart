import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/reminder_settings.dart';

void main() {
  group('ReminderSettings', () {
    test('defaults to the evening before at 7 PM', () {
      const d = ReminderSettings.defaults;
      expect(d.daysBefore, 1);
      expect(d.hour, 19);
      expect(d.minute, 0);
      expect(d.dayBefore, isTrue);
    });

    group('validated', () {
      test('keeps values in range', () {
        expect(
          ReminderSettings.validated(daysBefore: 0, hour: 6, minute: 30),
          const ReminderSettings(daysBefore: 0, hour: 6, minute: 30),
        );
        expect(
          ReminderSettings.validated(daysBefore: 1, hour: 0, minute: 0),
          const ReminderSettings(daysBefore: 1, hour: 0, minute: 0),
        );
        expect(
          ReminderSettings.validated(daysBefore: 1, hour: 23, minute: 59),
          const ReminderSettings(daysBefore: 1, hour: 23, minute: 59),
        );
      });

      test('missing values fall back to the defaults', () {
        expect(ReminderSettings.validated(), ReminderSettings.defaults);
        expect(
          ReminderSettings.validated(hour: 7),
          const ReminderSettings(daysBefore: 1, hour: 7, minute: 0),
        );
      });

      test('out-of-range values fall back field by field', () {
        expect(
          ReminderSettings.validated(daysBefore: 2, hour: 24, minute: 60),
          ReminderSettings.defaults,
        );
        expect(
          ReminderSettings.validated(daysBefore: -1, hour: -1, minute: -1),
          ReminderSettings.defaults,
        );
        // Only the broken field is replaced.
        expect(
          ReminderSettings.validated(daysBefore: 0, hour: 99, minute: 15),
          const ReminderSettings(daysBefore: 0, hour: 19, minute: 15),
        );
      });
    });

    group('timeFor', () {
      test('the day before at the chosen time', () {
        const settings = ReminderSettings(daysBefore: 1, hour: 18, minute: 45);
        expect(
          settings.timeFor(DateTime(2026, 10, 20)),
          DateTime(2026, 10, 19, 18, 45),
        );
      });

      test('on pickup day at the chosen time', () {
        const settings = ReminderSettings(daysBefore: 0, hour: 6, minute: 30);
        expect(
          settings.timeFor(DateTime(2026, 10, 20)),
          DateTime(2026, 10, 20, 6, 30),
        );
      });

      test('crosses month and year boundaries', () {
        const settings = ReminderSettings.defaults;
        expect(
          settings.timeFor(DateTime(2026, 11, 1)),
          DateTime(2026, 10, 31, 19),
        );
        expect(
          settings.timeFor(DateTime(2026, 3, 1)),
          DateTime(2026, 2, 28, 19),
        );
        expect(
          settings.timeFor(DateTime(2028, 3, 1)),
          DateTime(2028, 2, 29, 19),
        );
        expect(
          settings.timeFor(DateTime(2027, 1, 1)),
          DateTime(2026, 12, 31, 19),
        );
      });

      test('ignores the time of the pickup date', () {
        const settings = ReminderSettings(daysBefore: 0, hour: 7, minute: 5);
        expect(
          settings.timeFor(DateTime(2026, 10, 20, 23, 59)),
          DateTime(2026, 10, 20, 7, 5),
        );
      });
    });

    test('copyWith changes only the given fields and validates', () {
      const settings = ReminderSettings(daysBefore: 1, hour: 19, minute: 0);
      expect(
        settings.copyWith(daysBefore: 0),
        const ReminderSettings(daysBefore: 0, hour: 19, minute: 0),
      );
      expect(
        settings.copyWith(hour: 6, minute: 30),
        const ReminderSettings(daysBefore: 1, hour: 6, minute: 30),
      );
      expect(settings.copyWith(hour: 42), settings);
    });

    test('equality and hashCode follow the values', () {
      const a = ReminderSettings(daysBefore: 0, hour: 6, minute: 30);
      const b = ReminderSettings(daysBefore: 0, hour: 6, minute: 30);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ReminderSettings(daysBefore: 1, hour: 6)));
      expect(a, isNot(const ReminderSettings(daysBefore: 0, hour: 6)));
    });
  });
}
