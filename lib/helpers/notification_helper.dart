import 'package:flutter/foundation.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';

/// A reminder that should be pending for a pickup.
class PlannedReminder {
  final int id;
  final TrashType type;
  final DateTime pickupDate;
  final DateTime time;

  const PlannedReminder({
    required this.id,
    required this.type,
    required this.pickupDate,
    required this.time,
  });
}

class RescheduleResult {
  final int scheduled;
  final int failed;
  final bool exact;

  const RescheduleResult({
    required this.scheduled,
    required this.failed,
    required this.exact,
  });
}

class NotificationHelper {
  /// Reminders fire the evening before the pickup at this hour.
  static const int reminderHour = 19;

  /// Spacing between reminders when several bins go out on the same day.
  static const Duration sameDayGap = Duration(seconds: 20);

  /// Android allows at most 500 alarms per app. Everything is re-armed on
  /// every app start and every save, so the nearest reminders are enough.
  static const int maxScheduledReminders = 120;

  static Future<void> _queue = Future.value();

  /// Stable, collision-free ID: yyyymmdd * 10 + type index.
  static int notificationId(DateTime pickupDate, TrashType type) {
    final yyyymmdd =
        pickupDate.year * 10000 + pickupDate.month * 100 + pickupDate.day;
    return yyyymmdd * 10 + type.index;
  }

  /// Reverses [notificationId]; returns null for IDs not created by it.
  static PlannedReminder? decodeNotificationId(int id) {
    final typeIndex = id % 10;
    final yyyymmdd = id ~/ 10;
    if (id < 0 || typeIndex >= TrashType.values.length) return null;
    final year = yyyymmdd ~/ 10000;
    final month = (yyyymmdd ~/ 100) % 100;
    final day = yyyymmdd % 100;
    if (year < 2000 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final pickupDate = DateTime(year, month, day);
    return PlannedReminder(
      id: id,
      type: TrashType.values[typeIndex],
      pickupDate: pickupDate,
      time: reminderTime(pickupDate, 0),
    );
  }

  static DateTime reminderTime(DateTime pickupDate, int indexOnDay) {
    return DateTime(
      pickupDate.year,
      pickupDate.month,
      pickupDate.day - 1,
      reminderHour,
    ).add(sameDayGap * indexOnDay);
  }

  /// Computes every future reminder, soonest first. Bins sharing a pickup
  /// day get reminders [sameDayGap] apart, in [TrashType] order.
  static List<PlannedReminder> planReminders(
    Map<TrashType, List<DateTime>> datesByType, {
    DateTime? now,
    int limit = maxScheduledReminders,
  }) {
    now ??= DateTime.now();

    final typesByDay = <DateTime, Set<TrashType>>{};
    for (final entry in datesByType.entries) {
      for (final date in entry.value) {
        typesByDay
            .putIfAbsent(DateFormatHelper.dateOnly(date), () => {})
            .add(entry.key);
      }
    }

    final days = typesByDay.keys.toList()..sort();
    final reminders = <PlannedReminder>[];

    for (final day in days) {
      final types = typesByDay[day]!.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      for (var i = 0; i < types.length; i++) {
        final time = reminderTime(day, i);
        if (!time.isAfter(now)) continue;
        reminders.add(
          PlannedReminder(
            id: notificationId(day, types[i]),
            type: types[i],
            pickupDate: day,
            time: time,
          ),
        );
        if (reminders.length >= limit) return reminders;
      }
    }
    return reminders;
  }

  /// Makes the scheduled reminders match [datesByType] exactly.
  ///
  /// Every planned reminder is (re)armed even if the plugin thinks it is
  /// still pending: Android drops alarms when the app is force-stopped or
  /// updated, and the plugin's pending list doesn't notice. Re-arming an
  /// existing ID just replaces the alarm. Calls are serialized.
  static Future<RescheduleResult> rescheduleAll(
    Map<TrashType, List<DateTime>> datesByType,
  ) {
    final result = _queue.then((_) => _rescheduleAll(datesByType));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  static Future<RescheduleResult> _rescheduleAll(
    Map<TrashType, List<DateTime>> datesByType,
  ) async {
    final plan = planReminders(datesByType);
    final plannedIds = plan.map((r) => r.id).toSet();

    // Cancel individually rather than cancelAll(), which would also clear a
    // reminder that is currently displayed in the notification shade.
    final pending = await NotificationService.getPendingNotifications();
    for (final notification in pending) {
      if (!plannedIds.contains(notification.id)) {
        await NotificationService.cancelNotification(notification.id);
      }
    }

    final exact = await NotificationService.canScheduleExactAlarms();
    var scheduled = 0;
    var failed = 0;

    for (final reminder in plan) {
      try {
        await NotificationService.scheduleNotification(
          reminder.id,
          TrashTypeHelper.getNotificationTitle(reminder.type),
          TrashTypeHelper.getNotificationBody(reminder.type),
          reminder.time,
          exact: exact,
        );
        scheduled++;
      } catch (e) {
        failed++;
        debugPrint('Failed to schedule reminder ${reminder.id}: $e');
      }
    }

    return RescheduleResult(scheduled: scheduled, failed: failed, exact: exact);
  }
}
