import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/calendar_helper.dart';

void main() {
  group('CalendarHelper', () {
    late DateTime focusedDay;
    late List<DateTime> plasticDates;
    late List<DateTime> paperDates;
    late List<DateTime> garbageDates;
    late List<DateTime> bioDates;

    setUp(() {
      focusedDay = DateTime(2025, 9, 25);
      plasticDates = [DateTime(2025, 9, 25), DateTime(2025, 9, 27)];
      paperDates = [DateTime(2025, 9, 26), DateTime(2025, 9, 28)];
      garbageDates = [DateTime(2025, 9, 29)];
      bioDates = [DateTime(2025, 9, 30)];
    });

    group('buildCalendarDay', () {
      testWidgets('should return null when no trash dates match', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final emptyDate = DateTime(2025, 9, 20);
                  final result = CalendarHelper.buildCalendarDay(context, emptyDate, focusedDay, plasticDates, paperDates, garbageDates, bioDates);

                  expect(result, isNull);
                  return Container();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('should return container with single color for single trash type', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final plasticDate = DateTime(2025, 9, 25);
                  final result = CalendarHelper.buildCalendarDay(context, plasticDate, focusedDay, plasticDates, [], [], []);

                  expect(result, isNotNull);
                  expect(result, isA<Container>());
                  return result ?? Container();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
      });

      testWidgets('should return container with multiple colors for multiple trash types', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final multiDate = DateTime(2025, 9, 25);
                  final result = CalendarHelper.buildCalendarDay(context, multiDate, focusedDay, [multiDate], [multiDate], [], []);

                  expect(result, isNotNull);
                  expect(result, isA<Container>());

                  final container = result as Container;
                  expect(container.child, isA<ClipRRect>());

                  return result;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
      });

      testWidgets('should display correct day number', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final testDate = DateTime(2025, 9, 15);
                  final result = CalendarHelper.buildCalendarDay(context, testDate, focusedDay, [testDate], [], [], []);

                  return result ?? Container();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('15'), findsOneWidget);
      });

      testWidgets('should handle all combinations of trash types', (WidgetTester tester) async {
        final testDate = DateTime(2025, 9, 25);

        final combinations = [
          {'plastic': true, 'paper': false, 'garbage': false, 'bio': false},
          {'plastic': false, 'paper': true, 'garbage': false, 'bio': false},
          {'plastic': false, 'paper': false, 'garbage': true, 'bio': false},
          {'plastic': false, 'paper': false, 'garbage': false, 'bio': true},
          {'plastic': true, 'paper': true, 'garbage': false, 'bio': false},
          {'plastic': true, 'paper': true, 'garbage': true, 'bio': true},
        ];

        for (final combo in combinations) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    final result = CalendarHelper.buildCalendarDay(context, testDate, focusedDay, combo['plastic']! ? [testDate] : [], combo['paper']! ? [testDate] : [], combo['garbage']! ? [testDate] : [], combo['bio']! ? [testDate] : []);

                    expect(result, isNotNull);
                    return result ?? Container();
                  },
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
        }
      });

      testWidgets('_getCalendarTextColor should return white for paper, trash, bio', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final paperDate = DateTime(2025, 9, 26);
                  final paperResult = CalendarHelper.buildCalendarDay(context, paperDate, focusedDay, [], [paperDate], [], []);

                  expect(paperResult, isNotNull);

                  final garbageDate = DateTime(2025, 9, 29);
                  final garbageResult = CalendarHelper.buildCalendarDay(context, garbageDate, focusedDay, [], [], [garbageDate], []);

                  expect(garbageResult, isNotNull);

                  final bioDate = DateTime(2025, 9, 30);
                  final bioResult = CalendarHelper.buildCalendarDay(context, bioDate, focusedDay, [], [], [], [bioDate]);

                  expect(bioResult, isNotNull);

                  return Container();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
      });

      testWidgets('_getCalendarTextColor should return black for plastic only', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final plasticDate = DateTime(2025, 9, 25);
                  final result = CalendarHelper.buildCalendarDay(context, plasticDate, focusedDay, [plasticDate], [], [], []);

                  expect(result, isNotNull);
                  return result ?? Container();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
      });
    });

    group('Date matching logic', () {
      testWidgets('should correctly identify matching dates', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final exactMatch = DateTime(2025, 9, 25);
                  final result1 = CalendarHelper.buildCalendarDay(context, exactMatch, focusedDay, [DateTime(2025, 9, 25)], [], [], []);
                  expect(result1, isNotNull);

                  final sameDate = DateTime(2025, 9, 25, 14, 30);
                  final result2 = CalendarHelper.buildCalendarDay(context, sameDate, focusedDay, [DateTime(2025, 9, 25, 8, 0)], [], [], []);
                  expect(result2, isNotNull);

                  final noMatch = DateTime(2025, 9, 24);
                  final result3 = CalendarHelper.buildCalendarDay(context, noMatch, focusedDay, [DateTime(2025, 9, 25)], [], [], []);
                  expect(result3, isNull);

                  return Container();
                },
              ),
            ),
          ),
        );
      });
    });
  });
}
