import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/features/reminder/reminder_model.dart';
import 'notification_service.dart';
import 'package:workmanager/workmanager.dart';

class ReminderLogic {
  final NotificationService _notificationService = NotificationService();

  Future<List<Reminder>> fetchReminders(String userId) async {
    final remindersSnapshot = await FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    return remindersSnapshot.docs.map((doc) {
      return Reminder.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> addReminder(String userId, String title, String description, DateTime scheduledTime) async {
    // Add the reminder to Firestore
    DocumentReference docRef = await FirebaseFirestore.instance.collection('reminders').add({
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
    });

    final int validId = docRef.id.hashCode % 2147483647; // Ensure ID is within valid range

    // Schedule the notification using WorkManager
    await Workmanager().registerOneOffTask(
  validId.toString(), // Use a unique identifier
  'reminderTask', // Task name
  inputData: {
    'id': validId,
    'title': title, // Pass the title of the reminder
    'description': description, // Pass the description of the reminder
  },
  initialDelay: scheduledTime.difference(DateTime.now()).inMilliseconds > 0
      ? scheduledTime.difference(DateTime.now())
      : Duration.zero,
  existingWorkPolicy: ExistingWorkPolicy.replace, // Replace any existing task with the same ID
);

  }

  Future<void> deleteReminder(String reminderId) async {
    await FirebaseFirestore.instance.collection('reminders').doc(reminderId).delete();
    final int validId = reminderId.hashCode % 2147483647; // Ensure ID is within valid range
    await Workmanager().cancelByUniqueName(validId.toString()); // Cancel the WorkManager task
  }

  Future<void> scheduleReminders(List<Reminder> reminders) async {
    for (final reminder in reminders) {
      Timestamp scheduledTimestamp = reminder.scheduledTime as Timestamp;
      DateTime scheduledDateTime = scheduledTimestamp.toDate();

      final int validId = reminder.hashCode % 2147483647; // Ensure ID is within valid range

      // Schedule each reminder using WorkManager
      await Workmanager().registerOneOffTask(
        validId.toString(),
        'reminderTask',
        inputData: {
          'id': validId,
          'title': reminder.title,
          'description': reminder.description,
          'scheduledTime': scheduledDateTime.millisecondsSinceEpoch
        },
        initialDelay: scheduledDateTime.difference(DateTime.now()).inMilliseconds > 0
            ? scheduledDateTime.difference(DateTime.now())
            : Duration.zero,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }
  }
}