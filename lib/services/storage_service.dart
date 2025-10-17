import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/constants/app_constants.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/widget_service.dart';

class StorageService {
  StorageService._privateConstructor();

  static final StorageService instance = StorageService._privateConstructor();

  Future<void> saveDates(List<DateTime> dates, TrashType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String key = type.toString();

      List<String> dateStrings = dates
          .map((date) => date.toIso8601String())
          .toList();

      await prefs.setStringList(key, dateStrings);

      await WidgetService.updateWidget();
    } catch (e) {
      throw Exception('${AppConstants.storageSaveError}: $e');
    }
  }

  Future<List<DateTime>> loadDates(TrashType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String key = type.toString();

      List<String>? dateStrings = prefs.getStringList(key);

      if (dateStrings == null) return [];

      return dateStrings.map((date) => DateTime.parse(date)).toList();
    } catch (e) {
      throw Exception('${AppConstants.storageLoadError}: $e');
    }
  }

  Future<void> clearDates(TrashType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String key = type.toString();

      await prefs.remove(key);
    } catch (e) {
      throw Exception('${AppConstants.storageSaveError}: $e');
    }
  }
}
