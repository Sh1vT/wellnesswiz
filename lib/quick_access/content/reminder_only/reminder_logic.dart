import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/quick_access/content/reminder_only/reminder_model.dart';

class ReminderLogic {
  Future<List<Reminder>> fetchReminders(String userId) async {
    final remindersSnapshot = await FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    return remindersSnapshot.docs.map((doc) {
      return Reminder.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<void> addReminder(String userId, String title, String description, DateTime scheduledTime) async {
    // Add the reminder to Firestore
    await FirebaseFirestore.instance.collection('reminders').add({
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
    });
  }

  Future<void> deleteReminder(String reminderId) async {
    await FirebaseFirestore.instance.collection('reminders').doc(reminderId).delete();
  }
}