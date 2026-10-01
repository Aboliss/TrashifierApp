import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    late ThemeService themeService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize with system theme by default', () {
        themeService = ThemeService();

        expect(themeService.themeMode, equals(ThemeMode.system));
        expect(themeService.isDarkMode, isFalse);
      });

      test('should load saved dark theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.dark));
        expect(themeService.isDarkMode, isTrue);
      });

      test('should load saved light theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(themeService.isDarkMode, isFalse);
      });

      test('should load saved system theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'system'});

        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.system));
      });

      test('should default to system theme when no saved preference', () async {
        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.system));
      });
    });

    group('toggleTheme', () {
      setUp(() {
        themeService = ThemeService();
      });

      test('should cycle system -> light -> dark -> system', () async {
        expect(themeService.themeMode, equals(ThemeMode.system));

        await themeService.toggleTheme();
        expect(themeService.themeMode, equals(ThemeMode.light));

        await themeService.toggleTheme();
        expect(themeService.themeMode, equals(ThemeMode.dark));
        expect(themeService.isDarkMode, isTrue);

        await themeService.toggleTheme();
        expect(themeService.themeMode, equals(ThemeMode.system));
      });

      test('should persist theme change to preferences', () async {
        await themeService.toggleTheme();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), equals('light'));
      });

      test('should notify listeners when toggling', () async {
        bool notified = false;
        themeService.addListener(() {
          notified = true;
        });

        await themeService.toggleTheme();

        expect(notified, isTrue);
      });
    });

    group('setTheme', () {
      setUp(() {
        themeService = ThemeService();
      });

      test('should set theme to dark', () async {
        await themeService.setTheme(ThemeMode.dark);

        expect(themeService.themeMode, equals(ThemeMode.dark));
        expect(themeService.isDarkMode, isTrue);
      });

      test('should set theme to light', () async {
        await themeService.setTheme(ThemeMode.dark);
        await themeService.setTheme(ThemeMode.light);

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(themeService.isDarkMode, isFalse);
      });

      test('should not change or notify if setting same theme', () async {
        bool notified = false;
        themeService.addListener(() {
          notified = true;
        });

        await themeService.setTheme(ThemeMode.system);

        expect(themeService.themeMode, equals(ThemeMode.system));
        expect(notified, isFalse);
      });

      test('should persist every mode to preferences', () async {
        final prefs = await SharedPreferences.getInstance();

        await themeService.setTheme(ThemeMode.dark);
        expect(prefs.getString('theme_mode'), equals('dark'));

        await themeService.setTheme(ThemeMode.light);
        expect(prefs.getString('theme_mode'), equals('light'));

        await themeService.setTheme(ThemeMode.system);
        expect(prefs.getString('theme_mode'), equals('system'));
      });

      test('should notify listeners when changing theme', () async {
        bool notified = false;
        themeService.addListener(() {
          notified = true;
        });

        await themeService.setTheme(ThemeMode.dark);

        expect(notified, isTrue);
      });
    });

    group('Persistence Integration', () {
      test('should maintain theme across service instances', () async {
        final service1 = ThemeService();
        await service1.setTheme(ThemeMode.dark);

        final service2 = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(service2.themeMode, equals(ThemeMode.dark));
        expect(service2.isDarkMode, isTrue);
      });
    });

    group('ChangeNotifier Integration', () {
      setUp(() {
        themeService = ThemeService();
      });

      test('should extend ChangeNotifier', () {
        expect(themeService, isA<ChangeNotifier>());
      });

      test('should notify multiple listeners', () async {
        int notificationCount = 0;

        void listener1() => notificationCount++;
        void listener2() => notificationCount++;

        themeService.addListener(listener1);
        themeService.addListener(listener2);

        await themeService.toggleTheme();

        expect(notificationCount, equals(2));
      });

      test('should not notify removed listeners', () async {
        bool notified = false;

        void listener() => notified = true;

        themeService.addListener(listener);
        themeService.removeListener(listener);

        await themeService.toggleTheme();

        expect(notified, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should fall back to system for invalid saved values', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'invalid_value'});

        final service = ThemeService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.themeMode, equals(ThemeMode.system));
      });
    });
  });
}
