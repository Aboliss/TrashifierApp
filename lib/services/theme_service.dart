import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/constants/app_constants.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  static ThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = _decode(savedTheme);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('${AppConstants.themeLoadError}: $e');
    }
  }

  /// Cycles system -> light -> dark -> system.
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setTheme(ThemeMode.light);
      case ThemeMode.light:
        await setTheme(ThemeMode.dark);
      case ThemeMode.dark:
        await setTheme(ThemeMode.system);
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _encode(_themeMode));
    } catch (e) {
      debugPrint('${AppConstants.themeSaveError}: $e');
    }
  }
}
