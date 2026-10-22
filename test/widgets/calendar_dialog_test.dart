import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';

import 'day_pickups_sheet_test.dart' show usePhoneScreen;

/// Centers of the shown month's first outside cells: the one just before
/// day 1 and the one just after the last day, or null when the month starts
/// on a Monday or ends on a Sunday (the grids start on Monday).
({Offset? leading, Offset? trailing}) outsideCellCenters(
  WidgetTester tester,
  DateTime month,
) {
  Offset center(int d) => tester.getCenter(find.text('$d').hitTestable());
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  double? width;
  for (var d = 1; d < 28 && width == null; d++) {
    final a = center(d);
    final b = center(d + 1);
    if ((a.dy - b.dy).abs() < 1) width = b.dx - a.dx;
  }
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month, daysInMonth);
  return (
    leading: first.weekday == DateTime.monday
        ? null
        : center(1) - Offset(width!, 0),
    trailing: last.weekday == DateTime.sunday
        ? null
        : center(daysInMonth) + Offset(width!, 0),
  );
}

void main() {
  group('CalendarDialog', () {
    // Today's month, so its days are on the first page.
    final now = DateTime.now();
    DateTime day(int d) => DateTime(now.year, now.month, d);

    Future<Set<DateTime>? Function()> openDialog(WidgetTester tester) async {
      Set<DateTime>? result;
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await CalendarDialog.show(
                  context,
                  type: TrashType.plastic,
                  datesByType: {
                    TrashType.plastic: [day(10)],
                  },
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => result;
    }

    testWidgets('counts added and removed days as you tap', (tester) async {
      final result = await openDialog(tester);

      expect(find.text('Tap days to add or remove'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.text('12'));
      await tester.tap(find.text('14'));
      await tester.pump();
      expect(find.text('+2 new'), findsOneWidget);
      expect(find.text('Add 2 days'), findsOneWidget);

      await tester.tap(find.text('10'));
      await tester.pump();
      expect(find.text('+2 new · 1 removed'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(result(), equals({day(12), day(14)}));
    });

    testWidgets('outside days of the shown month cannot be toggled', (
      tester,
    ) async {
      final result = await openDialog(tester);

      // Find a month with outside cells (the current one almost always).
      var month = DateTime(now.year, now.month);
      var cells = outsideCellCenters(tester, month);
      for (
        var i = 0;
        i < 2 && cells.leading == null && cells.trailing == null;
        i++
      ) {
        await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        await tester.pumpAndSettle();
        month = DateTime(month.year, month.month + 1);
        cells = outsideCellCenters(tester, month);
      }
      expect([cells.leading, cells.trailing].nonNulls, isNotEmpty);

      for (final position in [cells.leading, cells.trailing].nonNulls) {
        await tester.tapAt(position);
        await tester.pump();
        expect(find.text('Tap days to add or remove'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.textContaining('new'), findsNothing);
        expect(find.textContaining('removed'), findsNothing);
      }

      // Days of the month still toggle.
      await tester.tap(find.text('20').hitTestable());
      await tester.pump();
      expect(find.text('Add 1 day'), findsOneWidget);

      await tester.tap(find.text('Add 1 day'));
      await tester.pumpAndSettle();
      expect(result(), {day(10), DateTime(month.year, month.month, 20)});
    });

    test('labels', () {
      expect(CalendarDialog.saveLabel(1, 0), 'Add 1 day');
      expect(CalendarDialog.saveLabel(0, 3), 'Remove 3 days');
      expect(CalendarDialog.changeSummary(0, 1), '1 removed');
    });
  });
}
