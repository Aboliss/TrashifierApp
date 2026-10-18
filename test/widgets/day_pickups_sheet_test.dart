import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
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
      Set<TrashType> initialTypes, {
      List<TrashType>? bins,
    }) async {
      Set<TrashType>? result;
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = bins == null
                    ? await DayPickupsSheet.show(
                        context,
                        day: DateTime(2025, 10, 3),
                        initialTypes: initialTypes,
                      )
                    : await DayPickupsSheet.show(
                        context,
                        day: DateTime(2025, 10, 3),
                        initialTypes: initialTypes,
                        bins: bins,
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

    testWidgets('describes the reminders the evening before by default', (
      tester,
    ) async {
      await openSheet(tester, {TrashType.paper});
      expect(
        find.text('One reminder the day before at 7:00 PM.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Plastic'));
      await tester.pump();
      expect(
        find.text('2 reminders the day before at 7:00 PM, one per bin.'),
        findsOneWidget,
      );
    });

    testWidgets('describes the chosen reminder day and time', (tester) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({});
      final service = ReminderSettingsService();
      await service.update(
        const ReminderSettings(daysBefore: 0, hour: 6, minute: 30),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ReminderSettingsService?>.value(
          value: service,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => DayPickupsSheet.show(
                  context,
                  day: DateTime(2025, 10, 3),
                  initialTypes: {TrashType.bio},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('One reminder on pickup day at 6:30 AM.'),
        findsOneWidget,
      );
    });

    group('with custom bins', () {
      const glass = TrashType(
        id: 'cglass',
        slot: 4,
        position: 1,
        customName: 'Glass',
        color: 5,
        icon: 6,
      );

      testWidgets('offers the built-ins by default', (tester) async {
        await openSheet(tester, {});
        expect(
          tester
              .widgetList<BinToggleTile>(find.byType(BinToggleTile))
              .map((tile) => tile.type),
          TrashType.builtIns,
        );
      });

      testWidgets('offers exactly the given bins, in their order', (
        tester,
      ) async {
        await openSheet(
          tester,
          {glass},
          bins: [TrashType.bio, glass, TrashType.plastic],
        );
        expect(
          tester
              .widgetList<BinToggleTile>(find.byType(BinToggleTile))
              .map((tile) => tile.type),
          [TrashType.bio, glass, TrashType.plastic],
        );
        expect(find.text('Glass'), findsOneWidget);
        // Not offered: hidden or left out bins.
        expect(find.text('Paper'), findsNothing);
        expect(isSelected(tester, glass), isTrue);
        expect(isSelected(tester, TrashType.bio), isFalse);
      });

      testWidgets('a custom bin can be picked and saved', (tester) async {
        final result = await openSheet(
          tester,
          {},
          bins: [...TrashType.builtIns, glass],
        );
        await tester.tap(find.text('Glass'));
        await tester.tap(find.text('Paper'));
        await tester.pump();
        await tester.tap(find.text('Save 2 bins'));
        await tester.pumpAndSettle();

        expect(result(), equals({glass, TrashType.paper}));
      });
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
