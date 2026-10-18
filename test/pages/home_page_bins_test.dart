import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/pages/home_tab.dart';
import 'package:trashifier_app/pages/settings_page.dart';
import 'package:trashifier_app/services/bin_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/bin_editor_sheet.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';
import 'package:trashifier_app/widgets/import_dialog.dart';

import '../widgets/day_pickups_sheet_test.dart' show usePhoneScreen;
import 'settings_page_test.dart' show revealInSettings;

void main() {
  const widgetChannel = MethodChannel('com.trashifier_app/widget');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
  });

  const glass = TrashType(
    id: 'cglass',
    slot: 4,
    position: 4,
    customName: 'Glass',
    color: 5,
    icon: 6,
  );

  final today = DateTime.now();
  DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);
  String day(int n) => StorageService.encodeDate(inDays(n));

  group('HomePage with custom bins', () {
    late BinService bins;

    /// Pumps HomePage with the built-ins (plastic hidden) and Glass, plus
    /// [prefs] (dates).
    Future<void> pumpHome(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
      bool hidePlastic = true,
    }) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({
        'swipe_hint_seen': true,
        'remove_hint_seen': true,
        BinService.binsKey: BinService.encode([
          if (hidePlastic)
            TrashType.plastic.copyWith(hidden: true)
          else
            TrashType.plastic,
          TrashType.paper,
          TrashType.trash,
          TrashType.bio,
          glass,
        ]),
        ...prefs,
      });
      bins = BinService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeService()),
            ChangeNotifierProvider<BinService?>.value(value: bins),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(bins.find(glass), isNotNull);
    }

    Map<TrashType, List<DateTime>> homeDates(WidgetTester tester) =>
        tester.widget<HomeTab>(find.byType(HomeTab)).datesByType;

    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    }

    testWidgets('Home shows the custom bin and leaves hidden bins out', (
      tester,
    ) async {
      await pumpHome(
        tester,
        prefs: {
          'bin.cglass': [day(3)],
          // Hidden: sooner, but must not show or remind.
          'TrashType.plastic': [day(2)],
        },
      );

      final dates = homeDates(tester);
      expect(dates.keys.map((t) => t.id), ['paper', 'trash', 'bio', 'cglass']);
      expect(dates[glass], [inDays(3)]);
      expect(find.textContaining('Glass'), findsWidgets);
      expect(find.text('Plastic'), findsNothing);

      // The calendar and its filters offer the visible bins only.
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarTab>(find.byType(CalendarTab));
      expect(calendar.datesByType.keys, isNot(contains(TrashType.plastic)));
      expect(calendar.datesByType.keys, contains(glass));
      expect(
        find.descendant(
          of: find.byType(CalendarTab),
          matching: find.text('Glass'),
        ),
        findsWidgets,
      );
    });

    testWidgets('the next reminder is for the custom bin, not a hidden one', (
      tester,
    ) async {
      await pumpHome(
        tester,
        prefs: {
          'bin.cglass': [day(3)],
          'TrashType.plastic': [day(2)],
        },
      );
      await openSettings(tester);

      final next = find.textContaining('Next reminder', findRichText: true);
      await revealInSettings(tester, next);
      expect(
        find.textContaining('· Glass', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('· Plastic', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('showing a hidden bin brings back its dates', (tester) async {
      await pumpHome(
        tester,
        prefs: {
          'TrashType.plastic': [day(2)],
        },
      );
      expect(homeDates(tester).containsKey(TrashType.plastic), isFalse);

      await tester.runAsync(() => bins.setHidden(TrashType.plastic, false));
      await tester.pumpAndSettle();

      expect(homeDates(tester)[TrashType.plastic], [inDays(2)]);
      expect(homeDates(tester).keys.first, TrashType.plastic);
    });

    testWidgets('a custom bin can get dates from the day sheet', (
      tester,
    ) async {
      await pumpHome(tester, hidePlastic: false);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      final day15 = find.text('15');
      await tester.ensureVisible(day15);
      await tester.tap(day15);
      await tester.pumpAndSettle();
      final edit = find.text('Edit');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();

      final sheet = find.byType(DayPickupsSheet);
      expect(
        tester
            .widgetList<BinToggleTile>(find.byType(BinToggleTile))
            .map((tile) => tile.type.id),
        ['plastic', 'paper', 'trash', 'bio', 'cglass'],
      );
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Glass')),
      );
      await tester.pump();
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Save 1 bin')),
      );
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('bin.cglass'), [
        StorageService.encodeDate(DateTime(today.year, today.month, 15)),
      ]);
      expect(prefs.getStringList('TrashType.plastic'), isNull);
    });

    testWidgets('the day sheet leaves hidden bins out and keeps their dates', (
      tester,
    ) async {
      final day15 = DateTime(today.year, today.month, 15);
      await pumpHome(
        tester,
        prefs: {
          'TrashType.plastic': [StorageService.encodeDate(day15)],
        },
      );

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      final cell = find.text('15');
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      final edit = find.text('Edit');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();

      final sheet = find.byType(DayPickupsSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Plastic')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Paper')),
      );
      await tester.pump();
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Save 1 bin')),
      );
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('TrashType.paper'), [
        StorageService.encodeDate(day15),
      ]);
      expect(prefs.getStringList('TrashType.plastic'), [
        StorageService.encodeDate(day15),
      ]);
    });

    testWidgets('deleting a custom bin in Settings deletes its dates', (
      tester,
    ) async {
      await pumpHome(
        tester,
        prefs: {
          'bin.cglass': [day(3), day(10)],
        },
      );
      await openSettings(tester);

      await tester.tap(find.text('Glass'));
      await tester.pumpAndSettle();
      final delete = find.descendant(
        of: find.byType(BinEditorSheet),
        matching: find.text('Delete bin'),
      );
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.text('The bin and its 2 pickup dates are deleted.'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(bins.find(glass), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('bin.cglass'), isNull);
      expect(find.text('Glass deleted'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(homeDates(tester).containsKey(glass), isFalse);
    });

    testWidgets('importing a schedule creates its missing custom bins', (
      tester,
    ) async {
      await pumpHome(tester, hidePlastic: false);
      await openSettings(tester);

      final incoming = ScheduleCodec.decodeLink(
        ScheduleCodec.encodeLink({
          TrashType.paper: [inDays(4)],
          // Same name as the user's bin: its dates go there.
          glass.copyWith(customName: 'GLASS'): [inDays(5)],
          const TrashType(
            id: 'cmetal',
            slot: 5,
            position: 5,
            customName: 'Metal',
            color: 9,
            icon: 10,
          ): [
            inDays(6),
            inDays(13),
          ],
        }, from: today),
      );
      final page = tester.widget<SettingsPage>(find.byType(SettingsPage));
      // Not awaited: after saving, the import re-arms reminders through a
      // static queue that an earlier test's fake async zone can leave
      // stuck, so only the saved state is checked.
      unawaited(page.onImport(incoming, ImportSource.link));
      await tester.pumpAndSettle();

      expect(find.byType(ImportDialog), findsOneWidget);
      expect(find.text('Adds 1 new bin: Metal.'), findsOneWidget);
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(bins.all.length, 6);
      final metal = bins.all.last;
      expect(metal.customName, 'Metal');
      expect(metal.color, 9);
      expect(metal.icon, 10);
      expect(metal.isBuiltIn, isFalse);
      expect(metal.id, isNot('cq2'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(metal.storageKey), [day(6), day(13)]);
      expect(prefs.getStringList('bin.cglass'), [day(5)]);
      expect(prefs.getStringList('TrashType.paper'), [day(4)]);
    });
  });
}
