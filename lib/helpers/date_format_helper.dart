class DateFormatHelper {
  /// A pickup on the current day still counts as upcoming until this hour.
  static const int pickupCutoffHour = 8;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}';
  }

  static String formatDayName(DateTime date) {
    return _weekdays[date.weekday - 1];
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

  static String getDaysUntilText(DateTime date) {
    final daysUntil = calculateDaysUntil(date);
    if (daysUntil == 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    return 'in $daysUntil days';
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
