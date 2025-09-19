import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';

class NotificationHelper {
  static Future<void> scheduleNotificationsForDates(List<DateTime> dates, TrashType type) async {
    for (var date in dates) {
      final scheduledTime = DateTime(date.year, date.month, date.day - 1, 19, 0);

      if (scheduledTime.isBefore(DateTime.now())) {
        continue;
      }

      await NotificationService.scheduleNotification(date.hashCode, TrashTypeHelper.getNotificationTitle(type), TrashTypeHelper.getNotificationBody(type), scheduledTime);
    }
  }

  static Future<void> cancelNotificationsForDates(List<DateTime> dates) async {
    for (var date in dates) {
      await NotificationService.cancelNotification(date.hashCode);
    }
  }

  static Future<void> rescheduleNotificationsForType(List<DateTime> newDates, List<DateTime> oldDates, TrashType type) async {
    final newlyAddedDates = newDates.where((newDate) => !oldDates.any((d) => DateFormatHelper.isSameDate(d, newDate))).toList();

    final removedDates = oldDates.where((existingDate) => !newDates.any((s) => DateFormatHelper.isSameDate(s, existingDate))).toList();

    if (newlyAddedDates.isNotEmpty) {
      await scheduleNotificationsForDates(newlyAddedDates, type);
    }

    if (removedDates.isNotEmpty) {
      await cancelNotificationsForDates(removedDates);
    }
  }
}
