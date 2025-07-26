import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:wellwiz/quick_access/content/reminder_only/thoughts_service.dart';

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
    //print('[DEBUG] WorkManager: callbackDispatcher started');
    //print('[DEBUG] Task name: $task');
    //print('[DEBUG] Input data: $inputData');
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);
    //print('[DEBUG] WorkManager: plugin initialized');
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.high,
      );
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      //print('[DEBUG] WorkManager: channel created');
    }
    String notifTitle = inputData?['title'] ?? 'WorkManager Notification';
    String notifBody = inputData?['body'] ?? 'This notification was scheduled using WorkManager.';
    if (task == 'thoughtTask') {
      //print('[DEBUG] thoughtTask branch entered');
      notifTitle = 'Positive Thought';
      notifBody = inputData?['description'] ?? ThoughtsService.getRandomThought();
      //print('[DEBUG] Chosen thought for notification: $notifBody');
      // Reschedule for the next day at the same time
      int hour = int.tryParse(inputData?['hour'] ?? '') ?? 8;
      int minute = int.tryParse(inputData?['minute'] ?? '') ?? 0;
      await ThoughtsService.rescheduleDailyThought(hour, minute);
    }
    await plugin.show(
      30001,
      notifTitle,
      notifBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(notifBody),
        ),
      ),
    );
    //print('[DEBUG] WorkManager: plugin.show called');
    return Future.value(true);
  });
}

class WorkManagerNotificationFallbackTest extends StatelessWidget {
  const WorkManagerNotificationFallbackTest({super.key});

  Future<void> scheduleWorkManagerNotification(int seconds, {String? title, String? body}) async {
    //print('[DEBUG] Scheduling WorkManager notification for $seconds seconds from now');
    await Workmanager().registerOneOffTask(
      'unique_task_${DateTime.now().millisecondsSinceEpoch}',
      workmanagerTaskName,
      initialDelay: Duration(seconds: seconds),
      inputData: {
        'title': title ?? 'WorkManager Notification',
        'body': body ?? 'This notification was scheduled $seconds seconds ago (WorkManager fallback).',
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    //print('[DEBUG] WorkManager task registered');
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