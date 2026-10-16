import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/services/season_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // setOverride refreshes the home screen widgets. Unanswered, the platform
  // call never completes inside testWidgets' fake async zone.
  const widgetChannel = MethodChannel('com.trashifier_app/widget');
  final widgetCalls = <String>[];
  setUp(() {
    widgetCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async {
          widgetCalls.add(call.method);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
  });

  group('SeasonService', () {
    final march = DateTime(2026, 3, 10);
    final october = DateTime(2026, 10, 16);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Lets the constructor's async load from SharedPreferences finish.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    group('loading', () {
      test('defaults to auto and the date\'s season', () async {
        final service = SeasonService(now: () => october);
        await settle();

        expect(service.override, SeasonOverride.auto);
        expect(service.season, Season.halloween);
        expect(service.costume, BuddyCostume.pumpkin);
      });

      test('applies the saved override and notifies', () async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: 'christmas',
        });
        final service = SeasonService(now: () => march);
        var notified = 0;
        service.addListener(() => notified++);
        await settle();

        expect(service.override, SeasonOverride.christmas);
        expect(service.season, Season.christmas);
        expect(service.costume, BuddyCostume.santa);
        expect(notified, greaterThanOrEqualTo(1));
      });

      test('a saved "normal" turns off the date\'s season', () async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: 'normal',
        });
        final service = SeasonService(now: () => october);
        await settle();

        expect(service.override, SeasonOverride.normal);
        expect(service.season, Season.none);
      });

      test('an invalid saved value falls back to auto', () async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: 'easter',
        });
        final service = SeasonService(now: () => october);
        await settle();

        expect(service.override, SeasonOverride.auto);
        expect(service.season, Season.halloween);
      });
    });

    group('setOverride', () {
      test('persists the override and notifies', () async {
        final service = SeasonService(now: () => march);
        await settle();
        var notified = 0;
        service.addListener(() => notified++);

        await service.setOverride(SeasonOverride.halloween);

        expect(service.override, SeasonOverride.halloween);
        expect(service.season, Season.halloween);
        expect(notified, 1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(SeasonService.overrideKey), 'halloween');
        // The home screen widgets read the override too.
        expect(widgetCalls, ['updateWidget']);
      });

      test('notifies even when the season stays the same', () async {
        // October is Halloween on auto; forcing Halloween changes only the
        // override, which the debug panel shows.
        final service = SeasonService(now: () => october);
        await settle();
        var notified = 0;
        service.addListener(() => notified++);

        await service.setOverride(SeasonOverride.halloween);

        expect(service.season, Season.halloween);
        expect(notified, 1);
      });

      test('setting the current override does nothing', () async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: 'christmas',
        });
        final service = SeasonService(now: () => march);
        await settle();
        var notified = 0;
        service.addListener(() => notified++);

        await service.setOverride(SeasonOverride.christmas);

        expect(notified, 0);
        expect(widgetCalls, isEmpty);
      });

      test('back to auto follows the date again and is saved', () async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: 'christmas',
        });
        final service = SeasonService(now: () => october);
        await settle();
        expect(service.season, Season.christmas);

        await service.setOverride(SeasonOverride.auto);

        expect(service.season, Season.halloween);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(SeasonService.overrideKey), 'auto');
      });

      test('a new service reads what the last one saved', () async {
        final first = SeasonService(now: () => march);
        await settle();
        await first.setOverride(SeasonOverride.christmas);

        final second = SeasonService(now: () => march);
        await settle();

        expect(second.override, SeasonOverride.christmas);
        expect(second.season, Season.christmas);
      });
    });

    group('refresh', () {
      test('picks up a new month', () async {
        var now = DateTime(2026, 9, 30, 23, 59);
        final service = SeasonService(now: () => now);
        await settle();
        expect(service.season, Season.none);
        var notified = 0;
        service.addListener(() => notified++);

        now = DateTime(2026, 10, 1, 0, 1);
        service.refresh();
        expect(service.season, Season.halloween);
        expect(notified, 1);

        now = DateTime(2026, 11, 1);
        service.refresh();
        expect(service.season, Season.none);
        expect(notified, 2);

        now = DateTime(2026, 12, 1);
        service.refresh();
        expect(service.season, Season.christmas);
        expect(service.costume, BuddyCostume.santa);
        expect(notified, 3);
      });

      test('does not notify when the season is unchanged', () async {
        var now = DateTime(2026, 10, 1);
        final service = SeasonService(now: () => now);
        await settle();
        var notified = 0;
        service.addListener(() => notified++);

        now = DateTime(2026, 10, 20);
        service.refresh();

        expect(service.season, Season.halloween);
        expect(notified, 0);
      });

      test('a forced season ignores the date', () async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: 'halloween',
        });
        var now = DateTime(2026, 10, 1);
        final service = SeasonService(now: () => now);
        await settle();

        now = DateTime(2026, 12, 1);
        service.refresh();

        expect(service.season, Season.halloween);
      });
    });

    group('decor', () {
      const allowed = {
        DecorAnchor.header: {DecorKind.ghost, DecorKind.spider},
        DecorAnchor.heroPerch: {DecorKind.pumpkin},
        DecorAnchor.heroSky: {DecorKind.ghost},
        DecorAnchor.weekTitle: {DecorKind.ghost, DecorKind.pumpkin},
        DecorAnchor.comingUpTitle: {DecorKind.ghost, DecorKind.pumpkin},
        DecorAnchor.calendarHeader: {DecorKind.ghost, DecorKind.spider},
        DecorAnchor.addSheet: {
          DecorKind.ghost,
          DecorKind.spider,
          DecorKind.pumpkin,
        },
      };

      test('every anchor has a rule', () {
        expect(allowed.keys.toSet(), DecorAnchor.values.toSet());
      });

      test('every anchor only gets kinds that fit it', () {
        final seen = {for (final anchor in DecorAnchor.values) anchor: 0};
        final kindsSeen = {
          for (final anchor in DecorAnchor.values) anchor: <DecorKind>{},
        };
        const rolls = 200;
        for (var seed = 0; seed < rolls; seed++) {
          final decor = SeasonService(
            now: () => october,
            random: Random(seed),
          ).decor;
          decor.forEach((anchor, kind) {
            expect(allowed[anchor], contains(kind), reason: 'seed $seed');
            seen[anchor] = seen[anchor]! + 1;
            kindsSeen[anchor]!.add(kind);
          });
        }

        // Each spot is sometimes empty and sometimes decorated, and spots
        // that allow several kinds get all of them.
        for (final anchor in DecorAnchor.values) {
          expect(seen[anchor], inExclusiveRange(0, rolls), reason: '$anchor');
          expect(kindsSeen[anchor], allowed[anchor], reason: '$anchor');
        }
      });

      test('the same seed rolls the same decor', () {
        final a = SeasonService(now: () => october, random: Random(7)).decor;
        final b = SeasonService(now: () => october, random: Random(7)).decor;
        expect(a, equals(b));
      });
    });
  });

  group('SeasonContext', () {
    Season? season;
    BuddyCostume? costume;
    var builds = 0;

    final probe = Builder(
      builder: (context) {
        builds++;
        season = context.season;
        costume = context.buddyCostume;
        return const SizedBox();
      },
    );

    setUp(() {
      season = null;
      costume = null;
      builds = 0;
    });

    testWidgets('is none without a SeasonService', (tester) async {
      await tester.pumpWidget(probe);

      expect(season, Season.none);
      expect(costume, BuddyCostume.normal);
    });

    testWidgets('is none with a null SeasonService', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SeasonService?>.value(value: null, child: probe),
      );

      expect(season, Season.none);
      expect(costume, BuddyCostume.normal);
    });

    testWidgets('follows the provided service and rebuilds on change', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final service = SeasonService(now: () => DateTime(2026, 12, 5));
      await tester.pumpWidget(
        ChangeNotifierProvider<SeasonService?>.value(
          value: service,
          child: probe,
        ),
      );
      await tester.pump();

      expect(season, Season.christmas);
      expect(costume, BuddyCostume.santa);
      final buildsBefore = builds;

      await service.setOverride(SeasonOverride.halloween);
      await tester.pump();

      expect(builds, greaterThan(buildsBefore));
      expect(season, Season.halloween);
      expect(costume, BuddyCostume.pumpkin);
    });
  });
}
