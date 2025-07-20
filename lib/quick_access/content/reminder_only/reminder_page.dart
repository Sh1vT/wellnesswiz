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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wellwiz/utils/color_palette.dart';

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
  }

  Future<void> _addReminder(
      String title, String description, DateTime scheduledTime) async {
    print('[DEBUG] _addReminder called with title: $title, description: $description, scheduledTime: $scheduledTime');
    try {
      await _reminderLogic.addReminder(
          widget.userId, title, description, scheduledTime);
      final delay = scheduledTime.difference(DateTime.now()).inSeconds;
      print('[DEBUG] Calculated delay for WorkManager: $delay seconds');
      if (delay > 0) {
        await workmanager_fallback.WorkManagerNotificationFallbackTest().scheduleWorkManagerNotification(
          delay,
          title: title,
          body: description,
        );
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
    await _reminderLogic.deleteReminder(widget.userId, reminder.id);
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
    final now = DateTime.now();
    final upcomingReminders = _reminders.where((r) => r.scheduledTime.isAfter(now)).toList();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Your",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color(0xFF6AAC43)),
              ),
              Text(
                " Reminders",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: ColorPalette.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Color(0xFF6AAC43),
                onPressed: _showAddReminderDialog,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          upcomingReminders.isEmpty
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: ColorPalette.greenSwatch[50]!.withOpacity(0.7),
                      ),
                      child: const Center(
                        child: Text(
                          'Add some reminders!',
                          style: TextStyle(fontFamily: 'Mulish', fontSize: 15, color: ColorPalette.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    itemCount: upcomingReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = upcomingReminders[index];
                      return _ReminderCard(
                        reminder: reminder,
                        onDelete: () => _deleteReminder(reminder),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    String title = '';
    String description = '';
    DateTime? scheduledTime;
    TextEditingController titleController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.grey.shade50,
          title: const Text('Add Reminder', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF212121))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(fontFamily: 'Mulish')),
                controller: titleController,
                style: const TextStyle(fontFamily: 'Mulish'),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(fontFamily: 'Mulish')),
                controller: descController,
                style: const TextStyle(fontFamily: 'Mulish'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6AAC43)),
                  label: Text(
                    scheduledTime == null
                        ? 'Select Date & Time'
                        : '${scheduledTime!.day}/${scheduledTime!.month}/${scheduledTime!.year}  ${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontFamily: 'Mulish', color: Color(0xFF6AAC43), fontWeight: FontWeight.w600),
                  ),
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
                        // Force dialog to rebuild to show selected time
                        (context as Element).markNeedsBuild();
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF6AAC43),
                    textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish', color: Color(0xFF212121))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Color(0xFF6AAC43),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white, fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
              onPressed: () {
                title = titleController.text;
                description = descController.text;
                if (title.isNotEmpty && description.isNotEmpty && scheduledTime != null) {
                  _addReminder(title, description, scheduledTime!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Add ReminderCard widget for card style
class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDelete;
  const _ReminderCard({required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 4),
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
            IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.delete, color: ColorPalette.black, size: 18),
              ),
              onPressed: onDelete,
              tooltip: 'Delete',
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}