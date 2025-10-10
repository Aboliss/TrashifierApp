import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/main.dart';
import 'package:trashifier_app/services/theme_service.dart';

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
    });
  });
}
