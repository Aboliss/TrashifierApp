import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';

List<TrashType> binsOf(int count) => [
  ...TrashType.builtIns,
  for (var slot = 4; slot < 10; slot++)
    TrashType(
      id: 'c$slot',
      slot: slot,
      position: slot,
      customName: 'Bin $slot',
      color: slot,
      icon: slot,
    ),
].take(count).toList();

void main() {
  group('BinMarkRow', () {
    Future<void> pumpRow(WidgetTester tester, Widget row) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(body: Center(child: row)),
        ),
      );
    }

    List<TrashType> markedTypes(WidgetTester tester) => [
      for (final mark in tester.widgetList<BinMark>(find.byType(BinMark)))
        mark.type,
    ];

    testWidgets('shows a mark per bin up to four', (tester) async {
      for (var count = 0; count <= 4; count++) {
        await pumpRow(tester, BinMarkRow(binsOf(count)));
        expect(find.byType(BinMark), findsNWidgets(count), reason: '$count');
        expect(find.textContaining('+'), findsNothing, reason: '$count');
      }
      expect(markedTypes(tester), TrashType.builtIns);
    });

    testWidgets('more than four shows three marks and "+N"', (tester) async {
      await pumpRow(tester, BinMarkRow(binsOf(5)));
      expect(find.byType(BinMark), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
      expect(markedTypes(tester), binsOf(3));

      await pumpRow(tester, BinMarkRow(binsOf(10)));
      expect(find.byType(BinMark), findsNWidgets(3));
      expect(find.text('+7'), findsOneWidget);
    });

    testWidgets('maxMarks changes the limit', (tester) async {
      await pumpRow(tester, BinMarkRow(binsOf(3), maxMarks: 2));
      expect(find.byType(BinMark), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);

      await pumpRow(tester, BinMarkRow(binsOf(2), maxMarks: 2));
      expect(find.byType(BinMark), findsNWidgets(2));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('bars share totalWidth but stay at least 6 px wide', (
      tester,
    ) async {
      await pumpRow(
        tester,
        BinMarkRow(binsOf(2), totalWidth: 30, spacing: 2, markHeight: 5),
      );
      for (final mark in tester.widgetList<BinMark>(find.byType(BinMark))) {
        expect(mark.width, 13); // 30 / 2 - 2
        expect(mark.height, 5);
      }

      await pumpRow(
        tester,
        BinMarkRow(binsOf(9), totalWidth: 30, spacing: 2, markHeight: 5),
      );
      expect(find.text('+6'), findsOneWidget);
      for (final mark in tester.widgetList<BinMark>(find.byType(BinMark))) {
        expect(mark.width, greaterThanOrEqualTo(6));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('passes onDark on to the marks', (tester) async {
      await pumpRow(tester, BinMarkRow(binsOf(2), onDark: true));
      for (final mark in tester.widgetList<BinMark>(find.byType(BinMark))) {
        expect(mark.onDark, isTrue);
      }
    });
  });
}
