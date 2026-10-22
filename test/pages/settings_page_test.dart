import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/pages/settings_page.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/debug_panel.dart';

import '../widgets/day_pickups_sheet_test.dart' show usePhoneScreen;

/// The version text in the Settings footer: "Trashifier 9.8.7", or just
/// "Trashifier" when the package info can't be read.
final Finder versionText = find.textContaining(RegExp(r'^Trashifier( |$)'));

Finder _settingsScrollable() => find
    .descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(Scrollable),
    )
    .first;

/// Scrolls the Settings page down until [finder] is built (the Bins section
/// at the top pushes later sections out of the lazy list), then into view.
Future<void> revealInSettings(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: _settingsScrollable(),
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the Settings page down to the footer, building the DEBUG section
/// (if shown) right above it.
Future<void> scrollToFooter(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    versionText,
    200,
    scrollable: _settingsScrollable(),
  );
  await tester.pump();
}

/// Holds the Settings version text for [hold] (scrolling it into view first)
/// and lets the page rebuild.
Future<void> holdVersionText(WidgetTester tester, Duration hold) async {
  await scrollToFooter(tester);
  final gesture = await tester.startGesture(tester.getCenter(versionText));
  await tester.pump(hold);
  await gesture.up();
  await tester.pump();
}

/// A segment of the debug panel's "Force a season" control ("Auto" also
/// names a theme choice, so look inside the panel only).
Finder seasonSegment(String label, {bool skipOffstage = true}) =>
    find.descendant(
      of: find.byType(DebugPanel, skipOffstage: skipOffstage),
      matching: find.text(label, skipOffstage: skipOffstage),
    );

/// Whether the hidden DEBUG section is shown on the open Settings page.
Future<bool> debugShown(WidgetTester tester) async {
  await scrollToFooter(tester);
  return find.byType(DebugPanel, skipOffstage: false).evaluate().isNotEmpty;
}

/// Shows or hides the DEBUG section with the five second hold. Its visibility
/// outlives the page, so this only holds when it has to.
Future<void> setDebugShown(WidgetTester tester, bool shown) async {
  if (await debugShown(tester) != shown) {
    await holdVersionText(tester, SettingsPage.debugHold);
  }
  expect(await debugShown(tester), shown);
}

