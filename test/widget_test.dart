import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/l10n/l10n.dart';
import 'package:trashifier_app/main.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/pages/home_tab.dart';
import 'package:trashifier_app/pages/settings_page.dart';
import 'package:trashifier_app/services/locale_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';
import 'package:trashifier_app/widgets/swipe_hint.dart';
import 'package:trashifier_app/widgets/swipe_reveal_row.dart';

import 'pages/settings_page_test.dart'
    show debugShown, holdVersionText, setDebugShown;
import 'widgets/day_pickups_sheet_test.dart' show usePhoneScreen;

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('should build without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MyApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should use correct theme configuration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MyApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should integrate with ThemeService correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: themeService, child: const MyApp()),
      );

      expect(
        find.byType(Consumer3<ThemeService, SeasonService?, LocaleService?>),
        findsOneWidget,
      );
      expect(find.byType(MaterialApp), findsOneWidget);

      await themeService.setTheme(ThemeMode.dark);
      await tester.pump();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        equals(ThemeMode.dark),
      );

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should theme the app for the active season', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        SeasonService.overrideKey: 'christmas',
      });
      final seasonService = SeasonService(now: () => DateTime(2026, 3, 10));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeService()),
            ChangeNotifierProvider<SeasonService?>.value(value: seasonService),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();

      expect(seasonService.season, equals(Season.christmas));
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        materialApp.theme!.colorScheme,
        equals(AppTheme.lightTheme(Season.christmas).colorScheme),
      );
      expect(
        materialApp.theme!.colorScheme,
        isNot(equals(AppTheme.lightTheme().colorScheme)),
      );

      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('MyApp clock format', () {
    final today = DateTime.now();
    final inTwoDays = DateTime(today.year, today.month, today.day + 2);

    // The pickup is in two days, so the default reminder (the day before at
    // 19:00) fires tomorrow evening.
    Future<void> pumpApp(WidgetTester tester) async {
      usePhoneScreen(tester);
      addTearDown(() => L10n.use24HourFormat = false);
      SharedPreferences.setMockInitialValues({
        'swipe_hint_seen': true,
        'remove_hint_seen': true,
        'TrashType.plastic': [StorageService.encodeDate(inTwoDays)],
      });
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MyApp(),
        ),
      );
      // Past the splash screen.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('Home shows a 24-hour reminder time when the phone uses it', (
      tester,
    ) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      await pumpApp(tester);

      expect(L10n.use24HourFormat, isTrue);
      expect(find.text('Reminder tomorrow at 19:00'), findsOneWidget);
      expect(find.textContaining('7:00 PM'), findsNothing);
    });

    testWidgets('Home shows a 12-hour reminder time otherwise', (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      await pumpApp(tester);

      expect(L10n.use24HourFormat, isFalse);
      expect(find.text('Reminder tomorrow at 7:00 PM'), findsOneWidget);
      expect(find.textContaining('19:00'), findsNothing);
    });

    testWidgets('a change of the phone setting updates Settings and Home '
        'right away', (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      await pumpApp(tester);

      // MediaQuery picks the new value up when the binding tells its
      // observers about changed settings; the test value alone is silent.
      Future<void> phoneUses24h(bool value) async {
        tester.platformDispatcher.alwaysUse24HourFormatTestValue = value;
        tester.binding.handleTextScaleFactorChanged();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(L10n.use24HourFormat, value);
      }

      // Home.
      expect(find.text('Reminder tomorrow at 7:00 PM'), findsOneWidget);
      await phoneUses24h(true);
      expect(find.text('Reminder tomorrow at 19:00'), findsOneWidget);
      expect(find.textContaining('7:00 PM'), findsNothing);

      // Settings: the time tile and the next reminder preview.
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      expect(
        find.textContaining('at 19:00', findRichText: true),
        findsOneWidget,
      );

      await phoneUses24h(false);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('7:00 PM'), findsOneWidget);
      expect(
        find.textContaining('at 7:00 PM', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('19:00', findRichText: true), findsNothing);

      await phoneUses24h(true);
      expect(find.text('19:00'), findsOneWidget);
      expect(
        find.textContaining('at 19:00', findRichText: true),
        findsOneWidget,
      );

      // Home, underneath, followed along.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text('Reminder tomorrow at 19:00'), findsOneWidget);
    });
  });

  group('HomePage', () {
    testWidgets('the settings button only opens Settings; holding it no '
        'longer toggles debug buttons on Home', (WidgetTester tester) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({'swipe_hint_seen': true});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bug_report, skipOffstage: false), findsNothing);

      // The old 3 s hold: nothing debug shows up on Home.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.settings_rounded)),
      );
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text('Reset hints'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      if (find.byType(SettingsPage).evaluate().isNotEmpty) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      expect(find.text('Reset hints'), findsNothing);
      expect(find.byIcon(Icons.bug_report, skipOffstage: false), findsNothing);

      // A tap opens Settings, with the debug section still hidden.
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      await setDebugShown(tester, false);
    });

    testWidgets('tapping the settings button opens Settings, whose theme '
        'control changes the theme', (WidgetTester tester) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({'swipe_hint_seen': true});
      final themeService = ThemeService();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: themeService,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      // No SeasonService provided.
      expect(find.text('Seasonal themes'), findsNothing);

      final dark = find.text('Dark');
      await tester.ensureVisible(dark);
      await tester.pumpAndSettle();
      await tester.tap(dark);
      await tester.pumpAndSettle();
      expect(themeService.themeMode, equals(ThemeMode.dark));

      // The back arrow scrolls with the (now taller) page, and the lazy list
      // drops it once it is scrolled away, so scroll back up to it.
      final back = find.byIcon(Icons.arrow_back_rounded);
      await tester.scrollUntilVisible(
        back,
        -200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('swiping left opens the calendar and retires the hint', (
      WidgetTester tester,
    ) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      final hint = find.byType(SwipeHint);
      double hintOpacity() => tester
          .widget<AnimatedOpacity>(
            find.ancestor(of: hint, matching: find.byType(AnimatedOpacity)),
          )
          .opacity;
      expect(hintOpacity(), 1);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarTab), findsOneWidget);
      expect(hintOpacity(), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('swipe_hint_seen'), isTrue);
    });

    testWidgets('the hint stays hidden once seen', (WidgetTester tester) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({'swipe_hint_seen': true});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AnimatedOpacity>(
              find.ancestor(
                of: find.byType(SwipeHint),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        0,
      );
    });

    group('Coming up rows', () {
      final today = DateTime.now();
      DateTime inDays(int n) =>
          DateTime(today.year, today.month, today.day + n);

      Future<void> pumpHome(WidgetTester tester) async {
        usePhoneScreen(tester);
        SharedPreferences.setMockInitialValues({
          'swipe_hint_seen': true,
          // Tomorrow is on the hero card; bio follows in the list.
          'TrashType.plastic': [StorageService.encodeDate(inDays(1))],
          'TrashType.bio': [
            StorageService.encodeDate(inDays(3)),
            StorageService.encodeDate(inDays(5)),
          ],
        });
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => ThemeService(),
            child: MaterialApp(
              // Android reports its own touch slop (smaller than Flutter's
              // default), which the PageView picks up; rows must still win
              // rightward drags.
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    gestureSettings: const DeviceGestureSettings(touchSlop: 8),
                  ),
                  child: const HomePage(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // In small steps like a finger, so the smaller touch slop would be
      // crossed first.
      Future<void> fingerDrag(
        WidgetTester tester,
        Finder row,
        double dx,
      ) async {
        await tester.ensureVisible(row);
        final gesture = await tester.startGesture(tester.getCenter(row));
        for (var i = 0; i < 30; i++) {
          await gesture.moveBy(Offset(dx / 30, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
      }

      Future<void> swipeOpen(WidgetTester tester, Finder row) =>
          fingerDrag(tester, row, 150);

      testWidgets('rows open again after closing', (tester) async {
        await pumpHome(tester);
        final row = find.text('Bio waste').first;
        double rowX() => tester.getTopLeft(row).dx;
        final closedX = rowX();

        for (var i = 0; i < 3; i++) {
          await swipeOpen(tester, row);
          expect(rowX(), greaterThan(closedX + 50), reason: 'open #$i');
          await fingerDrag(tester, row, -150);
          expect(rowX(), closedX, reason: 'closed #$i');
        }
        expect(find.byType(CalendarTab), findsNothing);
      });

      testWidgets('swipe right, Remove, then Undo', (tester) async {
        await pumpHome(tester);

        final firstBioRow = find.text('Bio waste').first;
        await tester.ensureVisible(firstBioRow);
        await tester.drag(firstBioRow, const Offset(150, 0));
        await tester.pumpAndSettle();
        // Every row has its Remove button behind it; this is the swiped one.
        await tester.tap(find.text('Remove').first);
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('TrashType.bio'),
          equals([StorageService.encodeDate(inDays(5))]),
        );
        expect(find.textContaining('Removed Bio waste'), findsOneWidget);

        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(
          prefs.getStringList('TrashType.bio'),
          equals([
            StorageService.encodeDate(inDays(3)),
            StorageService.encodeDate(inDays(5)),
          ]),
        );
      });

      testWidgets('a left swipe on a row still opens the calendar', (
        tester,
      ) async {
        await pumpHome(tester);

        final firstBioRow = find.text('Bio waste').first;
        await tester.ensureVisible(firstBioRow);
        await tester.fling(firstBioRow, const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        expect(find.byType(CalendarTab), findsOneWidget);
      });
    });

    group('remove hint', () {
      final today = DateTime.now();
      DateTime inDays(int n) =>
          DateTime(today.year, today.month, today.day + n);

      Map<String, Object> withPickups(Map<String, Object> prefs) => {
        ...prefs,
        // Tomorrow is on the hero card; bio follows in the Coming up list.
        'TrashType.plastic': [StorageService.encodeDate(inDays(1))],
        'TrashType.bio': [
          StorageService.encodeDate(inDays(3)),
          StorageService.encodeDate(inDays(5)),
        ],
      };

      Widget home({bool ready = true, bool disableAnimations = false}) =>
          ChangeNotifierProvider(
            create: (context) => ThemeService(),
            child: MaterialApp(
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: disableAnimations),
                  child: HomePage(ready: ready),
                ),
              ),
            ),
          );

      Finder firstRow() => find.text('Bio waste').first;
      double rowX(WidgetTester tester) => tester.getTopLeft(firstRow()).dx;

      Future<bool?> removeHintSeen() async =>
          (await SharedPreferences.getInstance()).getBool('remove_hint_seen');

      // Waits out the peek delay and the slide out, then reports whether the
      // first row moved, and lets it slide back.
      Future<bool> peeks(WidgetTester tester, double closedX) async {
        await tester.pump(SwipeRevealRow.peekDelay);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        final moved = rowX(tester) > closedX + 40;
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        return moved;
      }

      // The first row starts out behind the floating navigation bar on a
      // phone; the hint waits until it is scrolled clear.
      Future<void> scrollUp(WidgetTester tester) async {
        await tester.drag(
          find
              .descendant(
                of: find.byType(HomeTab),
                matching: find.byType(Scrollable),
              )
              .first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('the first Coming up row peeks once and is remembered', (
        tester,
      ) async {
        usePhoneScreen(tester);
        SharedPreferences.setMockInitialValues(
          withPickups({'swipe_hint_seen': true}),
        );
        await tester.pumpWidget(home());
        await tester.pumpAndSettle();
        final closedX = rowX(tester);

        // Covered by the navigation bar: no peek yet.
        expect(await peeks(tester, closedX), isFalse);
        expect(await removeHintSeen(), isNull);

        await scrollUp(tester);
        final secondRowX = tester.getTopLeft(find.text('Bio waste').at(1)).dx;

        await tester.pump(SwipeRevealRow.peekDelay);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        expect(rowX(tester), greaterThan(closedX + 40));
        // Only the first row.
        expect(tester.getTopLeft(find.text('Bio waste').at(1)).dx, secondRowX);

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(rowX(tester), closedX);
        expect(await removeHintSeen(), isTrue);

        // Not again.
        expect(await peeks(tester, closedX), isFalse);
      });

      testWidgets('waits for the calendar swipe hint to be seen first', (
        tester,
      ) async {
        usePhoneScreen(tester);
        SharedPreferences.setMockInitialValues(withPickups({}));
        await tester.pumpWidget(home());
        await tester.pumpAndSettle();
        await scrollUp(tester);
        final closedX = rowX(tester);

        expect(await peeks(tester, closedX), isFalse);
        expect(await removeHintSeen(), isNull);

        // Swiping to the calendar retires that hint; back on Home it peeks.
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.byType(CalendarTab), findsOneWidget);
        await tester.fling(
          find.byType(PageView).first,
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        await scrollUp(tester);

        expect(await peeks(tester, closedX), isTrue);
        expect(await removeHintSeen(), isTrue);
      });

      testWidgets('waits until the page is ready', (tester) async {
        usePhoneScreen(tester);
        SharedPreferences.setMockInitialValues(
          withPickups({'swipe_hint_seen': true}),
        );
        await tester.pumpWidget(home(ready: false));
        await tester.pumpAndSettle();
        await scrollUp(tester);
        final closedX = rowX(tester);

        expect(await peeks(tester, closedX), isFalse);
        expect(await removeHintSeen(), isNull);

        await tester.pumpWidget(home());
        expect(await peeks(tester, closedX), isTrue);
        expect(await removeHintSeen(), isTrue);
      });

      testWidgets('removing a pickup counts as seen', (tester) async {
        usePhoneScreen(tester);
        SharedPreferences.setMockInitialValues(
          withPickups({'swipe_hint_seen': true}),
        );
        // No peek with reduced motion, so only the removal can mark it.
        await tester.pumpWidget(home(disableAnimations: true));
        await tester.pumpAndSettle();
        await scrollUp(tester);
        final closedX = rowX(tester);
        expect(await peeks(tester, closedX), isFalse);
        expect(await removeHintSeen(), isNull);

        await tester.ensureVisible(firstRow());
        await tester.drag(firstRow(), const Offset(150, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove').first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Removed Bio waste'), findsOneWidget);
        expect(await removeHintSeen(), isTrue);
      });

      testWidgets('Reset hints in the debug panel brings both hints back', (
        tester,
      ) async {
        usePhoneScreen(tester);
        SharedPreferences.setMockInitialValues(
          withPickups({'swipe_hint_seen': true, 'remove_hint_seen': true}),
        );
        await tester.pumpWidget(home());
        await tester.pumpAndSettle();
        double swipeHintOpacity() => tester
            .widget<AnimatedOpacity>(
              find.ancestor(
                of: find.byType(SwipeHint),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity;
        expect(swipeHintOpacity(), 0);

        // The debug panel lives in Settings, behind a 5 s hold on the
        // version text.
        await tester.tap(find.byIcon(Icons.settings_rounded));
        await tester.pumpAndSettle();
        await setDebugShown(tester, false);
        await holdVersionText(tester, SettingsPage.debugHold);
        expect(await debugShown(tester), isTrue);
        final reset = find.text('Reset hints');
        await tester.ensureVisible(reset);
        await tester.pumpAndSettle();
        expect(reset, findsOneWidget);
        await tester.tap(reset);
        await tester.pump();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('swipe_hint_seen'), isFalse);
        expect(prefs.containsKey('remove_hint_seen'), isFalse);
        // The pickups are kept.
        expect(prefs.getStringList('TrashType.bio'), hasLength(2));
        expect(find.text('Hints will show again'), findsOneWidget);
        await tester.pumpAndSettle();

        // Hide the debug section again (it outlives the page), then go back.
        await setDebugShown(tester, false);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsNothing);
        expect(swipeHintOpacity(), 1);

        // The calendar hint goes first; the remove hint follows it.
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(PageView).first,
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        await scrollUp(tester);
        expect(await peeks(tester, rowX(tester)), isTrue);
        expect(prefs.getBool('remove_hint_seen'), isTrue);
        expect(prefs.getBool('swipe_hint_seen'), isTrue);
      });
    });

    testWidgets('tapping a calendar day edits that day\'s pickups', (
      WidgetTester tester,
    ) async {
      usePhoneScreen(tester);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // The 15th is never shown as an adjacent-month day.
      final day15 = find.text('15');
      await tester.ensureVisible(day15);
      await tester.tap(day15);
      await tester.pumpAndSettle();

      final edit = find.text('Edit');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();

      expect(find.byType(DayPickupsSheet), findsOneWidget);

      final inSheet = find.byType(DayPickupsSheet);
      await tester.tap(
        find.descendant(of: inSheet, matching: find.text('Plastic')),
      );
      await tester.pump();
      await tester.tap(
        find.descendant(of: inSheet, matching: find.text('Save 1 bin')),
      );
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('TrashType.plastic'),
        equals([StorageService.encodeDate(DateTime(now.year, now.month, 15))]),
      );
    });
  });
}
