import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';

/// Short texts shown around the next pickup.
class PickupCopyHelper {
  /// Home screen headline.
  static String headline(PickupDay? next, [DateTime? now]) {
    if (next == null) return 'No bins planned yet';
    final days = next.daysUntil(now);
    final big = next.types.length > 1;
    if (days == 0) return big ? 'Big bin day today!' : 'Bin day today!';
    if (days == 1) {
      return big ? 'Big bin day tomorrow!' : 'Bin day tomorrow!';
    }
    if (days < 7) {
      return 'Bins out on ${DateFormatHelper.formatDayName(next.date)}';
    }
    return 'A quiet week for bins';
  }

  /// "Today", "Tomorrow", "In 5 days", "Yesterday", "3 days ago".
  static String relativeDay(DateTime date, [DateTime? now]) {
    final days = DateFormatHelper.calculateDaysUntil(date, now);
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days > 1) return 'In $days days';
    return '${-days} days ago';
  }

  /// When the reminder for [day] fires, relative to [now].
  static String reminderLine(PickupDay day, [DateTime? now]) {
    now ??= DateTime.now();
    final days = day.daysUntil(now);
    final time = formatHour(NotificationHelper.reminderHour);
    if (days <= 0) return 'Pickup is today';
    if (days == 1) {
      return now.hour < NotificationHelper.reminderHour
          ? 'Reminder tonight at $time'
          : 'Put the bins out tonight';
    }
    final evening = day.date.subtract(const Duration(days: 1));
    return 'Reminder on ${DateFormatHelper.formatDayName(evening)} at $time';
  }

  /// 19 -> "7:00 PM".
  static String formatHour(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 ${hour < 12 ? 'AM' : 'PM'}';
  }
}
