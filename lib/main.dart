import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  tz.initializeTimeZones();

  runApp(ChangeNotifierProvider(create: (context) => ThemeService(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(debugShowCheckedModeBanner: false, theme: _lightTheme(), darkTheme: _darkTheme(), themeMode: themeService.themeMode, home: const HomePage());
      },
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardTheme: const CardThemeData(color: Colors.white, elevation: 4, shadowColor: Colors.black26),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: const CardThemeData(color: Color(0xFF1E1E1E), elevation: 4, shadowColor: Colors.black38),
    );
  }
}
