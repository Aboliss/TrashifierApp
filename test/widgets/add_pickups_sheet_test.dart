import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/add_pickups_sheet.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';

import 'day_pickups_sheet_test.dart' show usePhoneScreen;

void main() {
  group('AddPickupsSheet', () {
    const glass = TrashType(
      id: 'cglass',
      slot: 4,
      position: 0,
      customName: 'Glass',
      color: 5,
      icon: 6,
    );

    Future<TrashType? Function()> openSheet(
      WidgetTester tester,
      Map<TrashType, int> upcomingCounts,
    ) async {
      TrashType? result;
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await AddPickupsSheet.show(
                  context,
                  upcomingCounts: upcomingCounts,
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

    testWidgets('shows a tile per given bin, custom ones included', (
      tester,
    ) async {
      await openSheet(tester, {
        glass: 2,
        TrashType.plastic: 0,
        TrashType.bio: 1,
      });

      expect(
        tester
            .widgetList<BinToggleTile>(find.byType(BinToggleTile))
            .map((tile) => tile.type),
        [glass, TrashType.plastic, TrashType.bio],
      );
      expect(find.text('Glass'), findsOneWidget);
      // Hidden bins aren't passed in, so they don't show.
      expect(find.text('Paper'), findsNothing);
    });

    testWidgets('tapping a custom bin returns it', (tester) async {
      final result = await openSheet(tester, {
        for (final type in TrashType.builtIns) type: 0,
        glass: 0,
      });

      await tester.tap(find.text('Glass'));
      await tester.pumpAndSettle();

      expect(result(), glass);
      expect(result()!.customName, 'Glass');
    });
  });
}
