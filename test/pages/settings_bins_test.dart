import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/pages/settings_page.dart';
import 'package:trashifier_app/services/bin_service.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/bin_editor_sheet.dart';

import '../widgets/day_pickups_sheet_test.dart' show usePhoneScreen;
import 'settings_page_test.dart' show revealInSettings;

void main() {
  const widgetChannel = MethodChannel('com.trashifier_app/widget');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Trashifier',
      packageName: 'com.trashifier_app',
      version: '9.8.7',
      buildNumber: '1',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
  });

  final today = DateTime.now();
  DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);

  const glass = TrashType(
    id: 'cglass',
    slot: 4,
    position: 4,
    customName: 'Glass',
    color: 5,
    icon: 6,
  );

  group('Settings › Bins', () {
    late BinService bins;
    late List<TrashType> deleted;

    Future<void> pumpSettings(
      WidgetTester tester, {
      Map<TrashType, List<DateTime>> dates = const {},
      Future<void> Function(BinService)? setUpBins,
      bool withGlass = false,
    }) async {
      usePhoneScreen(tester);
      if (withGlass) {
        SharedPreferences.setMockInitialValues({
          BinService.binsKey: BinService.encode([...TrashType.builtIns, glass]),
        });
      }
      deleted = [];
      bins = BinService();
      await tester.runAsync(() => bins.ready);
      if (setUpBins != null) await tester.runAsync(() => setUpBins(bins));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeService()),
            ChangeNotifierProvider<ReminderSettingsService?>(
              create: (_) => ReminderSettingsService(),
            ),
            ChangeNotifierProvider<BinService?>.value(value: bins),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: SettingsPage(
              onImport: (_, _) async {},
              datesByType: dates,
              onDeleteBin: (bin) async {
                deleted.add(bin);
                await bins.remove(bin);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder hideButton(String name) => find.byTooltip('Hide $name');
    Finder showButton(String name) => find.byTooltip('Show $name');

    IconButton iconButton(WidgetTester tester, Finder tooltip) =>
        tester.widget<IconButton>(
          find.ancestor(of: tooltip, matching: find.byType(IconButton)),
        );

    Future<void> openEditor(WidgetTester tester, String name) async {
      final row = find.text(name);
      await revealInSettings(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(BinEditorSheet), findsOneWidget);
    }

    Finder inEditor(Finder finder) =>
        find.descendant(of: find.byType(BinEditorSheet), matching: finder);

    testWidgets('lists every bin in order with an add row and a hint', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.text('BINS'), findsOneWidget);
      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(y('Plastic'), lessThan(y('Paper')));
      expect(y('Paper'), lessThan(y('General trash')));
      expect(y('General trash'), lessThan(y('Bio waste')));
      expect(find.text('Add a bin'), findsOneWidget);
      expect(find.textContaining('Drag to reorder.'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(4));
    });

    testWidgets('shows the upcoming count of each bin', (tester) async {
      await pumpSettings(
        tester,
        dates: {
          TrashType.paper: [inDays(2), inDays(9), inDays(-3)],
        },
      );
      expect(find.text('2 upcoming'), findsOneWidget);
      expect(find.text('Nothing planned'), findsNWidgets(3));
    });

    testWidgets('adding a bin through the editor shows it in the list', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Add a bin'));
      await tester.pumpAndSettle();
      expect(find.byType(BinEditorSheet), findsOneWidget);
      expect(inEditor(find.text('Delete bin')), findsNothing);

      // No name, no bin.
      final addButton = inEditor(find.widgetWithText(PillButton, 'Add bin'));
      expect(tester.widget<PillButton>(addButton).onPressed, isNull);

      await tester.enterText(inEditor(find.byType(TextField)), '  Glass ');
      await tester.pump();
      expect(tester.widget<PillButton>(addButton).onPressed, isNotNull);
      // Pick the last color and icon.
      await tester.tap(inEditor(find.bySemanticsLabel('Color 12')));
      await tester.pump();
      final lastIcon = inEditor(find.bySemanticsLabel('Icon 16'));
      await tester.ensureVisible(lastIcon);
      await tester.pumpAndSettle();
      await tester.tap(lastIcon);
      await tester.pump();

      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.byType(BinEditorSheet), findsNothing);
      expect(bins.all.length, 5);
      final glass = bins.all.last;
      expect(glass.customName, 'Glass');
      expect(glass.isBuiltIn, isFalse);
      expect(glass.slot, 4);
      expect(glass.color, 11);
      expect(glass.icon, 15);
      expect(find.text('Glass'), findsOneWidget);
      expect(hideButton('Glass'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(5));
    });

    testWidgets('cancelling the editor adds nothing', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Add a bin'));
      await tester.pumpAndSettle();
      await tester.enterText(inEditor(find.byType(TextField)), 'Glass');
      await tester.tap(inEditor(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(bins.all, equals(TrashType.builtIns));
    });

    testWidgets('the eye button hides and shows a bin', (tester) async {
      await pumpSettings(tester);

      await tester.tap(hideButton('Paper'));
      await tester.pumpAndSettle();
      expect(bins.find(TrashType.paper)!.hidden, isTrue);
      expect(bins.visible, isNot(contains(TrashType.paper)));
      expect(find.text('Hidden'), findsOneWidget);
      expect(showButton('Paper'), findsOneWidget);
      // Still listed, so it can be shown again.
      expect(find.text('Paper'), findsOneWidget);

      await tester.tap(showButton('Paper'));
      await tester.pumpAndSettle();
      expect(bins.find(TrashType.paper)!.hidden, isFalse);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('the last visible bin cannot be hidden', (tester) async {
      await pumpSettings(
        tester,
        setUpBins: (bins) async {
          await bins.setHidden(TrashType.plastic, true);
          await bins.setHidden(TrashType.paper, true);
          await bins.setHidden(TrashType.trash, true);
        },
      );

      expect(bins.visible, [TrashType.bio]);
      expect(iconButton(tester, hideButton('Bio waste')).onPressed, isNull);
      // Hidden bins can still be shown.
      expect(iconButton(tester, showButton('Paper')).onPressed, isNotNull);

      // Showing another bin makes Bio hideable again.
      await tester.tap(showButton('Paper'));
      await tester.pumpAndSettle();
      expect(iconButton(tester, hideButton('Bio waste')).onPressed, isNotNull);
    });

    testWidgets('built-in bins have no Delete; a rename sticks', (
      tester,
    ) async {
      await pumpSettings(tester);

      await openEditor(tester, 'Paper');
      expect(inEditor(find.text('Delete bin')), findsNothing);
      expect(inEditor(find.text('Save')), findsOneWidget);

      await tester.enterText(inEditor(find.byType(TextField)), 'Cardboard');
      await tester.pump();
      final save = inEditor(find.widgetWithText(PillButton, 'Save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(bins.find(TrashType.paper)!.customName, 'Cardboard');
      expect(find.text('Cardboard'), findsOneWidget);
      expect(bins.all.length, 4);
    });

    testWidgets('a built-in saved with an empty name gets its own back', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        setUpBins: (bins) =>
            bins.update(TrashType.paper.copyWith(customName: 'Cardboard')),
      );

      await openEditor(tester, 'Cardboard');
      await tester.enterText(inEditor(find.byType(TextField)), '');
      await tester.pump();
      final save = inEditor(find.widgetWithText(PillButton, 'Save'));
      expect(tester.widget<PillButton>(save).onPressed, isNotNull);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(bins.find(TrashType.paper)!.customName, isNull);
      expect(find.text('Paper'), findsOneWidget);
    });

    group('deleting a custom bin', () {
      Future<void> tapDeleteInEditor(WidgetTester tester) async {
        await openEditor(tester, 'Glass');
        final delete = inEditor(find.text('Delete bin'));
        expect(delete, findsOneWidget);
        await tester.ensureVisible(delete);
        await tester.pumpAndSettle();
        await tester.tap(delete);
        await tester.pumpAndSettle();
      }

      testWidgets('asks first, then calls onDeleteBin', (tester) async {
        await pumpSettings(
          tester,
          withGlass: true,
          dates: {
            glass: [inDays(1), inDays(8), inDays(-6)],
          },
        );
        expect(bins.find(glass), isNotNull);

        await tapDeleteInEditor(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete Glass?'), findsOneWidget);
        expect(
          find.text('The bin and its 3 pickup dates are deleted.'),
          findsOneWidget,
        );
        expect(deleted, isEmpty);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await tester.pumpAndSettle();

        expect(deleted, [glass]);
        expect(bins.find(glass), isNull);
        expect(find.text('Glass deleted'), findsOneWidget);
        expect(find.text('Glass'), findsNothing);
      });

      testWidgets('cancelling the confirmation keeps the bin', (tester) async {
        await pumpSettings(tester, withGlass: true);

        await tapDeleteInEditor(tester);
        expect(
          find.text('The bin is removed.'),
          findsOneWidget,
          reason: 'no dates',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Cancel'),
          ),
        );
        await tester.pumpAndSettle();

        expect(deleted, isEmpty);
        expect(bins.find(glass), isNotNull);
        expect(find.text('Glass'), findsOneWidget);
      });
    });

    testWidgets('ten bins replace the add row with a note', (tester) async {
      await pumpSettings(
        tester,
        setUpBins: (bins) async {
          for (var i = 1; i <= 6; i++) {
            await bins.add(name: 'Bin $i', color: 4, icon: 4);
          }
        },
      );
      expect(bins.isFull, isTrue);

      await revealInSettings(
        tester,
        find.text('That’s 10 bins, the most there can be.'),
      );
      expect(find.text('Add a bin'), findsNothing);
    });
  });
}
