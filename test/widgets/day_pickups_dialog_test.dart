import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/day_pickups_dialog.dart';

void main() {
  group('DayPickupsDialog', () {
    // Opens the dialog and returns a getter for its result once closed.
    Future<Set<TrashType>? Function()> openDialog(
      WidgetTester tester,
      Set<TrashType> initialTypes,
    ) async {
      Set<TrashType>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await DayPickupsDialog.show(
                  context,
                  day: DateTime(2025, 10, 3),
                  initialTypes: initialTypes,
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

    bool isChecked(WidgetTester tester, String label) {
      return tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, label),
              )
              .value ??
          false;
    }

    testWidgets('shows the day and preselects existing pickups', (
      tester,
    ) async {
      await openDialog(tester, {TrashType.paper, TrashType.bio});

      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Oct 3'), findsOneWidget);
      expect(isChecked(tester, 'Paper'), isTrue);
      expect(isChecked(tester, 'Bio waste'), isTrue);
      expect(isChecked(tester, 'Plastic'), isFalse);
      expect(isChecked(tester, 'General trash'), isFalse);
    });

    testWidgets('save returns the edited selection', (tester) async {
      final result = await openDialog(tester, {TrashType.paper});

      await tester.tap(find.text('Plastic'));
      await tester.tap(find.text('Paper'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result(), equals({TrashType.plastic}));
    });

    testWidgets('cancel returns null', (tester) async {
      final result = await openDialog(tester, {TrashType.paper});

      await tester.tap(find.text('Plastic'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result(), isNull);
    });
  });
}
