import 'package:wellwiz/quick_access/content/reminder_only/reminder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReminderLogic {
  static String _reminderKey(String userId) => 'reminders_$userId';

  Future<List<Reminder>> fetchReminders(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_reminderKey(userId));
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((e) => Reminder(
      id: e['id'],
      userId: e['userId'],
      title: e['title'],
      description: e['description'],
      scheduledTime: DateTime.parse(e['scheduledTime']),
    )).toList();
  }

  Future<void> addReminder(String userId, String title, String description, DateTime scheduledTime) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await fetchReminders(userId);
    final newReminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      description: description,
      scheduledTime: scheduledTime,
    );
    reminders.add(newReminder);
    await prefs.setString(_reminderKey(userId), json.encode(reminders.map((r) => {
      'id': r.id,
      'userId': r.userId,
      'title': r.title,
      'description': r.description,
      'scheduledTime': r.scheduledTime.toIso8601String(),
    }).toList()));
  }

  Future<void> deleteReminder(String userId, String reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await fetchReminders(userId);
    reminders.removeWhere((r) => r.id == reminderId);
    await prefs.setString(_reminderKey(userId), json.encode(reminders.map((r) => {
      'id': r.id,
      'userId': r.userId,
      'title': r.title,
      'description': r.description,
      'scheduledTime': r.scheduledTime.toIso8601String(),
    }).toList()));
  }
}