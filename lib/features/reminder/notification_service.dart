import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService() {
    _initialize();
  }

  void _initialize() {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Your launcher icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    _notificationsPlugin.initialize(initializationSettings);
    _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'reminder_channel', // Channel ID
        'Reminders', // Channel name
        description: 'This channel is used for reminder notifications.',
        importance: Importance.high, // Importance level
        playSound: true, // Play sound for notifications
      );

      // Create the channel on the device
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
}) async {
  // Convert the scheduled time to the local timezone
  final tz.TZDateTime scheduledDateTime = tz.TZDateTime.from(
    scheduledTime,
    tz.local,
  );

  await _notificationsPlugin.zonedSchedule(
    id,
    title, // Title of the notification (Reminder title)
    body,  // Body of the notification (Reminder description)
    scheduledDateTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',  // Keep the same channel ID
        'Reminders',         // Channel name
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,    // Disable sound if not needed
        styleInformation: BigTextStyleInformation(''),  // Simplified notification style
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
  );
}





  Future<void> cancelNotification(int id) async {
    // Ensure the ID fits within a 32-bit integer range
    final int validId = id % 2147483647; // Ensure ID is within valid range
    await _notificationsPlugin.cancel(validId);
  }

  Future<void> init() async {
    // Custom initialization logic can be placed here if needed
  }

  Future<void> showHardcodedNotification(int id, String title, String description) async {
  await _notificationsPlugin.show(
    id,
    title, // Use the passed title for the notification
    description, // Use the passed description for the notification
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel', // Ensure this matches your channel ID
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      ),
    ),
  );
}

}