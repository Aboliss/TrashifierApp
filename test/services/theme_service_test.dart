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
      test('should initialize with light theme by default', () {
        themeService = ThemeService();

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(themeService.isDarkMode, isFalse);
      });

      test('should load saved theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.dark));
        expect(themeService.isDarkMode, isTrue);
      });

      test('should load light theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(themeService.isDarkMode, isFalse);
      });

      test('should default to light theme when no saved preference', () async {
        SharedPreferences.setMockInitialValues({});

        themeService = ThemeService();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(themeService.isDarkMode, isFalse);
      });
    });

    group('Theme Properties', () {
      setUp(() {
        themeService = ThemeService();
      });

      test('isDarkMode should return correct boolean for light theme', () {
        expect(themeService.isDarkMode, isFalse);
      });

      test('isDarkMode should return correct boolean for dark theme', () async {
        await themeService.setTheme(ThemeMode.dark);
        expect(themeService.isDarkMode, isTrue);
      });

      test('themeMode getter should return current theme mode', () {
        expect(themeService.themeMode, isA<ThemeMode>());
        expect(themeService.themeMode, equals(ThemeMode.light));
      });
    });

    group('toggleTheme', () {
      setUp(() {
        themeService = ThemeService();
      });

      test('should toggle from light to dark', () async {
        expect(themeService.themeMode, equals(ThemeMode.light));

        await themeService.toggleTheme();

        expect(themeService.themeMode, equals(ThemeMode.dark));
        expect(themeService.isDarkMode, isTrue);
      });

      test('should toggle from dark to light', () async {
        await themeService.setTheme(ThemeMode.dark);
        expect(themeService.themeMode, equals(ThemeMode.dark));

        await themeService.toggleTheme();

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(themeService.isDarkMode, isFalse);
      });

      test('should persist theme change to preferences', () async {
        await themeService.toggleTheme();

        final prefs = await SharedPreferences.getInstance();
        final savedTheme = prefs.getString('theme_mode');

        expect(savedTheme, equals('dark'));
      });

      test('should notify listeners when toggling', () async {
        bool notified = false;
        themeService.addListener(() {
          notified = true;
        });

        await themeService.toggleTheme();

        expect(notified, isTrue);
      });

      test('should handle multiple toggles correctly', () async {
        expect(themeService.themeMode, equals(ThemeMode.light));

        await themeService.toggleTheme();
        expect(themeService.themeMode, equals(ThemeMode.dark));

        await themeService.toggleTheme();
        expect(themeService.themeMode, equals(ThemeMode.light));

        await themeService.toggleTheme();
        expect(themeService.themeMode, equals(ThemeMode.dark));
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

        await themeService.setTheme(ThemeMode.light);

        expect(themeService.themeMode, equals(ThemeMode.light));
        expect(notified, isFalse);
      });

      test('should persist theme change to preferences', () async {
        await themeService.setTheme(ThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        final savedTheme = prefs.getString('theme_mode');

        expect(savedTheme, equals('dark'));
      });

      test('should notify listeners when changing theme', () async {
        bool notified = false;
        themeService.addListener(() {
          notified = true;
        });

        await themeService.setTheme(ThemeMode.dark);

        expect(notified, isTrue);
      });

      test('should handle system theme mode', () async {
        await themeService.setTheme(ThemeMode.system);

        expect(themeService.themeMode, equals(ThemeMode.system));
        expect(themeService.isDarkMode, isFalse);
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

      test('should handle preference key consistency', () async {
        await themeService.setTheme(ThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();

        expect(keys, contains('theme_mode'));
      });
    });

    group('ChangeNotifier Integration', () {
      setUp(() {
        themeService = ThemeService();
      });

      test('should extend ChangeNotifier', () {
        expect(themeService, isA<ChangeNotifier>());
      });

      test('should allow adding and removing listeners', () {
        void listener() {}

        expect(() => themeService.addListener(listener), returnsNormally);
        expect(() => themeService.removeListener(listener), returnsNormally);
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
      setUp(() {
        themeService = ThemeService();
      });

      test('should handle invalid saved theme values gracefully', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'invalid_value'});

        final service = ThemeService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.themeMode, equals(ThemeMode.light));
      });

      test('should handle all ThemeMode values', () async {
        final themeModes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

        for (final mode in themeModes) {
          await themeService.setTheme(mode);
          expect(themeService.themeMode, equals(mode));
        }
      });
    });
  });
}
