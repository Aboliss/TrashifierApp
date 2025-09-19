import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:trashifier_app/config/app_theme.dart';
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
        return MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme(), darkTheme: AppTheme.darkTheme(), themeMode: themeService.themeMode, home: const HomePage());
      },
    );
  }
}
