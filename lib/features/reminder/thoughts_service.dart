import 'package:workmanager/workmanager.dart';
import 'package:wellwiz/features/reminder/notification_service.dart'; // Import your NotificationService
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:wellwiz/secrets.dart';
import 'package:intl/intl.dart'; // For unique ID generation
import 'package:flutter/material.dart'; // For TimeOfDay

class ThoughtsService {
  late final GenerativeModel _model;
  static const String _apiKey = geminikey; 
  final NotificationService _notificationService = NotificationService(); // Instantiate NotificationService

  ThoughtsService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> fetchPositiveThought() async {
    try {
      String prompt = "Generate a positive thought for the user. Keep it short and.";
      var content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        throw Exception("No response from Gemini API");
      }
    } catch (e) {
      print('Error fetching positive thought: $e');
      return "Keep smiling!";
    }
  }

  String _generateUniqueId() {
    return DateFormat('yyyyMMddHHmmss').format(DateTime.now());
  }

  Future<void> scheduleDailyThoughtNotification(int hour, int minute) async {
  // Calculate the initial delay from the current time to the next occurrence of the selected time
  DateTime now = DateTime.now();
  DateTime nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
  if (nextOccurrence.isBefore(now)) {
    // If the time has already passed today, schedule for the next day
    nextOccurrence = nextOccurrence.add(Duration(days: 1));
  }
  Duration initialDelay = nextOccurrence.difference(now);

  // Register a daily thought task with WorkManager
  await Workmanager().registerPeriodicTask(
    "daily_thought_task", // Give it a fixed name if it's a daily task
    "thoughtTask", // Differentiate from reminder tasks
    frequency: const Duration(days: 1), // Repeats every day
    initialDelay: initialDelay, // Delay before the first occurrence
    inputData: {
      'title': "Positive Thought",
      'description': "Time for a positive thought to brighten your day!"
    },
    existingWorkPolicy: ExistingWorkPolicy.replace, // Replace any existing task with the same ID
  );
}


  Future<void> scheduleTestThoughtNotification() async {
    // Register a one-off task for testing purposes
    await Workmanager().registerOneOffTask(
      "test_thought_task", // A one-time task for testing
      "thoughtTask", // Differentiate from reminder tasks
      initialDelay: const Duration(seconds: 3),
    );
  }
}
