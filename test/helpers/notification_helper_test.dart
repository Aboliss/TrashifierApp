import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('NotificationHelper Logic Tests', () {
    group('Date Processing Logic', () {
      test('should identify newly added dates correctly', () {
        final oldDates = [DateTime(2025, 9, 25), DateTime(2025, 9, 26)];

        final newDates = [DateTime(2025, 9, 25), DateTime(2025, 9, 27), DateTime(2025, 9, 28)];

        final newlyAddedDates = newDates.where((newDate) => !oldDates.any((d) => DateFormatHelper.isSameDate(d, newDate))).toList();

        expect(newlyAddedDates.length, equals(2));
        expect(newlyAddedDates[0].day, equals(27));
        expect(newlyAddedDates[1].day, equals(28));
      });

      test('should identify removed dates correctly', () {
        final oldDates = [DateTime(2025, 9, 25), DateTime(2025, 9, 26), DateTime(2025, 9, 27)];

        final newDates = [DateTime(2025, 9, 25)];

        final removedDates = oldDates.where((existingDate) => !newDates.any((s) => DateFormatHelper.isSameDate(s, existingDate))).toList();

        expect(removedDates.length, equals(2));
        expect(removedDates[0].day, equals(26));
        expect(removedDates[1].day, equals(27));
      });

      test('should handle same dates with different times', () {
        final oldDates = [DateTime(2025, 9, 25, 8, 0)];
        final newDates = [DateTime(2025, 9, 25, 14, 30)];

        final newlyAddedDates = newDates.where((newDate) => !oldDates.any((d) => DateFormatHelper.isSameDate(d, newDate))).toList();

        final removedDates = oldDates.where((existingDate) => !newDates.any((s) => DateFormatHelper.isSameDate(s, existingDate))).toList();

        expect(newlyAddedDates.length, equals(0));
        expect(removedDates.length, equals(0));
      });

      test('should handle empty lists', () {
        final oldDates = <DateTime>[];
        final newDates = [DateTime(2025, 9, 25)];

        final newlyAddedDates = newDates.where((newDate) => !oldDates.any((d) => DateFormatHelper.isSameDate(d, newDate))).toList();

        expect(newlyAddedDates.length, equals(1));
        expect(newlyAddedDates.first.day, equals(25));
      });

      test('should filter past dates from scheduling', () {
        final now = DateTime.now();
        final dates = [now.subtract(const Duration(days: 2)), now.subtract(const Duration(days: 1)), now.add(const Duration(days: 1)), now.add(const Duration(days: 2))];

        final validDates = <DateTime>[];
        for (var date in dates) {
          final scheduledTime = DateTime(date.year, date.month, date.day - 1, 19, 0);
          if (!scheduledTime.isBefore(DateTime.now())) {
            validDates.add(date);
          }
        }

        expect(validDates.length, equals(2));
      });
    });

    group('Notification ID Generation', () {
      test('should generate consistent IDs for dates', () {
        final date1 = DateTime(2025, 9, 25, 10, 0);
        final date2 = DateTime(2025, 9, 25, 15, 30);
        final date3 = DateTime(2025, 9, 26, 10, 0);

        final id1 = date1.hashCode;
        final id2 = date2.hashCode;
        final id3 = date3.hashCode;

        expect(id1, isNot(equals(id2)));
        expect(id1, isNot(equals(id3)));
        expect(id2, isNot(equals(id3)));
      });

      test('should generate unique IDs for different dates', () {
        final dates = List.generate(10, (index) => DateTime(2025, 9, 25 + index));
        final ids = dates.map((date) => date.hashCode).toSet();

        expect(ids.length, equals(10));
      });
    });

    group('Trash Type Integration', () {
      test('should work with all trash types', () {
        for (final trashType in TrashType.values) {
          expect(() => trashType.toString(), returnsNormally);
          expect(trashType.toString(), isNotEmpty);
        }
      });
    });
  });
}
