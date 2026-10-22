import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/pages/settings_page.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/floating_nav_bar.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

import '../widgets/day_pickups_sheet_test.dart' show usePhoneScreen;
import 'settings_page_test.dart'
    show debugShown, holdVersionText, seasonSegment, setDebugShown;

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

void main() {
  // setOverride refreshes the home screen widgets; unanswered, that platform
  // call would never complete in the fake async zone.
  const widgetChannel = MethodChannel('com.trashifier_app/widget');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
  });

  /// Pumps HomePage themed for the active season like MyApp does, with the
  /// clock in March (no season on auto).
  Future<SeasonService> pumpHome(WidgetTester tester) async {
    usePhoneScreen(tester);
    SharedPreferences.setMockInitialValues({'swipe_hint_seen': true});
    final service = SeasonService(
      now: () => DateTime(2026, 3, 10),
      random: Random(1),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeService()),
          ChangeNotifierProvider<SeasonService?>.value(value: service),
        ],
        child: Consumer<SeasonService?>(
          builder: (context, season, child) => MaterialApp(
            theme: AppTheme.lightTheme(season?.season ?? Season.none),
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(service.season, Season.none);
    return service;
  }

  /// Switches the season without awaiting the save (awaiting it inside
  /// testWidgets can stall); pumps instead. Not pumpAndSettle: snow falls
  /// forever.
  Future<void> forceSeason(
    WidgetTester tester,
    SeasonService service,
    SeasonOverride override,
  ) async {
    service.setOverride(override);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(service.override, override);
  }

  /// "October 2026" from the calendar's header.
  String shownMonth(WidgetTester tester) {
    final header = find.descendant(
      of: find.byType(CalendarTab),
      matching: find.textContaining(
        RegExp('^(${_monthNames.join('|')}) \\d{4}\$'),
        findRichText: true,
      ),
    );
    expect(header, findsOneWidget);
    return tester.widget<RichText>(header).text.toPlainText();
  }

  int navIndex(WidgetTester tester) =>
      tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).index;

  // The outer PageView comes first; the calendar has its own inside.
  double? tabPage(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView).first).controller!.page;

  group('HomePage season switch', () {
    testWidgets('switching into and out of Christmas keeps the Calendar tab '
        'and its state', (tester) async {
      final service = await pumpHome(tester);

      await tester.tap(find.text('Calendar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CalendarTab), findsOneWidget);
      expect(navIndex(tester), 1);

      final calendarState = tester.state(find.byType(CalendarTab));
      final startMonth = shownMonth(tester);
      final nextMonth = find.descendant(
        of: find.byType(CalendarTab),
        matching: find.byIcon(Icons.chevron_right_rounded),
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(nextMonth);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      final movedMonth = shownMonth(tester);
      expect(movedMonth, isNot(startMonth));

      void expectStillOnCalendar(String reason) {
        expect(find.byType(CalendarTab), findsOneWidget, reason: reason);
        expect(navIndex(tester), 1, reason: reason);
        expect(tabPage(tester), 1, reason: reason);
        expect(
          tester.state(find.byType(CalendarTab)),
          same(calendarState),
          reason: reason,
        );
        expect(shownMonth(tester), movedMonth, reason: reason);
      }

      await forceSeason(tester, service, SeasonOverride.christmas);
      expect(service.season, Season.christmas);
      expect(find.byType(SnowLayer), findsOneWidget);
      expect(find.byType(LightsString), findsOneWidget);
      expectStillOnCalendar('into Christmas');

      await forceSeason(tester, service, SeasonOverride.normal);
      expect(service.season, Season.none);
      expect(find.byType(SnowLayer), findsNothing);
      expect(find.byType(LightsString), findsNothing);
      expectStillOnCalendar('out of Christmas');

      // Halloween doesn't touch the backdrop, but check it all the same.
      await forceSeason(tester, service, SeasonOverride.halloween);
      expectStillOnCalendar('into Halloween');
      await forceSeason(tester, service, SeasonOverride.christmas);
      expectStillOnCalendar('Halloween to Christmas');
    });

    testWidgets('a swipe to the calendar survives the switch too', (
      tester,
    ) async {
      final service = await pumpHome(tester);

      await tester.fling(
        find.byType(PageView).first,
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(navIndex(tester), 1);
      final calendarState = tester.state(find.byType(CalendarTab));

      await forceSeason(tester, service, SeasonOverride.christmas);
      expect(navIndex(tester), 1);
      expect(tester.state(find.byType(CalendarTab)), same(calendarState));

      await forceSeason(tester, service, SeasonOverride.auto);
      expect(service.season, Season.none);
      expect(navIndex(tester), 1);
      expect(tester.state(find.byType(CalendarTab)), same(calendarState));
    });
  });

  group('HomePage debug season switch', () {
    // Not pumpAndSettle: once a season is forced, snow falls forever.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await settle(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
    }

    Future<void> backToHome(WidgetTester tester) async {
      // The system back gesture; Settings' own back button is scrolled away.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(SettingsPage), findsNothing);
    }

    /// Opens Settings and unlocks its DEBUG section with the hold on the
    /// version text.
    Future<void> openDebugPanel(WidgetTester tester) async {
      await openSettings(tester);
      await setDebugShown(tester, false);
      expect(seasonSegment('Christmas', skipOffstage: false), findsNothing);
      await holdVersionText(tester, SettingsPage.debugHold);
      expect(await debugShown(tester), isTrue);
    }

    /// Hides the DEBUG section again; it would outlive this test otherwise.
    Future<void> closeDebugPanel(WidgetTester tester) async {
      if (find.byType(SettingsPage).evaluate().isEmpty) {
        await openSettings(tester);
      }
      await setDebugShown(tester, false);
    }

    Future<void> tapSeason(WidgetTester tester, String label) async {
      final button = seasonSegment(label);
      await tester.ensureVisible(button);
      await tester.pump();
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      // Let the theme animate to the new palette.
      await tester.pump(const Duration(seconds: 1));
    }

    AppPalette paletteOf(WidgetTester tester, Type page) => Theme.of(
      tester.element(find.byType(page, skipOffstage: false)),
    ).extension<AppPalette>()!;

    testWidgets('is hidden until the version text is held in Settings', (
      tester,
    ) async {
      await pumpHome(tester);
      // Not on Home any more, whatever the gear does.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.settings_rounded)),
      );
      await tester.pump(const Duration(seconds: 6));
      await gesture.up();
      await settle(tester);
      expect(seasonSegment('Christmas', skipOffstage: false), findsNothing);
      if (find.byType(SettingsPage).evaluate().isNotEmpty) {
        await backToHome(tester);
      }

      await openDebugPanel(tester);
      for (final label in ['Auto', 'Normal', 'Halloween', 'Christmas']) {
        expect(seasonSegment(label, skipOffstage: false), findsOneWidget);
      }
      // Auto is the starting override.
      final auto = seasonSegment('Auto');
      await tester.ensureVisible(auto);
      await tester.pump();
      expect(tester.getSemantics(auto), containsSemantics(isSelected: true));

      await closeDebugPanel(tester);
    });

    testWidgets('tapping Christmas forces it, saves it and re-themes', (
      tester,
    ) async {
      final service = await pumpHome(tester);
      final normalGround = paletteOf(tester, HomePage).ground;
      expect(normalGround, AppPalette.of(Season.none, Brightness.light).ground);

      await openDebugPanel(tester);
      await tapSeason(tester, 'Christmas');

      expect(service.override, SeasonOverride.christmas);
      expect(service.season, Season.christmas);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SeasonService.overrideKey), 'christmas');

      final christmas = AppPalette.of(Season.christmas, Brightness.light);
      expect(paletteOf(tester, SettingsPage).ground, christmas.ground);
      expect(paletteOf(tester, HomePage).ground, christmas.ground);
      expect(paletteOf(tester, HomePage).fab, christmas.fab);
      expect(
        tester.getSemantics(seasonSegment('Christmas')),
        containsSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(seasonSegment('Auto')),
        containsSemantics(isSelected: false),
      );

      // Home snows behind Settings.
      await backToHome(tester);
      expect(find.byType(SnowLayer), findsOneWidget);

      // The panel is still there on the next visit and switches back.
      await openSettings(tester);
      expect(await debugShown(tester), isTrue);
      await tapSeason(tester, 'Normal');
      expect(service.override, SeasonOverride.normal);
      expect(service.season, Season.none);
      expect(prefs.getString(SeasonService.overrideKey), 'normal');
      expect(paletteOf(tester, SettingsPage).ground, normalGround);
      expect(paletteOf(tester, HomePage).ground, normalGround);

      await backToHome(tester);
      expect(find.byType(SnowLayer), findsNothing);

      await closeDebugPanel(tester);
    });

    testWidgets('tapping Halloween forces Halloween', (tester) async {
      final service = await pumpHome(tester);
      await openDebugPanel(tester);
      await tapSeason(tester, 'Halloween');

      expect(service.season, Season.halloween);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SeasonService.overrideKey), 'halloween');
      expect(
        paletteOf(tester, HomePage).ground,
        AppPalette.of(Season.halloween, Brightness.light).ground,
      );

      await backToHome(tester);
      expect(find.byType(SnowLayer), findsNothing);

      await closeDebugPanel(tester);
    });
  });
}
