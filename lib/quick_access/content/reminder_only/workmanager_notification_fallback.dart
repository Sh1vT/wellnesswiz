import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// INSTRUCTIONS:
// 1. If you change the WorkManager callback or notification channel, do a full restart (not just hot reload).
// 2. If you change the channel ID, uninstall and reinstall the app.
// 3. If you change only the UI, hot reload is fine.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(MaterialApp(
    home: WorkManagerNotificationFallbackTest(),
  ));
}

const String workmanagerTaskName = 'show_notification_task';
const String channelId = 'workmanager_channel_v2';
const String channelName = 'WorkManager Channel V2';
const String channelDesc = 'Channel for WorkManager fallback notifications (v2).';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('[DEBUG] WorkManager: callbackDispatcher started');
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);
    print('[DEBUG] WorkManager: plugin initialized');
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.high,
      );
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      print('[DEBUG] WorkManager: channel created');
    }
    await plugin.show(
      30001,
      inputData?['title'] ?? 'WorkManager Notification',
      inputData?['body'] ?? 'This notification was scheduled using WorkManager.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
    print('[DEBUG] WorkManager: plugin.show called');
    return Future.value(true);
  });
}

class WorkManagerNotificationFallbackTest extends StatelessWidget {
  Future<void> scheduleWorkManagerNotification(int seconds) async {
    print('[DEBUG] Scheduling WorkManager notification for $seconds seconds from now');
    await Workmanager().registerOneOffTask(
      'unique_task_${DateTime.now().millisecondsSinceEpoch}',
      workmanagerTaskName,
      initialDelay: Duration(seconds: seconds),
      inputData: {
        'title': 'WorkManager Notification',
        'body': 'This notification was scheduled $seconds seconds ago (WorkManager fallback).',
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    print('[DEBUG] WorkManager task registered');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WorkManager Notification Fallback Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await scheduleWorkManagerNotification(10);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Scheduled WorkManager notification for 10 seconds from now.')),
                );
              },
              child: Text('Schedule WorkManager Notification (10 sec)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await scheduleWorkManagerNotification(120);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Scheduled WorkManager notification for 2 minutes from now.')),
                );
              },
              child: Text('Schedule WorkManager Notification (2 min)'),
            ),
          ],
        ),
      ),
    );
  }
} 