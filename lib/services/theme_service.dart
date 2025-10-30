import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/constants/app_constants.dart';
import 'package:trashifier_app/services/widget_service.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _manualOverrideKey = 'theme_manual_override';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isManualOverride = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isManualOverride => _isManualOverride;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      _isManualOverride = prefs.getBool(_manualOverrideKey) ?? false;

      if (savedTheme != null && _isManualOverride) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      throw Exception('${AppConstants.themeLoadError}: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isManualOverride = true;
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
      await prefs.setBool(_manualOverrideKey, true);

      notifyListeners();
    } catch (e) {
      throw Exception('${AppConstants.themeSaveError}: $e');
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    try {
      _themeMode = themeMode;
      _isManualOverride = themeMode != ThemeMode.system;

      final prefs = await SharedPreferences.getInstance();
      if (_isManualOverride) {
        await prefs.setString(
          _themeKey,
          _themeMode == ThemeMode.dark ? 'dark' : 'light',
        );
        await prefs.setBool(_manualOverrideKey, true);
      } else {
        await prefs.remove(_themeKey);
        await prefs.setBool(_manualOverrideKey, false);
      }

      notifyListeners();
    } catch (e) {
      throw Exception('${AppConstants.themeSaveError}: $e');
    }
  }

  Future<void> resetToSystemTheme() async {
    try {
      _themeMode = ThemeMode.system;
      _isManualOverride = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.setBool(_manualOverrideKey, false);

      notifyListeners();
    } catch (e) {
      throw Exception('${AppConstants.themeSaveError}: $e');
    }
  }

  void updateSystemTheme(Brightness systemBrightness) {
    WidgetService.updateWidget();

    if (!_isManualOverride) {
      final newMode = systemBrightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;

      if (_themeMode != newMode && _themeMode != ThemeMode.system) {
        _themeMode = ThemeMode.system;
        notifyListeners();
      }
    }
  }
}
