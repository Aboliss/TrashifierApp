import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/widgets/swipe_reveal_row.dart';

import 'day_pickups_sheet_test.dart' show usePhoneScreen;

void main() {
  group('SwipeRevealRow peek', () {
    late int peeked;

    setUp(() => peeked = 0);

    Widget row({bool peek = true}) => SwipeRevealRow(
      peek: peek,
      onPeeked: () => peeked++,
      actionLabel: 'Remove',
      onAction: () {},
      action: const Text('Remove'),
      actionBackground: Colors.red,
      child: const SizedBox(
        height: 60,
        width: double.infinity,
        child: ColoredBox(color: Colors.white, child: Text('Row')),
      ),
    );

    Future<void> pumpRow(
      WidgetTester tester, {
      bool peek = true,
      bool disableAnimations = false,
      Widget? body,
    }) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          home: Scaffold(
            body: body ?? Column(children: [row(peek: peek)]),
          ),
        ),
      );
    }

    double rowX(WidgetTester tester) => tester.getTopLeft(find.text('Row')).dx;

    testWidgets('slides part way open, back, then reports it once', (
      tester,
    ) async {
      await pumpRow(tester);
      final closedX = rowX(tester);

      // Nothing happens before the delay.
      await tester.pump(
        SwipeRevealRow.peekDelay - const Duration(milliseconds: 1),
      );
      await tester.pump();
      expect(rowX(tester), closedX);

      // Slides out to 0.8 of the action width and holds there.
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 500));
      expect(rowX(tester), moreOrLessEquals(closedX + 0.8 * 96));
      expect(peeked, 0);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(rowX(tester), closedX);
      expect(peeked, 1);

      // Only once.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(rowX(tester), closedX);
      expect(peeked, 1);
    });

    testWidgets('does nothing without peek', (tester) async {
      await pumpRow(tester, peek: false);
      final closedX = rowX(tester);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(rowX(tester), closedX);
      expect(peeked, 0);
    });

    testWidgets('is skipped when animations are disabled', (tester) async {
      await pumpRow(tester, disableAnimations: true);
      final closedX = rowX(tester);

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(rowX(tester), closedX);
      }
      await tester.pump(const Duration(seconds: 5));
      expect(rowX(tester), closedX);
      expect(peeked, 0);
    });

    testWidgets('a drag during the peek stops it and counts as seen', (
      tester,
    ) async {
      await pumpRow(tester);
      final closedX = rowX(tester);

      await tester.pump(SwipeRevealRow.peekDelay);
      await tester.pump(const Duration(milliseconds: 150));
      expect(rowX(tester), greaterThan(closedX));

      // Pull it back closed with a finger.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-15, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(peeked, 1);
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(rowX(tester), closedX);
      expect(peeked, 1);
    });

    testWidgets('waits until the row is scrolled on screen', (tester) async {
      await pumpRow(
        tester,
        body: ListView(
          children: [
            const SizedBox(height: 1200),
            row(),
            const SizedBox(height: 400),
          ],
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      expect(peeked, 0);

      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Row'), findsOneWidget);
      final closedX = rowX(tester);

      await tester.pump(SwipeRevealRow.peekDelay);
      await tester.pump(const Duration(milliseconds: 500));
      expect(rowX(tester), greaterThan(closedX));

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(peeked, 1);
      expect(rowX(tester), closedX);
    });

    testWidgets('waits while covered by the bottom inset', (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SwipeRevealRow(
                peek: true,
                onPeeked: () => peeked++,
                peekBottomInset: 100,
                actionLabel: 'Remove',
                onAction: () {},
                action: const Text('Remove'),
                actionBackground: Colors.red,
                child: const SizedBox(height: 60, child: Text('Row')),
              ),
            ),
          ),
        ),
      );
      final closedX = rowX(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(rowX(tester), closedX);
      expect(peeked, 0);
    });
  });
}
