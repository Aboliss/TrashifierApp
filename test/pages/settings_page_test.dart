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

import '../widgets/day_pickups_sheet_test.dart' show usePhoneScreen;

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
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(toggle);
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
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('the seasonal switch is hidden without a SeasonService', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.text('Seasonal themes'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
