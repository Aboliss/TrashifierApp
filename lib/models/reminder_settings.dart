/// When pickup reminders fire: [daysBefore] the pickup (1 = the day before,
/// 0 = pickup day) at [hour]:[minute] local time.
class ReminderSettings {
  final int daysBefore;
  final int hour;
  final int minute;

  const ReminderSettings({
    this.daysBefore = 1,
    this.hour = 19,
    this.minute = 0,
  });

  /// The evening before at 19:00, as before reminders were adjustable.
  static const ReminderSettings defaults = ReminderSettings();

  /// Builds settings from stored values; anything missing or out of range
  /// falls back to [defaults] field by field.
  factory ReminderSettings.validated({
    int? daysBefore,
    int? hour,
    int? minute,
  }) {
    return ReminderSettings(
      daysBefore: daysBefore == 0 || daysBefore == 1
          ? daysBefore!
          : defaults.daysBefore,
      hour: hour != null && hour >= 0 && hour <= 23 ? hour : defaults.hour,
      minute: minute != null && minute >= 0 && minute <= 59
          ? minute
          : defaults.minute,
    );
  }

  bool get dayBefore => daysBefore == 1;

  /// The local time the reminder for a pickup on [pickupDate] fires.
  DateTime timeFor(DateTime pickupDate) {
    return DateTime(
      pickupDate.year,
      pickupDate.month,
      pickupDate.day - daysBefore,
      hour,
      minute,
    );
  }

  ReminderSettings copyWith({int? daysBefore, int? hour, int? minute}) {
    return ReminderSettings.validated(
      daysBefore: daysBefore ?? this.daysBefore,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.daysBefore == daysBefore &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(daysBefore, hour, minute);

  @override
  String toString() =>
      'ReminderSettings(daysBefore: $daysBefore, $hour:$minute)';
}
