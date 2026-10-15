import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/pages/splash_screen.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  try {
    await NotificationService.init();
  } catch (e) {
    // Continue anyway
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

/// Bundled fonts are under the SIL Open Font License; list them on the
/// licenses page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [
      ('Bricolage Grotesque', 'assets/fonts/OFL-BricolageGrotesque.txt'),
      ('Figtree', 'assets/fonts/OFL-Figtree.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(file));
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  void _onInitializationComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeService.themeMode,
          home: _showSplash
              ? SplashScreen(
                  onInitializationComplete: _onInitializationComplete,
                )
              : const HomePage(),
        );
      },
    );
  }
}
