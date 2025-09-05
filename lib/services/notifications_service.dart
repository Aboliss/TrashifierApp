import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {}

  static Future<void> init() async {
    // Initialize timezones
    tzdata.initializeTimeZones();
    print('Timezones initialized');

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings("@mipmap/ic_launcher");
    const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings, iOS: iOSInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotification, onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification);

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    print('Notification plugin initialized');
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
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails('reminder_channel', 'Reminder Channel', importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    print('Scheduled notification: id=$id');
  }
}
