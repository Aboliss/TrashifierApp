import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';

/// The sheet is laid out for phones; the default 800x600 test view cuts off
/// its buttons.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('DayPickupsSheet', () {
    // Opens the sheet and returns a getter for its result once closed.
    Future<Set<TrashType>? Function()> openSheet(
      WidgetTester tester,
      Set<TrashType> initialTypes,
    ) async {
      Set<TrashType>? result;
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await DayPickupsSheet.show(
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

    bool isSelected(WidgetTester tester, TrashType type) {
      return tester
          .widgetList<BinToggleTile>(find.byType(BinToggleTile))
          .firstWhere((tile) => tile.type == type)
          .selected;
    }

    testWidgets('shows the day and preselects existing pickups', (
      tester,
    ) async {
      await openSheet(tester, {TrashType.paper, TrashType.bio});

      expect(find.text('Friday, Oct 3'), findsOneWidget);
      expect(isSelected(tester, TrashType.paper), isTrue);
      expect(isSelected(tester, TrashType.bio), isTrue);
      expect(isSelected(tester, TrashType.plastic), isFalse);
      expect(isSelected(tester, TrashType.trash), isFalse);
      expect(find.text('Save 2 bins'), findsOneWidget);
    });

    testWidgets('save returns the edited selection', (tester) async {
      final result = await openSheet(tester, {TrashType.paper});

      await tester.tap(find.text('Plastic'));
      await tester.tap(find.text('Paper'));
      await tester.pump();
      await tester.tap(find.text('Save 1 bin'));
      await tester.pumpAndSettle();

      expect(result(), equals({TrashType.plastic}));
    });

    testWidgets('deselecting everything offers to clear the day', (
      tester,
    ) async {
      final result = await openSheet(tester, {TrashType.paper});

      await tester.tap(find.text('Paper'));
      await tester.pump();
      await tester.tap(find.text('Clear day'));
      await tester.pumpAndSettle();

      expect(result(), equals(<TrashType>{}));
    });

    testWidgets('cancel returns null', (tester) async {
      final result = await openSheet(tester, {TrashType.paper});

      await tester.tap(find.text('Plastic'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result(), isNull);
    });
  });
}
