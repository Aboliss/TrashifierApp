import 'package:intl/intl.dart';
import 'package:trashifier_app/l10n/l10n.dart';

class DateFormatHelper {
  /// A pickup on the current day still counts as upcoming until this hour.
  static const int pickupCutoffHour = 8;

  // Formats follow the app language (L10n.localeName).

  /// "Oct 20", "20. Okt.", "20 oct", "20. 10.".
  static String formatDate(DateTime date) =>
      DateFormat.MMMd(L10n.localeName).format(date);

  /// "Oct 2026".
  static String formatMonthYear(DateTime date) =>
      DateFormat.yMMM(L10n.localeName).format(date);

  /// "October" on its own, e.g. above a month grid.
  static String formatMonthName(DateTime date) =>
      _capitalize(DateFormat.LLLL(L10n.localeName).format(date));

  /// "Tuesday".
  static String formatDayName(DateTime date) =>
      DateFormat.EEEE(L10n.localeName).format(date);

  /// "Tue".
  static String formatShortDayName(DateTime date) =>
      DateFormat.E(L10n.localeName).format(date);

  /// "T"; for narrow day headers.
  static String formatDayLetter(DateTime date) =>
      DateFormat.EEEEE(L10n.localeName).format(date).toUpperCase();

  /// "Tuesday, Oct 20", "Dienstag, 20. Okt.", "Martes, 20 oct"; capitalized
  /// because it starts a line (Spanish and Slovak weekdays are lowercase).
  static String formatFullDate(DateTime date) =>
      _capitalize('${formatDayName(date)}, ${formatDate(date)}');

  /// "Tue, Oct 20".
  static String formatShortDate(DateTime date) =>
      _capitalize(DateFormat.MMMEd(L10n.localeName).format(date));

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  /// "19:00" or "7:00 PM", following the phone's 24-hour setting (not the
  /// language).
  static String formatTime(int hour, int minute) {
    final time = DateTime(2000, 1, 1, hour, minute);
    if (L10n.use24HourFormat) {
      return DateFormat.Hm(L10n.localeName).format(time);
    }
    return DateFormat('h:mm a', L10n.localeName)
        .format(time)
        // Some locales put a narrow no-break space before AM/PM.
        .replaceAll('\u202F', ' ');
  }

  /// Strips the time (and any UTC flag) and returns local midnight of the
  /// same calendar day. Pickup dates are calendar days, not instants.
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int calculateDaysUntil(DateTime date, [DateTime? now]) {
    now ??= DateTime.now();
    // Compare in UTC so DST transitions (23h/25h days) don't skew the count.
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDate = DateTime.utc(date.year, date.month, date.day);
    return targetDate.difference(today).inDays;
  }

  /// "Today", "Tomorrow", "in 5 days".
  static String getDaysUntilText(DateTime date) {
    final daysUntil = calculateDaysUntil(date);
    if (daysUntil == 0) return L10n.current.today;
    if (daysUntil == 1) return L10n.current.tomorrow;
    return L10n.current.inDaysBadge(daysUntil);
  }

  static bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDate(date, DateTime.now());
  }

  /// Whether a pickup on [date] is still upcoming: any later calendar day,
  /// or today before [pickupCutoffHour].
  static bool isFuture(DateTime date, [DateTime? now]) {
    now ??= DateTime.now();
    final daysUntil = calculateDaysUntil(date, now);
    if (daysUntil > 0) return true;
    return daysUntil == 0 && now.hour < pickupCutoffHour;
  }
}
