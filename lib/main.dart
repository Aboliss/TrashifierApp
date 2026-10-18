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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _showSplash = true;

  // Android's 24-hour clock setting, asked on start and on every resume:
  // Flutter's own copy (MediaQuery.alwaysUse24HourFormat) is only refreshed
  // on configuration changes, so it goes stale when just that setting
  // changes. Null until known (and in tests), then the platform value is used.
  static const MethodChannel _system = MethodChannel(
    'com.trashifier_app/system',
  );
  bool? _phone24HourFormat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshClockFormat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshClockFormat();
  }

  Future<void> _refreshClockFormat() async {
    try {
      final use24 = await _system.invokeMethod<bool>('is24HourFormat');
      if (use24 != null && use24 != _phone24HourFormat && mounted) {
        setState(() => _phone24HourFormat = use24);
      }
    } on MissingPluginException {
      // Not on Android (widget tests): MediaQuery's value is used.
    } on PlatformException catch (e) {
      debugPrint('Failed to read the clock format: $e');
    }
  }

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
          // Keeps L10n (strings and the 24-hour setting), used outside
          // widgets, in step before anything below builds.
          builder: (context, child) {
            L10n.update(Localizations.localeOf(context));
            // MediaQuery's copy can be stale (see _phone24HourFormat). The
            // override makes everything that watches the clock format
            // (context.watchClockFormat) rebuild when it changes.
            final media = MediaQuery.of(context);
            final use24 = _phone24HourFormat ?? media.alwaysUse24HourFormat;
            L10n.use24HourFormat = use24;
            if (media.alwaysUse24HourFormat == use24) return child!;
            return MediaQuery(
              data: media.copyWith(alwaysUse24HourFormat: use24),
              child: child!,
            );
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
