import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/trash_type.dart';

class StorageService {
  StorageService._privateConstructor();

  static final StorageService instance = StorageService._privateConstructor();

  Future<void> saveDates(List<DateTime> dates, TrashType type) async {
    final prefs = await SharedPreferences.getInstance();

    String key = type.toString();

    List<String> dateStrings = dates.map((date) => date.toIso8601String()).toList();

    prefs.setStringList(key, dateStrings);
  }

  Future<List<DateTime>> loadDates(TrashType type) async {
    final prefs = await SharedPreferences.getInstance();

    String key = type.toString();

    List<String>? dateStrings = prefs.getStringList(key);

    if (dateStrings == null) return [];

    return dateStrings.map((date) => DateTime.parse(date)).toList();
  }

  Future<void> clearDates(TrashType type) async {
    final prefs = await SharedPreferences.getInstance();

    String key = type.toString();

    prefs.remove(key);
  }
}
