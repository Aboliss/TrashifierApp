import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/l10n/l10n.dart';
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
    final l = L10n.current;
    if (next == null) return l.headlineNothingPlanned;
    final days = next.daysUntil(now);
    final big = next.types.length > 1;
    final mood = switch (season) {
      Season.halloween => l.moodSpooky,
      Season.christmas => l.moodJolly,
      Season.none => big ? l.moodBig : l.moodNormal,
    };
    if (days == 0) return l.headlineToday(mood);
    if (days == 1) return l.headlineTomorrow(mood);
    if (days < 7) {
      return l.headlineThisWeek(DateFormatHelper.formatDayName(next.date));
    }
    return l.headlineQuietWeek;
  }

  /// "Today", "Tomorrow", "In 5 days", "Yesterday", "3 days ago".
  static String relativeDay(DateTime date, [DateTime? now]) {
    final l = L10n.current;
    final days = DateFormatHelper.calculateDaysUntil(date, now);
    if (days == 0) return l.today;
    if (days == 1) return l.tomorrow;
    if (days == -1) return l.yesterday;
    if (days > 1) return l.inDays(days);
    return l.daysAgo(-days);
  }

  /// When the reminder for [day] fires, relative to [now].
  static String reminderLine(
    PickupDay day, [
    DateTime? now,
    ReminderSettings settings = ReminderSettings.defaults,
  ]) {
    final l = L10n.current;
    now ??= DateTime.now();
    final fires = settings.timeFor(day.date);
    final time = formatTime(settings.hour, settings.minute);
    if (fires.isAfter(now)) {
      final days = DateFormatHelper.calculateDaysUntil(fires, now);
      if (days == 0) {
        return fires.hour >= 17
            ? l.reminderTonight(time)
            : l.reminderToday(time);
      }
      if (days == 1) return l.reminderTomorrow(time);
      return l.reminderOnDay(DateFormatHelper.formatDayName(fires), time);
    }
    // The reminder already fired.
    if (day.daysUntil(now) <= 0) return l.pickupIsToday;
    return l.putBinsOutTonight;
  }

  /// The hint on the empty Next pickup card.
  static String emptyCardHint(ReminderSettings settings) {
    final time = formatTime(settings.hour, settings.minute);
    return settings.dayBefore
        ? L10n.current.emptyCardHintDayBefore(time)
        : L10n.current.emptyCardHintPickupDay(time);
  }

  /// "2 reminders the day before at 7:00 PM, one per bin."
  static String dayReminders(int count, ReminderSettings settings) {
    final time = formatTime(settings.hour, settings.minute);
    return settings.dayBefore
        ? L10n.current.dayRemindersDayBefore(count, time)
        : L10n.current.dayRemindersPickupDay(count, time);
  }

  /// 19, 0 -> "7:00 PM" (English) or "19:00".
  static String formatTime(int hour, int minute) =>
      DateFormatHelper.formatTime(hour, minute);

  /// 19 -> "7:00 PM".
  static String formatHour(int hour) => formatTime(hour, 0);
}
