import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/constants/app_constants.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('${AppConstants.themeLoadError}: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');

      notifyListeners();
    } catch (e) {
      throw Exception('${AppConstants.themeSaveError}: $e');
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    try {
      _themeMode = themeMode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');

      notifyListeners();
    } catch (e) {
      throw Exception('${AppConstants.themeSaveError}: $e');
    }
  }
}
