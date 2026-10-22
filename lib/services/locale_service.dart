import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/services/widget_service.dart';

/// The app language: the phone's (default) or one picked in Settings.
///
/// The Android widgets read the same preference (`flutter.app_language`).
class LocaleService extends ChangeNotifier {
  static const String languageKey = 'app_language';

  /// Value stored for "follow the phone".
  static const String system = 'system';

  /// Language codes with translations, in the order the picker lists them.
  static const List<String> languages = ['en', 'de', 'es', 'sk'];

  /// Each language's name in itself, as the picker shows it.
  static const Map<String, String> nativeNames = {
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'sk': 'Slovenčina',
  };

  String _language = system;

  // Set once the user picks a language; a saved value that finishes loading
  // later must not undo that choice.
  bool _chosen = false;

  LocaleService() {
    _load();
  }

  /// [system] or one of [languages].
  String get language => _language;

  /// The forced locale, or null to follow the phone.
  Locale? get locale => _language == system ? null : Locale(_language);

  static String _validated(String? value) =>
      languages.contains(value) ? value! : system;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_chosen) return;
      final saved = _validated(prefs.getString(languageKey));
      if (saved == _language) return;
      _language = saved;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load the app language: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    _chosen = true;
    final value = _validated(language);
    if (value == _language) return;
    _language = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languageKey, value);
    } catch (e) {
      debugPrint('Failed to save the app language: $e');
    }
    // The widgets show text too.
    await WidgetService.updateWidget();
  }
}
