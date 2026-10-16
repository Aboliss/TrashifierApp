import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

void main() {
  group('Seasonal animations', () {
    /// Pumps [child] with animations turned off (the phone's "remove
    /// animations" setting) or on, switchable afterwards.
    Future<void Function(bool)> pumpDecor(
      WidgetTester tester,
      Widget child, {
      required bool disableAnimations,
    }) async {
      late StateSetter setOuter;
      var off = disableAnimations;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: off),
                child: Scaffold(
                  body: Center(
                    child: SizedBox(width: 300, height: 300, child: child),
                  ),
                ),
              );
            },
          ),
        ),
      );
      return (value) => setOuter(() => off = value);
    }

    /// Lets everything start up (pictures load, the app's own transitions
    /// end).
    Future<void> settleIn(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final decorations = <String, Widget Function()>{
      'SnowLayer': () => const SnowLayer(),
      'LightsString': () => const LightsString(),
      'FloatingGhost': () => const FloatingGhost(),
      'HangingSpider': () => const HangingSpider(color: Color(0xFF2B1838)),
    };

    for (final MapEntry(key: name, value: build) in decorations.entries) {
      testWidgets('$name keeps animating normally', (tester) async {
        await pumpDecor(tester, build(), disableAnimations: false);
        await settleIn(tester);
        expect(tester.binding.hasScheduledFrame, isTrue);
      });

      testWidgets('$name stops with animations turned off', (tester) async {
        await pumpDecor(tester, build(), disableAnimations: true);
        await settleIn(tester);
        expect(tester.binding.hasScheduledFrame, isFalse);
      });

      testWidgets('$name follows the setting when it changes', (tester) async {
        final setOff = await pumpDecor(
          tester,
          build(),
          disableAnimations: false,
        );
        await settleIn(tester);
        expect(tester.binding.hasScheduledFrame, isTrue);

        setOff(true);
        await settleIn(tester);
        expect(tester.binding.hasScheduledFrame, isFalse);

        setOff(false);
        await settleIn(tester);
        expect(tester.binding.hasScheduledFrame, isTrue);
      });
    }

    testWidgets('a whole Christmas screen goes still', (tester) async {
      SharedPreferences.setMockInitialValues({
        SeasonService.overrideKey: 'christmas',
      });
      final service = SeasonService(now: () => DateTime(2026, 3, 10));
      await tester.pumpWidget(
        ChangeNotifierProvider<SeasonService?>.value(
          value: service,
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: const Scaffold(
                  body: SeasonBackdrop(child: Center(child: Text('content'))),
                ),
              ),
            ),
          ),
        ),
      );
      await settleIn(tester);

      expect(service.season, Season.christmas);
      expect(find.byType(SnowLayer), findsOneWidget);
      expect(find.byType(LightsString), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('SeasonBackdrop', () {
    const widgetChannel = MethodChannel('com.trashifier_app/widget');
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, (call) async => null);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, null);
    });

    testWidgets('keeps its child (and its state) across seasons', (
      tester,
    ) async {
      final service = SeasonService(
        now: () => DateTime(2026, 3, 10),
        random: Random(1),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<SeasonService?>.value(
          value: service,
          child: const MaterialApp(
            home: Scaffold(body: SeasonBackdrop(child: _Probe())),
          ),
        ),
      );
      await tester.pump();
      final probe = tester.state(find.byType(_Probe));
      expect(find.byType(SnowLayer), findsNothing);
      double inset() => tester.state<_ProbeState>(find.byType(_Probe)).inset;
      expect(inset(), 0);

      for (final (override, christmas) in [
        (SeasonOverride.christmas, true),
        (SeasonOverride.normal, false),
        (SeasonOverride.halloween, false),
        (SeasonOverride.christmas, true),
        (SeasonOverride.auto, false),
      ]) {
        service.setOverride(override);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final reason = override.name;
        expect(tester.state(find.byType(_Probe)), same(probe), reason: reason);
        expect(
          find.byType(SnowLayer),
          christmas ? findsOneWidget : findsNothing,
          reason: reason,
        );
        expect(
          find.byType(LightsString),
          christmas ? findsOneWidget : findsNothing,
          reason: reason,
        );
        expect(inset(), christmas ? greaterThan(0) : 0, reason: reason);
      }
    });
  });

  group('HalloweenDecor', () {
    /// Pumps every anchor's decoration with [override] saved, using a roll
    /// that decorates at least one anchor.
    Future<SeasonService> pumpAnchors(
      WidgetTester tester,
      SeasonOverride override,
    ) async {
      SharedPreferences.setMockInitialValues({
        SeasonService.overrideKey: override.name,
      });
      final service = SeasonService(
        now: () => DateTime(2026, 3, 10),
        random: Random(3),
      );
      expect(service.decor, isNotEmpty);
      await tester.pumpWidget(
        ChangeNotifierProvider<SeasonService?>.value(
          value: service,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  for (final anchor in DecorAnchor.values)
                    HalloweenDecor(anchor),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return service;
    }

    testWidgets('draws what the roll put on each anchor', (tester) async {
      final service = await pumpAnchors(tester, SeasonOverride.halloween);
      expect(service.season, Season.halloween);

      int count(DecorKind kind) =>
          service.decor.values.where((k) => k == kind).length;
      expect(find.byType(FloatingGhost), findsNWidgets(count(DecorKind.ghost)));
      expect(
        find.byType(HangingSpider),
        findsNWidgets(count(DecorKind.spider)),
      );
    });

    testWidgets('draws nothing outside Halloween', (tester) async {
      await pumpAnchors(tester, SeasonOverride.christmas);
      expect(find.byType(FloatingGhost), findsNothing);
      expect(find.byType(HangingSpider), findsNothing);
    });
  });
}

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  /// The lights' inset as last built.
  double inset = -1;

  @override
  Widget build(BuildContext context) {
    inset = SeasonBackdrop.topInset(context);
    return const Text('content');
  }
}
