import 'package:workmanager/workmanager.dart';

/// Utility to schedule a notification using WorkManager.
Future<void> createAndScheduleReminder({
  required String userId, // Kept for interface compatibility, but not used
  required String title,
  required String description,
  required DateTime scheduledTime,
}) async {
  // Calculate delay in seconds
  final delay = scheduledTime.difference(DateTime.now()).inSeconds;
  if (delay > 0) {
    await Workmanager().registerOneOffTask(
      'reminder_  ${DateTime.now().millisecondsSinceEpoch}',
      'show_notification_task',
      initialDelay: Duration(seconds: delay),
      inputData: {
        'title': title,
        'body': description,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
} 