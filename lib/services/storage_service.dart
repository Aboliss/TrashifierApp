import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/constants/app_constants.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/widget_service.dart';

/// Persists pickup dates per trash type.
///
/// Dates are stored as calendar days (`yyyy-MM-dd`), not instants, so a pickup
/// stays on the same day regardless of the device timezone. The Android home
/// screen widget reads the same keys (see TrashifierWidget.kt).
class StorageService {
  StorageService._privateConstructor();

  static final StorageService instance = StorageService._privateConstructor();

  static String encodeDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses `yyyy-MM-dd` as well as legacy ISO-8601 timestamps
  /// (e.g. `2025-10-05T00:00:00.000Z`). Only the calendar day is kept: legacy
  /// values were UTC midnight of the picked day, so the date fields are the
  /// day the user selected. Returns null for unparsable values.
  static DateTime? decodeDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) return null;
    final date = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    // Reject overflowing values such as 2025-02-31.
    if (date.month != int.parse(match.group(2)!)) return null;
    return date;
  }

  Future<void> saveDates(List<DateTime> dates, TrashType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dateStrings = _normalize(dates).map(encodeDate).toList();

      await prefs.setStringList(type.toString(), dateStrings);

      await WidgetService.updateWidget();
    } catch (e) {
      throw Exception('${AppConstants.storageSaveError}: $e');
    }
  }

  Future<List<DateTime>> loadDates(TrashType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dateStrings = prefs.getStringList(type.toString());

      if (dateStrings == null) return [];

      // Skip corrupt entries instead of losing the whole list.
      return _normalize(dateStrings.map(decodeDate).whereType<DateTime>());
    } catch (e) {
      throw Exception('${AppConstants.storageLoadError}: $e');
    }
  }

  Future<void> clearDates(TrashType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(type.toString());

      await WidgetService.updateWidget();
    } catch (e) {
      throw Exception('${AppConstants.storageSaveError}: $e');
    }
  }

  /// Converts to local calendar days, removes duplicates and sorts.
  static List<DateTime> _normalize(Iterable<DateTime> dates) {
    final unique = <DateTime>{
      for (final date in dates) DateFormatHelper.dateOnly(date),
    };
    return unique.toList()..sort();
  }
}
