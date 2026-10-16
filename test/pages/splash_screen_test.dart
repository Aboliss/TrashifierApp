import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/pages/splash_screen.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/bin_buddy.dart';

void main() {
  group('SplashScreen', () {
    late int calls;

    setUp(() {
      calls = 0;
      SharedPreferences.setMockInitialValues({});
    });

    /// Pumps the splash; with [tickersOn] false its animation never advances.
    Future<void> pumpSplash(
      WidgetTester tester, {
      SeasonService? season,
      bool tickersOn = true,
    }) async {
      final app = MaterialApp(
        theme: AppTheme.lightTheme(season?.season ?? Season.none),
        home: TickerMode(
          enabled: tickersOn,
          child: SplashScreen(onInitializationComplete: () => calls++),
        ),
      );
      await tester.pumpWidget(
        season == null
            ? app
            : ChangeNotifierProvider<SeasonService?>.value(
                value: season,
                child: app,
              ),
      );
    }

    /// Pumps frames [step] apart for [total].
    Future<void> pumpFrames(
      WidgetTester tester,
      Duration total, {
      Duration step = const Duration(milliseconds: 50),
    }) async {
      for (var t = Duration.zero; t < total; t += step) {
        await tester.pump(step);
      }
    }

    List<BuddyCostume> costumes(WidgetTester tester) => tester
        .widgetList<BinBuddy>(find.byType(BinBuddy))
        .map((buddy) => buddy.costume)
        .toList();

    testWidgets('closes once the animation has played', (tester) async {
      await pumpSplash(tester);
      expect(calls, 0);

      // The animation is 1.6 s; well before the 4 s fallback.
      await pumpFrames(tester, const Duration(milliseconds: 1000));
      expect(calls, 0);
      await pumpFrames(tester, const Duration(milliseconds: 1500));
      expect(calls, 1);

      // Nothing more once the fallback time has passed too.
      await pumpFrames(tester, const Duration(seconds: 3));
      expect(calls, 1);
    });

    /// Builds the splash (running its initState) without drawing a frame,
    /// like a slow start-up where the first frame takes seconds.
    void buildWithoutFrame(WidgetTester tester) {
      final binding = tester.binding;
      binding.attachRootWidget(
        binding.wrapWithDefaultView(
          MaterialApp(
            home: SplashScreen(onInitializationComplete: () => calls++),
          ),
        ),
      );
      binding.buildOwner!.buildScope(binding.rootElement!);
      expect(find.byType(SplashScreen), findsOneWidget);
    }

    testWidgets('closes 4 s after the first frame when no more frames come', (
      tester,
    ) async {
      await pumpSplash(tester);

      // The first frame is drawn, then time passes without another one: the
      // animation never starts.
      await tester.binding.delayed(const Duration(milliseconds: 3900));
      expect(calls, 0);
      await tester.binding.delayed(const Duration(milliseconds: 200));
      expect(calls, 1);

      // Frames resuming later play the animation without closing again.
      await pumpFrames(tester, const Duration(seconds: 3));
      expect(calls, 1);
    });

    testWidgets('a slow first frame still gets the whole animation', (
      tester,
    ) async {
      buildWithoutFrame(tester);

      // The first frame takes 7 s (seen on a slow emulator).
      await tester.binding.delayed(const Duration(seconds: 7));
      expect(calls, 0);

      // The animation then plays in full and closes the splash itself, well
      // before 4 s after that frame.
      await pumpFrames(tester, const Duration(milliseconds: 1000));
      expect(calls, 0);
      await pumpFrames(tester, const Duration(milliseconds: 1500));
      expect(calls, 1);

      await pumpFrames(tester, const Duration(seconds: 4));
      expect(calls, 1);
    });

    testWidgets('closes after 10 s when no frame is ever drawn', (
      tester,
    ) async {
      buildWithoutFrame(tester);

      await tester.binding.delayed(const Duration(milliseconds: 9900));
      expect(calls, 0);
      await tester.binding.delayed(const Duration(milliseconds: 200));
      expect(calls, 1);

      // Frames arriving after all don't close it again. (Past the 4 s the
      // first frame starts, so no timer is left pending.)
      await pumpFrames(tester, const Duration(seconds: 5));
      expect(calls, 1);
    });

    testWidgets('closes after 4 s when the animation is stuck', (tester) async {
      // Frames come, but the muted ticker never moves the animation on.
      await pumpSplash(tester, tickersOn: false);

      await pumpFrames(tester, const Duration(milliseconds: 3900));
      expect(calls, 0);
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(calls, 1);

      await pumpFrames(tester, const Duration(seconds: 3));
      expect(calls, 1);
    });

    testWidgets('a splash removed early never calls back', (tester) async {
      await pumpSplash(tester);
      await pumpFrames(tester, const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      // The fallback timer is cancelled too (a pending timer would fail the
      // test).
      await tester.binding.delayed(const Duration(seconds: 5));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('Bin Buddy stays normal out of season', (tester) async {
      await pumpSplash(tester);
      await tester.pump();
      expect(costumes(tester), [BuddyCostume.normal]);

      await pumpFrames(tester, const Duration(milliseconds: 1000));
      expect(costumes(tester), [BuddyCostume.normal]);
    });

    for (final (override, costume) in [
      (SeasonOverride.christmas, BuddyCostume.santa),
      (SeasonOverride.halloween, BuddyCostume.pumpkin),
    ]) {
      testWidgets('Bin Buddy changes into $costume during the hop '
          '(${override.name})', (tester) async {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: override.name,
        });
        final service = SeasonService(
          now: () => DateTime(2026, 3, 10),
          random: Random(1),
        );
        await pumpSplash(tester, season: service);
        // Loads the saved override and starts the animation.
        await tester.pump();
        expect(service.override, override);

        // Like the native splash at first...
        expect(costumes(tester), [BuddyCostume.normal]);
        await tester.pump(const Duration(milliseconds: 100));
        expect(costumes(tester), [BuddyCostume.normal]);

        // ...then in costume from the top of the first hop (0.2 of 1.6 s).
        await pumpFrames(tester, const Duration(milliseconds: 400));
        expect(costumes(tester), [costume]);
        await pumpFrames(tester, const Duration(milliseconds: 600));
        expect(costumes(tester), [costume]);

        await pumpFrames(tester, const Duration(seconds: 1));
        expect(calls, 1);
      });
    }
  });
}
