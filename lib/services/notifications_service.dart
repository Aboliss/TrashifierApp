import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {}

  static Future<void> init() async {
    // Initialize timezones
    tzdata.initializeTimeZones();

    // Set the local timezone - use a more robust approach
    try {
      // Try to get local timezone, fallback to UTC if it fails
      tz.setLocalLocation(tz.local);
      print('Timezones initialized with local timezone: ${tz.local.name}');
    } catch (e) {
      print('Failed to set local timezone, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android notification channels
    const AndroidNotificationChannel instantChannel = AndroidNotificationChannel('instant_notification_channel_id', 'Instant Notifications', description: 'Channel for instant notifications', importance: Importance.max, playSound: true);

    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel('reminder_channel', 'Reminder Channel', description: 'Channel for trash collection reminders', importance: Importance.high, playSound: true);

    // Create notification channels
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(instantChannel);

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(reminderChannel);

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings("@mipmap/ic_launcher");
    const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings, iOS: iOSInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotification, onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification);

    // Request permissions sequentially to avoid conflicts
    try {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      print('Notification permission requested');
    } catch (e) {
      print('Error requesting notification permission: $e');
    }

    try {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
      print('Exact alarms permission requested');
    } catch (e) {
      print('Error requesting exact alarms permission: $e');
    }

    print('Notification plugin initialized with channels created');
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails('instant_notification_channel_id', 'Instant Notifications', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: 'instant_notification');
    print('Instant notification shown: $title - $body');
  }

  static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    print('Scheduling notification: id=$id, title=$title, body=$body, scheduledTime=$scheduledTime');

    try {
      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.local);
      print('Scheduled TZ time: $scheduledTZTime');
      print('Current time: ${tz.TZDateTime.now(tz.local)}');

      // Check if the scheduled time is in the future
      if (scheduledTZTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Warning: Scheduled time is in the past. Notification will not be scheduled.');
        return;
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZTime,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails('reminder_channel', 'Reminder Channel', channelDescription: 'Channel for trash collection reminders', importance: Importance.high, priority: Priority.high, playSound: true, enableVibration: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Successfully scheduled notification: id=$id');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Cancelled notification: id=$id');
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('Cancelled all notifications');
  }
}
