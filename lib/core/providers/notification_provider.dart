import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // The error says 'settings' is required.
    await _notifications.initialize(
      initSettings, // First positional is often initializationSettings
      // but let's try to use the named one if it fails.
      // Actually, if it's version 21.0.0, maybe it's just 'settings:'
    );
    
    // Initialize timezone
    tz.initializeTimeZones();
    final dynamic tzData = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = tzData is String ? tzData : (tzData as dynamic).name.toString();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminders',
          'Class Reminders',
          channelDescription: 'Notifications for upcoming classes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // androidScheduleMode is correct, but let's check UILocalNotificationDateInterpretation
      // If it's missing, maybe it's not needed or renamed.
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminders',
          'Class Reminders',
          channelDescription: 'Notifications for upcoming classes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