void main() {
  // setOverride refreshes the home screen widgets; unanswered, that platform
  // call would never complete in the fake async zone.
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

  group('SettingsPage', () {
    late ThemeService themeService;
    late ReminderSettingsService reminderService;

    Future<void> pumpSettings(
      WidgetTester tester, {
      Map<TrashType, List<DateTime>>? dates,
      SeasonService? season,
    }) async {
      usePhoneScreen(tester);
      themeService = ThemeService();
      reminderService = ReminderSettingsService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeService),
            ChangeNotifierProvider<ReminderSettingsService?>.value(
              value: reminderService,
            ),
            if (season != null)
              ChangeNotifierProvider<SeasonService?>.value(value: season),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: SettingsPage(
              onImport: (_, _) async {},
              datesByType:
                  dates ??
                  {
                    TrashType.plastic: [inDays(3)],
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await revealInSettings(tester, finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    String preview(DateTime fires, String time, String bin) =>
        'Next reminder: ${DateFormatHelper.formatDayName(fires)}, '
        '${DateFormatHelper.formatDate(fires)} at $time · $bin';

    testWidgets('previews the next reminder with the defaults', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('7:00 PM'), findsOneWidget);
      expect(
        find.text(preview(inDays(2), '7:00 PM', 'Plastic'), findRichText: true),
        findsOneWidget,
      );
      // The version footer sits at the bottom of the (now taller) page.
      await tester.scrollUntilVisible(
        find.text('Trashifier 9.8.7'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Trashifier 9.8.7'), findsOneWidget);
    });

    testWidgets('says when no reminder is planned', (tester) async {
      await pumpSettings(tester, dates: {});

      expect(
        find.text('No reminder planned yet. Add pickups on Home.'),
        findsOneWidget,
      );
    });

    testWidgets('choosing "On pickup day" updates and saves the setting', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tapVisible(tester, find.text('On pickup day'));

      expect(reminderService.settings.daysBefore, 0);
      expect(reminderService.settings.hour, 19);
      expect(
        tester.getSemantics(find.text('On pickup day')),
        containsSemantics(isSelected: true),
      );
      expect(
        find.text(preview(inDays(3), '7:00 PM', 'Plastic'), findRichText: true),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(ReminderSettingsService.daysBeforeKey), 0);

      await tapVisible(tester, find.text('The day before'));
      expect(reminderService.settings.daysBefore, 1);
    });

    testWidgets('picking a time updates hour and minute', (tester) async {
      await pumpSettings(tester);

      await tapVisible(tester, find.bySemanticsLabel('Reminder time, 7:00 PM'));
      expect(find.text('Reminder time'), findsOneWidget);

      // Type it in rather than dragging the dial.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '6');
      await tester.enterText(fields.at(1), '30');
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        reminderService.settings,
        const ReminderSettings(daysBefore: 1, hour: 6, minute: 30),
      );
      expect(find.text('6:30 AM'), findsOneWidget);
      expect(
        find.text(preview(inDays(2), '6:30 AM', 'Plastic'), findRichText: true),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(ReminderSettingsService.hourKey), 6);
      expect(prefs.getInt(ReminderSettingsService.minuteKey), 30);
    });

    testWidgets('cancelling the time picker keeps the time', (tester) async {
      await pumpSettings(tester);

      await tapVisible(tester, find.bySemanticsLabel('Reminder time, 7:00 PM'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(reminderService.settings, ReminderSettings.defaults);
    });

    testWidgets('the theme control sets the ThemeService mode', (tester) async {
      await pumpSettings(tester);
      expect(themeService.themeMode, ThemeMode.system);

      await tapVisible(tester, find.text('Dark'));
      expect(themeService.themeMode, ThemeMode.dark);

      await tapVisible(tester, find.text('Light'));
      expect(themeService.themeMode, ThemeMode.light);

      await tapVisible(tester, find.text('Auto'));
      expect(themeService.themeMode, ThemeMode.system);
    });

    testWidgets('the seasonal switch toggles between auto and normal', (
      tester,
    ) async {
      final season = SeasonService(now: () => DateTime(2026, 10, 16));
      await pumpSettings(tester, season: season);
      expect(season.override, SeasonOverride.auto);

      final toggle = find.byType(Switch);
      await revealInSettings(tester, toggle);
      expect(tester.widget<Switch>(toggle).value, isTrue);

      await tapVisible(tester, toggle);
      expect(season.override, SeasonOverride.normal);
      expect(season.season, Season.none);
      expect(tester.widget<Switch>(toggle).value, isFalse);

      await tapVisible(tester, toggle);
      expect(season.override, SeasonOverride.auto);
      expect(season.season, Season.halloween);
      expect(tester.widget<Switch>(toggle).value, isTrue);
    });

    testWidgets('a season forced from the debug panel counts as on', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        SeasonService.overrideKey: 'christmas',
      });
      final season = SeasonService(now: () => DateTime(2026, 3, 10));
      await pumpSettings(tester, season: season);

      expect(season.override, SeasonOverride.christmas);
      await revealInSettings(tester, find.byType(Switch));
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('the seasonal switch is hidden without a SeasonService', (
      tester,
    ) async {
      await pumpSettings(tester);
      // The theme control sits right above where the switch would be.
      await revealInSettings(tester, find.text('Dark'));

      expect(find.text('Seasonal themes'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
    testWidgets('the seasonal switch has no subtitle', (tester) async {
      await pumpSettings(
        tester,
        season: SeasonService(now: () => DateTime(2026, 3, 10)),
      );

      final label = find.text('Seasonal themes');
      await revealInSettings(tester, label);
      expect(label, findsOneWidget);
      // Only the label sits next to the switch now.
      final row = find.ancestor(of: label, matching: find.byType(Row)).first;
      expect(
        find.descendant(of: row, matching: find.byType(Text)),
        findsOneWidget,
      );
      expect(find.textContaining('Pumpkin Buddy'), findsNothing);
      expect(find.textContaining('Santa Buddy'), findsNothing);
    });

    group('hidden DEBUG section', () {
      testWidgets('a hold shorter than five seconds does nothing', (
        tester,
      ) async {
        await pumpSettings(tester);
        await setDebugShown(tester, false);
        expect(find.text('Reset hints', skipOffstage: false), findsNothing);

        await holdVersionText(tester, const Duration(seconds: 4));
        expect(await debugShown(tester), isFalse);
        // Letting go stopped the count: nothing appears later either.
        await tester.pump(const Duration(seconds: 3));
        expect(await debugShown(tester), isFalse);

        // Two short holds don't add up.
        await holdVersionText(tester, const Duration(seconds: 3));
        await holdVersionText(tester, const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 3));
        expect(await debugShown(tester), isFalse);
      });

      testWidgets('holding five seconds shows it, holding again hides it', (
        tester,
      ) async {
        await pumpSettings(
          tester,
          season: SeasonService(now: () => DateTime(2026, 3, 10)),
        );
        await setDebugShown(tester, false);

        await holdVersionText(tester, SettingsPage.debugHold);
        expect(await debugShown(tester), isTrue);
        // Two sections of rows, in the Settings style.
        for (final title in ['DEBUG · REMINDERS', 'DEBUG · APP']) {
          expect(find.text(title, skipOffstage: false), findsOneWidget);
        }
        for (final (title, subtitle) in [
          ('Reminder plan', 'Planned reminders and permissions'),
          ('Pending reminders', 'What Android has scheduled'),
          ('Test notification', 'Arrives in 10 seconds'),
          ('Reset hints', 'Show the swipe hints on Home again'),
          ('Update widgets', 'Redraw the home screen widgets now'),
        ]) {
          expect(find.text(title, skipOffstage: false), findsOneWidget);
          expect(find.text(subtitle, skipOffstage: false), findsOneWidget);
        }
        expect(
          find.text('Force a season', skipOffstage: false),
          findsOneWidget,
        );
        for (final label in ['Auto', 'Normal', 'Halloween', 'Christmas']) {
          expect(
            seasonSegment(label, skipOffstage: false),
            findsOneWidget,
            reason: label,
          );
        }
        // Reminders first, both above the footer.
        final remindersTop = tester
            .getTopLeft(find.text('DEBUG · REMINDERS', skipOffstage: false))
            .dy;
        final appTop = tester
            .getTopLeft(find.text('DEBUG · APP', skipOffstage: false))
            .dy;
        expect(remindersTop, lessThan(appTop));
        expect(appTop, lessThan(tester.getTopLeft(versionText).dy));

        await holdVersionText(tester, SettingsPage.debugHold);
        expect(await debugShown(tester), isFalse);
        expect(find.text('Reset hints', skipOffstage: false), findsNothing);
        expect(find.text('DEBUG · APP', skipOffstage: false), findsNothing);
        expect(find.text('Force a season', skipOffstage: false), findsNothing);
      });

      testWidgets('leaves out the season control without a SeasonService', (
        tester,
      ) async {
        await pumpSettings(tester);
        await setDebugShown(tester, true);
        expect(
          find.text('Update widgets', skipOffstage: false),
          findsOneWidget,
        );
        expect(find.text('Force a season', skipOffstage: false), findsNothing);
        expect(seasonSegment('Christmas', skipOffstage: false), findsNothing);
        await setDebugShown(tester, false);
      });

      testWidgets('a very long hold toggles only once', (tester) async {
        await pumpSettings(tester);
        await setDebugShown(tester, false);

        await holdVersionText(tester, const Duration(seconds: 12));
        expect(await debugShown(tester), isTrue);

        await setDebugShown(tester, false);
      });

      testWidgets('stays shown when Settings is opened again', (tester) async {
        await pumpSettings(tester);
        await setDebugShown(tester, true);

        // Leave Settings (its state is disposed) and open it afresh.
        await tester.pumpWidget(const SizedBox());
        await pumpSettings(tester);
        expect(await debugShown(tester), isTrue);

        await setDebugShown(tester, false);
        await tester.pumpWidget(const SizedBox());
        await pumpSettings(tester);
        expect(await debugShown(tester), isFalse);
      });
    });
  });
}
