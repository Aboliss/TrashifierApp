import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

class TrashDate {
  final DateTime date;
  final TrashType type;

  TrashDate({required this.date, required this.type});

  factory TrashDate.fromDateTime(DateTime date, TrashType type) {
    return TrashDate(date: date, type: type);
  }

  static List<TrashDate> fromDateList(List<DateTime> dates, TrashType type) {
    return dates.map((date) => TrashDate(date: date, type: type)).toList();
  }

  bool get isToday => DateFormatHelper.isToday(date);
  bool get isFuture => DateFormatHelper.isFuture(date);
  int get daysUntil => DateFormatHelper.calculateDaysUntil(date);
  String get formattedDate => DateFormatHelper.formatDate(date);
  String get dayName => DateFormatHelper.formatDayName(date);
  String get daysUntilText => DateFormatHelper.getDaysUntilText(date);

  bool isSameDate(DateTime other) {
    return DateFormatHelper.isSameDate(date, other);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrashDate &&
        other.type == type &&
        DateFormatHelper.isSameDate(other.date, date);
  }

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day, type);

  @override
  String toString() {
    return 'TrashDate{date: $formattedDate, type: $type}';
  }
}
