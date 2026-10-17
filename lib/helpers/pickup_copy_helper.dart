import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/season.dart';

/// Short texts shown around the next pickup.
class PickupCopyHelper {
  /// Home screen headline. In season, today's and tomorrow's pickups get a
  /// seasonal word ("Spooky bin day tomorrow!").
  static String headline(
    PickupDay? next, [
    DateTime? now,
    Season season = Season.none,
  ]) {
    if (next == null) return 'No bins planned yet';
    final days = next.daysUntil(now);
    final big = next.types.length > 1;
    final mood = switch (season) {
      Season.halloween => 'Spooky bin day',
      Season.christmas => 'Jolly bin day',
      Season.none => big ? 'Big bin day' : 'Bin day',
    };
    if (days == 0) return '$mood today!';
    if (days == 1) return '$mood tomorrow!';
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
  static String reminderLine(
    PickupDay day, [
    DateTime? now,
    ReminderSettings settings = ReminderSettings.defaults,
  ]) {
    now ??= DateTime.now();
    final fires = settings.timeFor(day.date);
    final time = formatTime(settings.hour, settings.minute);
    if (fires.isAfter(now)) {
      final days = DateFormatHelper.calculateDaysUntil(fires, now);
      if (days == 0) {
        return fires.hour >= 17
            ? 'Reminder tonight at $time'
            : 'Reminder today at $time';
      }
      if (days == 1) return 'Reminder tomorrow at $time';
      return 'Reminder on ${DateFormatHelper.formatDayName(fires)} at $time';
    }
    // The reminder already fired.
    if (day.daysUntil(now) <= 0) return 'Pickup is today';
    return 'Put the bins out tonight';
  }

  /// "the day before at 7:00 PM", "on pickup day at 6:30 AM".
  static String reminderWhen(ReminderSettings settings) {
    final time = formatTime(settings.hour, settings.minute);
    return settings.dayBefore
        ? 'the day before at $time'
        : 'on pickup day at $time';
  }

  /// 19, 0 -> "7:00 PM"; 6, 30 -> "6:30 AM".
  static String formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m ${hour < 12 ? 'AM' : 'PM'}';
  }

  /// 19 -> "7:00 PM".
  static String formatHour(int hour) => formatTime(hour, 0);
}
