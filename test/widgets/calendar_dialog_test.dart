import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';

import 'day_pickups_sheet_test.dart' show usePhoneScreen;

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

    test('labels', () {
      expect(CalendarDialog.saveLabel(1, 0), 'Add 1 day');
      expect(CalendarDialog.saveLabel(0, 3), 'Remove 3 days');
      expect(CalendarDialog.changeSummary(0, 1), '1 removed');
    });
  });
}
