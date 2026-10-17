import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/reminder_settings.dart';

/// The user's reminder day and time, persisted. Listeners (the home page)
/// re-arm all reminders when it changes.
class ReminderSettingsService extends ChangeNotifier {
  static const String daysBeforeKey = 'reminder_days_before';
  static const String hourKey = 'reminder_hour';
  static const String minuteKey = 'reminder_minute';

  ReminderSettings _settings = ReminderSettings.defaults;

  // Set once the user changes a setting; values that finish loading later
  // must not undo that change.
  bool _chosen = false;

  ReminderSettingsService() {
    _load();
  }

  ReminderSettings get settings => _settings;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_chosen) return;
      final loaded = ReminderSettings.validated(
        daysBefore: prefs.getInt(daysBeforeKey),
        hour: prefs.getInt(hourKey),
        minute: prefs.getInt(minuteKey),
      );
      if (loaded == _settings) return;
      _settings = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load reminder settings: $e');
    }
  }

  Future<void> update(ReminderSettings settings) async {
    _chosen = true;
    if (settings == _settings) return;
    _settings = settings;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(daysBeforeKey, settings.daysBefore);
      await prefs.setInt(hourKey, settings.hour);
      await prefs.setInt(minuteKey, settings.minute);
    } catch (e) {
      debugPrint('Failed to save reminder settings: $e');
    }
  }
}

extension ReminderSettingsContext on BuildContext {
  /// The reminder settings; [ReminderSettings.defaults] when no service is
  /// provided (e.g. in widget tests). Rebuilds the caller when they change.
  ReminderSettings get reminderSettings =>
      Provider.of<ReminderSettingsService?>(this)?.settings ??
      ReminderSettings.defaults;
}
