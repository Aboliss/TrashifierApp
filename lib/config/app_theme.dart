import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightScaffoldBackground = Color(0xFFF5F5F5);
  static const Color _darkScaffoldBackground = Color(0xFF121212);
  static const Color _lightCardColor = Colors.white;
  static const Color _darkCardColor = Color(0xFF1E1E1E);
  static const double _cardElevation = 4;
  static const Color _lightCardShadow = Colors.black26;
  static const Color _darkCardShadow = Colors.black38;

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: _lightScaffoldBackground,
      cardTheme: const CardThemeData(
        color: _lightCardColor,
        elevation: _cardElevation,
        shadowColor: _lightCardShadow,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: _darkScaffoldBackground,
      cardTheme: const CardThemeData(
        color: _darkCardColor,
        elevation: _cardElevation,
        shadowColor: _darkCardShadow,
      ),
    );
  }
}
