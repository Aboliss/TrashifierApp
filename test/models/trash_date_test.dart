import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('TrashDate', () {
    late DateTime testDate;
    late TrashType testType;

    setUp(() {
      testDate = DateTime(2025, 9, 25, 10, 30);
      testType = TrashType.plastic;
    });

    group('Constructor and Factory Methods', () {
      test('should create TrashDate with required parameters', () {
        final trashDate = TrashDate(date: testDate, type: testType);

        expect(trashDate.date, equals(testDate));
        expect(trashDate.type, equals(testType));
      });

      test('should create TrashDate from DateTime using factory', () {
        final trashDate = TrashDate.fromDateTime(testDate, testType);

        expect(trashDate.date, equals(testDate));
        expect(trashDate.type, equals(testType));
      });

      test('should create list of TrashDate from DateTime list', () {
        final dates = [DateTime(2025, 9, 25), DateTime(2025, 9, 26), DateTime(2025, 9, 27)];

        final trashDates = TrashDate.fromDateList(dates, testType);

        expect(trashDates.length, equals(3));
        expect(trashDates[0].date, equals(dates[0]));
        expect(trashDates[1].date, equals(dates[1]));
        expect(trashDates[2].date, equals(dates[2]));
        expect(trashDates.every((td) => td.type == testType), isTrue);
      });
    });

    group('Date Comparison Methods', () {
      test('isSameDate should return true for same date different time', () {
        final trashDate = TrashDate(date: DateTime(2025, 9, 25, 14, 30), type: testType);
        final otherDate = DateTime(2025, 9, 25, 8, 0);

        expect(trashDate.isSameDate(otherDate), isTrue);
      });

      test('isSameDate should return false for different dates', () {
        final trashDate = TrashDate(date: DateTime(2025, 9, 25), type: testType);
        final otherDate = DateTime(2025, 9, 26);

        expect(trashDate.isSameDate(otherDate), isFalse);
      });

      test('isToday should return true for today\'s date', () {
        final today = DateTime.now();
        final todayTrashDate = TrashDate(date: today, type: testType);

        expect(todayTrashDate.isToday, isTrue);
      });

      test('isFuture should return true for future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final futureTrashDate = TrashDate(date: futureDate, type: testType);

        expect(futureTrashDate.isFuture, isTrue);
      });
    });

    group('Formatted Properties', () {
      test('should return correct formatted date', () {
        final trashDate = TrashDate(date: DateTime(2025, 9, 25), type: testType);
        expect(trashDate.formattedDate, equals('Sep 25'));
      });

      test('should return correct day name', () {
        final thursday = DateTime(2025, 9, 25);
        final trashDate = TrashDate(date: thursday, type: testType);
        expect(trashDate.dayName, equals('Thursday'));
      });

      test('should calculate days until correctly', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowTrashDate = TrashDate(date: tomorrow, type: testType);

        expect(tomorrowTrashDate.daysUntil, equals(1));
      });

      test('should return correct days until text', () {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final inTwoDays = today.add(const Duration(days: 2));

        final todayTrashDate = TrashDate(date: today, type: testType);
        final tomorrowTrashDate = TrashDate(date: tomorrow, type: testType);
        final futureTrshDate = TrashDate(date: inTwoDays, type: testType);

        expect(todayTrashDate.daysUntilText, equals('Today'));
        expect(tomorrowTrashDate.daysUntilText, equals('Tomorrow'));
        expect(futureTrshDate.daysUntilText, equals('in 2 days'));
      });
    });

    group('Equality and Hash', () {
      test('should be equal for same date and type', () {
        final trashDate1 = TrashDate(date: DateTime(2025, 9, 25, 10, 0), type: TrashType.plastic);
        final trashDate2 = TrashDate(date: DateTime(2025, 9, 25, 14, 30), type: TrashType.plastic);

        expect(trashDate1, equals(trashDate2));
      });

      test('should not be equal for different types', () {
        final trashDate1 = TrashDate(date: testDate, type: TrashType.plastic);
        final trashDate2 = TrashDate(date: testDate, type: TrashType.paper);

        expect(trashDate1, isNot(equals(trashDate2)));
      });

      test('should not be equal for different dates', () {
        final trashDate1 = TrashDate(date: DateTime(2025, 9, 25), type: testType);
        final trashDate2 = TrashDate(date: DateTime(2025, 9, 26), type: testType);

        expect(trashDate1, isNot(equals(trashDate2)));
      });

      test('should have same hash code for equal objects', () {
        final trashDate1 = TrashDate(date: DateTime(2025, 9, 25, 10, 0), type: TrashType.plastic);
        final trashDate2 = TrashDate(date: DateTime(2025, 9, 25, 14, 30), type: TrashType.plastic);

        expect(trashDate1.hashCode, equals(trashDate2.hashCode));
      });
    });

    group('toString', () {
      test('should return correct string representation', () {
        final trashDate = TrashDate(date: DateTime(2025, 9, 25), type: TrashType.plastic);

        expect(trashDate.toString(), equals('TrashDate{date: Sep 25, type: TrashType.plastic}'));
      });
    });
  });
}
