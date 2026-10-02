import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/main.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/day_pickups_dialog.dart';

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

    testWidgets('tapping a calendar day edits that day\'s pickups', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      // The 15th is never shown as an adjacent-month day.
      final day15 = find.text('15');
      await tester.ensureVisible(day15);
      await tester.tap(day15);
      await tester.pumpAndSettle();

      expect(find.byType(DayPickupsDialog), findsOneWidget);

      await tester.tap(find.text('Plastic'));
      await tester.tap(find.text('Save'));
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
