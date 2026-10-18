import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:trashifier_app/l10n/app_localizations.dart';

export 'package:trashifier_app/l10n/app_localizations.dart';

/// Access to the UI strings.
///
/// Widgets use `context.l10n`. Code without a BuildContext (date and copy
/// helpers, reminder texts scheduled in the background) uses [L10n.current],
/// which the app keeps in step with the active locale (see main.dart).
/// Both fall back to English, e.g. in widget tests without localizations.
class L10n {
  static AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

  static AppLocalizations get current => _current;

  /// "en", "de", "es" or "sk"; for intl's date formats.
  static String get localeName => _current.localeName;

  /// The phone's 24-hour clock setting; times follow it in every language.
  static bool use24HourFormat = false;

  /// Switches [current] (and intl's default locale) to [locale], falling
  /// back to English for unsupported ones.
  static void update(Locale locale) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    final next = lookupAppLocalizations(
      supported ? Locale(locale.languageCode) : const Locale('en'),
    );
    if (next.localeName == _current.localeName) return;
    _current = next;
    Intl.defaultLocale = next.localeName;
  }
}

extension L10nContext on BuildContext {
  /// The strings for the locale in effect here. Rebuilds the caller when the
  /// language changes.
  AppLocalizations get l10n => AppLocalizations.of(this) ?? L10n.current;

  /// Rebuilds the caller when the phone's 24-hour setting changes; call it
  /// in build methods that show times (formatted via [L10n.use24HourFormat]).
  void watchClockFormat() => MediaQuery.alwaysUse24HourFormatOf(this);
}
