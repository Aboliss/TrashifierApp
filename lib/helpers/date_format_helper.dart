class DateFormatHelper {
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

  static int calculateDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
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

  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return true;
    } else if (isSameDate(date, now)) {
      return now.hour < 8;
    }
    return false;
  }
}
