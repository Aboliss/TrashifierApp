import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:trashifier_app/constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _reminderDetails =
      AndroidNotificationDetails(
        'reminder_channel',
        'Reminder Channel',
        channelDescription: 'Channel for trash collection reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  static Future<void> onDidReceiveNotification(
    NotificationResponse notificationResponse,
  ) async {}

  static Future<void> init() async {
    // Reminder times are computed as local DateTimes and converted to an
    // absolute instant (see scheduleNotification), so only the UTC zone is
    // needed; no device timezone lookup is required.
    tzdata.initializeTimeZones();

    const AndroidNotificationChannel instantChannel =
        AndroidNotificationChannel(
          'instant_notification_channel_id',
          'Instant Notifications',
          description: 'Channel for instant notifications',
          importance: Importance.max,
          playSound: true,
        );
    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
          'reminder_channel',
          'Reminder Channel',
          description: 'Channel for trash collection reminders',
          importance: Importance.high,
          playSound: true,
        );

    try {
      await _android?.createNotificationChannel(instantChannel);
      await _android?.createNotificationChannel(reminderChannel);
    } catch (e) {
      debugPrint('Failed to create notification channels: $e');
    }

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotification,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
      );
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }

    try {
      await _android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('${AppConstants.notificationPermissionError}: $e');
    }

    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('${AppConstants.exactAlarmPermissionError}: $e');
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    return await _android?.areNotificationsEnabled() ?? false;
  }

  static Future<bool> canScheduleExactAlarms() async {
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_notification_channel_id',
        'Instant Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'instant_notification',
    );
  }

  /// Schedules a notification at [scheduledTime] (a local or UTC DateTime).
  ///
  /// When [exact] is false (exact alarms not permitted) the reminder is still
  /// scheduled, but Android may deliver it a little late.
  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    bool exact = true,
  }) async {
    try {
      // TZDateTime.from keeps the absolute instant; using UTC avoids depending
      // on tz.local, which the timezone package leaves at UTC anyway.
      final scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.UTC);

      if (scheduledTZTime.isBefore(tz.TZDateTime.now(tz.UTC))) {
        return;
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZTime,
        const NotificationDetails(android: _reminderDetails),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      throw Exception('${AppConstants.notificationSchedulingError}: $e');
    }
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
