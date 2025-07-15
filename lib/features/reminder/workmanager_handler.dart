import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wellwiz/firebase_options.dart';
import 'package:wellwiz/features/reminder/notification_service.dart';
import 'package:wellwiz/features/reminder/thoughts_service.dart';

const String reminderTaskName = 'reminderTask';
const String thoughtTaskName = 'thoughtTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Required: Ensure widgets are initialized
    WidgetsFlutterBinding.ensureInitialized();
    print('workmanager_handler: Firebase.apps.length = ${Firebase.apps.length}');
    if (Firebase.apps.isEmpty) {
      print('workmanager_handler: Initializing Firebase');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('workmanager_handler: Firebase initialized');
    } else {
      print('workmanager_handler: Firebase already initialized');
    }

    // Services
    final notificationService = NotificationService();
    final thoughtsService = ThoughtsService();

    if (task == reminderTaskName) {
      // Reminder task handling
      final int id = inputData!['id'];
      final String title = inputData['title'];
      final String description = inputData['description'];

      await notificationService.showHardcodedNotification(
          id, title, description);
    } else if (task == thoughtTaskName) {
      // Thought task handling
      final thought = await thoughtsService.fetchPositiveThought();

      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await notificationService.showHardcodedNotification(
          id, "Thought for Today", thought);
    }

    return Future.value(true);
  });
}
