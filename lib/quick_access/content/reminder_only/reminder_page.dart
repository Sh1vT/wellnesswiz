import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/quick_access/content/reminder_only/reminder_model.dart';
import 'package:wellwiz/quick_access/content/reminder_only/thoughts_service.dart';
import 'reminder_logic.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:wellwiz/quick_access/content/reminder_only/workmanager_notification_fallback.dart' as workmanager_fallback;

class ReminderPage extends StatefulWidget {
  final String userId;

  const ReminderPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderLogic _reminderLogic = ReminderLogic();
  final ThoughtsService _thoughtsService = ThoughtsService();
  List<Reminder> _reminders = [];
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchReminders();
    _getUserInfo();
  }

  Future<void> _fetchReminders() async {
    final reminders = await _reminderLogic.fetchReminders(widget.userId);
    setState(() {
      _reminders = reminders;
    });
    // Removed: await _reminderLogic.scheduleReminders(_reminders);
  }

  Future<void> _addReminder(
      String title, String description, DateTime scheduledTime) async {
    print('[DEBUG] _addReminder called with title: $title, description: $description, scheduledTime: $scheduledTime');
    try {
      await _reminderLogic.addReminder(
          widget.userId, title, description, scheduledTime);
      print('[DEBUG] Reminder added to Firestore');
      // Schedule WorkManager notification fallback
      final delay = scheduledTime.difference(DateTime.now()).inSeconds;
      print('[DEBUG] Calculated delay for WorkManager: $delay seconds');
      if (delay > 0) {
        await workmanager_fallback.WorkManagerNotificationFallbackTest().scheduleWorkManagerNotification(delay);
        print('[DEBUG] WorkManager notification scheduled');
      } else {
        print('[DEBUG] Delay not positive, notification not scheduled');
      }
      _fetchReminders();
    } catch (e) {
      print('[DEBUG] Error in _addReminder: $e');
      // Show a generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add reminder: \\${e.toString()}')),
      );
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await _reminderLogic.deleteReminder(reminder.id);
    _fetchReminders();
  }

  Future<void> _pickTimeAndScheduleDailyThought() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      helpText: "Choose time for daily positive thoughts!",
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color.fromRGBO(
                106, 172, 67, 1), // Change the primary color to green
            colorScheme: ColorScheme.light(
                primary:
                    Color.fromRGBO(106, 172, 67, 1)), // Change color scheme
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final int hour = selectedTime.hour;
      final int minute = selectedTime.minute;

      await _thoughtsService.scheduleDailyThoughtNotification(hour, minute);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Daily positive thought scheduled for ${selectedTime.format(context)}!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Row(
            children: [
              IconButton(
                  onPressed: _pickTimeAndScheduleDailyThought,
                  icon: Icon(Icons.schedule_rounded)),
              SizedBox(
                width: 10,
              )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Title section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Your",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromRGBO(106, 172, 67, 1)),
              ),
              Text(
                " Reminders",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Replace the fixed height Container with Expanded
          Expanded(
  child: _reminders.isEmpty
      ? ListView.builder(
          itemCount: 1, // Show just one item
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Container(
                height: 80, // Set height similar to regular tiles
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: Text(
                    'Add some reminders!',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            );
          },
        )
      : ListView.builder(
          itemCount: _reminders.length,
          itemBuilder: (context, index) {
            final reminder = _reminders[index];

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  trailing: IconButton(
                    icon: Icon(Icons.delete,
                        color: Colors.grey.shade700),
                    onPressed: () => _deleteReminder(reminder),
                  ),
                  leading: Icon(
                    Icons.alarm,
                    size: 30,
                    color: Color.fromRGBO(106, 172, 67, 1),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: const TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${DateFormat.yMMMd().add_jm().format(reminder.scheduledTime)}',
                        style: const TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
),



          // Add reminder button
          Padding(
            padding: const EdgeInsets.all(16), // Add padding for better spacing
            child: Container(
              height: 42,
              width: 42,
              child: IconButton(
                color: Colors.green.shade500,
                onPressed: () {
                  _showAddReminderDialog(); // Open dialog to add reminder
                },
                icon: const Icon(
                  Icons.add,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      // Remove floatingActionButton
    );
  }

  void _showAddReminderDialog() async {
    print('[DEBUG] _showAddReminderDialog called');
    // Request notification permission first
    final status = await Permission.notification.request();
    print('[DEBUG] Notification permission status: \\${status.toString()}');
    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Permission Required'),
          content: const Text('Please enable notifications to receive reminders.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      print('[DEBUG] Notification permission not granted, dialog shown');
      return;
    }
    String title = '';
    String description = '';
    DateTime? scheduledTime;
    TextEditingController titleController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                controller: titleController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: descController,
              ),
              TextButton(
                child: const Text('Select Date & Time'),
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (selectedDate != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selectedTime != null) {
                      scheduledTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      print('[DEBUG] User selected scheduledTime: $scheduledTime');
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                setState(() {
                  title = titleController.text;
                  description = descController.text;
                });
                print('[DEBUG] Add button pressed with title: $title, description: $description, scheduledTime: $scheduledTime');
                if (title.isNotEmpty &&
                    description.isNotEmpty &&
                    scheduledTime != null) {
                  _addReminder(title, description, scheduledTime!);
                  Navigator.of(context).pop();
                } else {
                  print('[DEBUG] Invalid input, reminder not added');
                }
              },
            ),
          ],
        );
      },
    );
  }
}