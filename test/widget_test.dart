import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/main.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';
import 'package:trashifier_app/widgets/swipe_hint.dart';

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
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: themeService, child: const MyApp()),
      );

      expect(find.byType(Consumer<ThemeService>), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('HomePage', () {
    testWidgets('holding the theme button for 5s toggles debug buttons', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.bug_report), findsNothing);

      final themeButton = find.byIcon(Icons.brightness_auto);
      final gesture = await tester.startGesture(tester.getCenter(themeButton));
      await tester.pump(const Duration(seconds: 6));
      await gesture.up();
      await tester.pump();

      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(find.byIcon(Icons.widgets), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('tapping the theme button cycles the theme', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final themeService = ThemeService();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: themeService,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.brightness_auto));
      await tester.pump();

      expect(themeService.themeMode, equals(ThemeMode.light));
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
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
