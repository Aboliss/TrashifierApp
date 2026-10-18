import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/l10n/l10n.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/pages/splash_screen.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/locale_service.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date formats for every app language, also outside widgets.
  await initializeDateFormatting();
  _registerFontLicenses();

  try {
    await NotificationService.init();
  } catch (e) {
    // Continue anyway
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => SeasonService()),
        ChangeNotifierProvider(create: (context) => ReminderSettingsService()),
        ChangeNotifierProvider(create: (context) => LocaleService()),
      ],
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
    return Consumer3<ThemeService, SeasonService?, LocaleService?>(
      builder: (context, themeService, seasonService, localeService, child) {
        final season = seasonService?.season ?? Season.none;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => 'Trashifier',
          // Null follows the phone (or Android's per-app language setting).
          locale: localeService?.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Keeps L10n.current, used outside widgets, on the active locale
          // before anything below builds.
          builder: (context, child) {
            L10n.update(Localizations.localeOf(context));
            return child!;
          },
          theme: AppTheme.lightTheme(season),
          darkTheme: AppTheme.darkTheme(season),
          themeMode: themeService.themeMode,
          // Home is built under the splash so its data has loaded by the time
          // the splash fades away.
          home: Stack(
            children: [
              HomePage(ready: !_showSplash),
              if (_showSplash)
                SplashScreen(
                  onInitializationComplete: _onInitializationComplete,
                ),
            ],
          ),
        );
      },
    );
  }
}
