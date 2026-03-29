import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
  }

  Future<void> scheduleWeeklyNotification(
    String id,
    String title,
    String body,
  ) async {
    final int nid = id.hashCode & 0x7fffffff;

    final now = tz.TZDateTime.now(tz.local);
    // schedule for next occurrence at 09:00 local time
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    const androidDetails = AndroidNotificationDetails(
      'smartfinance_reminder',
      'SmartFinance Reminders',
      channelDescription: 'Weekly reminders and tips',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      nid,
      title,
      body,
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iOSDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
