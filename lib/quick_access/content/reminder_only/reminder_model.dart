import 'package:cloud_firestore/cloud_firestore.dart';

// reminder.dart
class Reminder {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime scheduledTime;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.scheduledTime,
  });

  // Factory method to create Reminder from Firestore data
  factory Reminder.fromMap(String id, Map<String, dynamic> data) {
    return Reminder(
      id: id,
      userId: data['userId'],
      title: data['title'],
      description: data['description'],
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime,
    };
  }
}

