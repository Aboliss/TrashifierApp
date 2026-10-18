import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/l10n/l10n.dart';

void main() {
  group('DateFormatHelper', () {
    group('formatDate', () {
      test('should format date correctly for single digit day and month', () {
        final date = DateTime(2025, 1, 5);
        expect(DateFormatHelper.formatDate(date), equals('Jan 5'));
      });

      test('should format date correctly for double digit day and month', () {
        final date = DateTime(2025, 12, 25);
        expect(DateFormatHelper.formatDate(date), equals('Dec 25'));
      });

      test('should format all months correctly', () {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        for (int i = 0; i < 12; i++) {
          final date = DateTime(2025, i + 1, 15);
          expect(DateFormatHelper.formatDate(date), equals('${months[i]} 15'));
        }
      });
    });

    group('formatDayName', () {
      test('should format weekday names correctly', () {
        final weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        for (int i = 0; i < 7; i++) {
          final date = DateTime(2025, 9, 22 + i);
          expect(DateFormatHelper.formatDayName(date), equals(weekdays[i]));
        }
      });
    });

    group('calculateDaysUntil', () {
      test('should return 0 for today', () {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);

        expect(DateFormatHelper.calculateDaysUntil(todayNormalized), equals(0));
      });

      test('should return positive number for future dates', () {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));

        expect(DateFormatHelper.calculateDaysUntil(tomorrow), equals(1));

        final inFiveDays = today.add(const Duration(days: 5));
        expect(DateFormatHelper.calculateDaysUntil(inFiveDays), equals(5));
      });

      test('should return negative number for past dates', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        expect(DateFormatHelper.calculateDaysUntil(yesterday), equals(-1));
      });

      test('should ignore time component', () {
        final today = DateTime.now();
        final todayMorning = DateTime(today.year, today.month, today.day, 8, 0);
        final todayEvening = DateTime(
          today.year,
          today.month,
          today.day,
          20,
          0,
        );

        expect(DateFormatHelper.calculateDaysUntil(todayMorning), equals(0));
        expect(DateFormatHelper.calculateDaysUntil(todayEvening), equals(0));
      });
    });

    group('getDaysUntilText', () {
      test('should return "Today" for today', () {
        final today = DateTime.now();
        expect(DateFormatHelper.getDaysUntilText(today), equals('Today'));
      });

      test('should return "Tomorrow" for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateFormatHelper.getDaysUntilText(tomorrow), equals('Tomorrow'));
      });

      test('should return "in X days" for future dates', () {
        final today = DateTime.now();
        final inTwoDays = today.add(const Duration(days: 2));
        final inTenDays = today.add(const Duration(days: 10));

        expect(
          DateFormatHelper.getDaysUntilText(inTwoDays),
          equals('in 2 days'),
        );
        expect(
          DateFormatHelper.getDaysUntilText(inTenDays),
          equals('in 10 days'),
        );
      });

      test('should return "in X days" for past dates (negative)', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(
          DateFormatHelper.getDaysUntilText(yesterday),
          equals('in -1 days'),
        );
      });
    });

    group('isSameDate', () {
      test('should return true for same dates with different times', () {
        final date1 = DateTime(2025, 9, 25, 8, 30);
        final date2 = DateTime(2025, 9, 25, 20, 45);

        expect(DateFormatHelper.isSameDate(date1, date2), isTrue);
      });

      test('should return false for different dates', () {
        final date1 = DateTime(2025, 9, 25);
        final date2 = DateTime(2025, 9, 26);

        expect(DateFormatHelper.isSameDate(date1, date2), isFalse);
      });

      test('should return false for different months', () {
        final date1 = DateTime(2025, 9, 25);
        final date2 = DateTime(2025, 10, 25);

        expect(DateFormatHelper.isSameDate(date1, date2), isFalse);
      });

      test('should return false for different years', () {
        final date1 = DateTime(2025, 9, 25);
        final date2 = DateTime(2024, 9, 25);

        expect(DateFormatHelper.isSameDate(date1, date2), isFalse);
      });
    });

    group('isToday', () {
      test('should return true for today\'s date', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        expect(DateFormatHelper.isToday(today), isTrue);
      });

      test('should return true for today with different time', () {
        final now = DateTime.now();
        final todayDifferentTime = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
        );

        expect(DateFormatHelper.isToday(todayDifferentTime), isTrue);
      });

      test('should return false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        expect(DateFormatHelper.isToday(yesterday), isFalse);
      });

      test('should return false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        expect(DateFormatHelper.isToday(tomorrow), isFalse);
      });
    });

    group('isFuture', () {
      test('should return true for dates clearly in the future', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        expect(DateFormatHelper.isFuture(tomorrow), isTrue);
      });

      test('should return false for dates clearly in the past', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        expect(DateFormatHelper.isFuture(yesterday), isFalse);
      });

      test('should consider today future only before 8 AM', () {
        final today = DateTime(2025, 10, 5);

        expect(
          DateFormatHelper.isFuture(today, DateTime(2025, 10, 5, 7, 59)),
          isTrue,
        );
        expect(
          DateFormatHelper.isFuture(today, DateTime(2025, 10, 5, 8, 0)),
          isFalse,
        );
      });

      test('compares calendar days, not instants', () {
        // table_calendar produces UTC midnight. In timezones behind UTC that
        // instant is the previous local evening; tomorrow's pickup must still
        // count as upcoming late tonight.
        final tomorrowUtc = DateTime.utc(2025, 10, 6);
        final lateTonight = DateTime(2025, 10, 5, 23, 30);

        expect(DateFormatHelper.isFuture(tomorrowUtc, lateTonight), isTrue);
        expect(
          DateFormatHelper.calculateDaysUntil(tomorrowUtc, lateTonight),
          equals(1),
        );
      });
    });

    group('dateOnly', () {
      test('drops time and UTC flag', () {
        final result = DateFormatHelper.dateOnly(
          DateTime.utc(2025, 10, 5, 13, 45),
        );

        expect(result, equals(DateTime(2025, 10, 5)));
        expect(result.isUtc, isFalse);
      });
    });

    group('calculateDaysUntil across DST', () {
      test('counts calendar days even when a day is 23 or 25 hours', () {
        // Spring and autumn DST changes in the EU and US.
        expect(
          DateFormatHelper.calculateDaysUntil(
            DateTime(2026, 3, 30),
            DateTime(2026, 3, 28, 23, 0),
          ),
          equals(2),
        );
        expect(
          DateFormatHelper.calculateDaysUntil(
            DateTime(2025, 11, 3),
            DateTime(2025, 11, 1, 23, 0),
          ),
          equals(2),
        );
      });
    });
  });
  group('DateFormatHelper.formatTime', () {
    late bool saved24h;
    late String savedLanguage;
    late String? savedIntlLocale;

    setUp(() {
      saved24h = L10n.use24HourFormat;
      savedLanguage = L10n.localeName;
      savedIntlLocale = Intl.defaultLocale;
    });
    tearDown(() {
      L10n.use24HourFormat = saved24h;
      L10n.update(Locale(savedLanguage));
      Intl.defaultLocale = savedIntlLocale;
    });

    void useLanguage(String code) {
      L10n.update(Locale(code));
      expect(L10n.localeName, code);
    }

    test('defaults to the 12-hour clock', () {
      expect(L10n.use24HourFormat, isFalse);
    });

    for (final code in ['en', 'de']) {
      group('in $code', () {
        test('24-hour setting: "06:00" and "19:00"', () {
          useLanguage(code);
          L10n.use24HourFormat = true;
          expect(DateFormatHelper.formatTime(6, 0), '06:00');
          expect(DateFormatHelper.formatTime(19, 0), '19:00');
          expect(DateFormatHelper.formatTime(0, 5), '00:05');
          expect(DateFormatHelper.formatTime(12, 0), '12:00');
          expect(DateFormatHelper.formatTime(23, 59), '23:59');
        });

        test('12-hour setting: "6:00 AM" and "7:00 PM"', () {
          useLanguage(code);
          L10n.use24HourFormat = false;
          expect(DateFormatHelper.formatTime(6, 0), '6:00 AM');
          expect(DateFormatHelper.formatTime(19, 0), '7:00 PM');
          expect(DateFormatHelper.formatTime(0, 5), '12:05 AM');
          expect(DateFormatHelper.formatTime(12, 0), '12:00 PM');
          expect(DateFormatHelper.formatTime(23, 59), '11:59 PM');
        });
      });
    }

    test('the language no longer decides: German follows the setting', () {
      useLanguage('de');
      L10n.use24HourFormat = false;
      final twelve = DateFormatHelper.formatTime(19, 30);
      L10n.use24HourFormat = true;
      final twentyFour = DateFormatHelper.formatTime(19, 30);
      expect(twelve, '7:30 PM');
      expect(twentyFour, '19:30');
    });

    test('Spanish and Slovak follow the setting too, in their own style', () {
      // Their 24-hour pattern has no leading zero, and Spanish writes the
      // day period its own way.
      final expected = {
        'es': ('6:00', '19:00', '6:00 a. m.', '7:00 p. m.'),
        'sk': ('6:00', '19:00', '6:00 AM', '7:00 PM'),
      };
      for (final MapEntry(key: code, value: times) in expected.entries) {
        useLanguage(code);
        L10n.use24HourFormat = true;
        expect(DateFormatHelper.formatTime(6, 0), times.$1, reason: code);
        expect(DateFormatHelper.formatTime(19, 0), times.$2, reason: code);
        L10n.use24HourFormat = false;
        expect(DateFormatHelper.formatTime(6, 0), times.$3, reason: code);
        expect(DateFormatHelper.formatTime(19, 0), times.$4, reason: code);
        expect(
          DateFormatHelper.formatTime(19, 0),
          isNot(contains('\u202F')),
          reason: code,
        );
      }
    });
  });
}
