import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wellwiz/features/appointments/app_page.dart';
import 'package:wellwiz/features/emergency/emergency_service.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/reminder/reminder_page.dart';
import 'package:wellwiz/features/reminder/thoughts_service.dart';

class ShortcutsPage extends StatefulWidget {
  const ShortcutsPage({super.key});

  @override
  State<ShortcutsPage> createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final ThoughtsService _thoughtsService = ThoughtsService();

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
    return ListView(
      children: [
        Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Quick ",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromARGB(255, 106, 172, 67)),
              ),
              Text(
                "Access",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 20,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return UserAppointmentsPage(userId: _auth.currentUser?.uid ?? '');
            }));
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Container(
              padding: EdgeInsets.all(20),
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      Icons.collections_bookmark_outlined,
                      size: 40,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          'My ',
                          style: TextStyle(
                              color: Color.fromARGB(255, 106, 172, 67),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text('Bookings',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 18)),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.navigate_next_rounded,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            String userId = _auth.currentUser?.uid ?? ''; // Get the current user's ID
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ReminderPage(userId: userId); // Pass the userId to ReminderPage
            }));
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Container(
              padding: EdgeInsets.all(20),
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      size: 40,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          'My ',
                          style: TextStyle(
                              color: Color.fromARGB(255, 106, 172, 67),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text('Reminders',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 18)),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.navigate_next_rounded,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _pickTimeAndScheduleDailyThought();
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Container(
              padding: EdgeInsets.all(20),
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 40,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          'Daily ',
                          style: TextStyle(
                              color: Color.fromARGB(255, 106, 172, 67),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text('Positivity',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 18)),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.navigate_next_rounded,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return EmergencyScreen();
            }));
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Container(
              padding: EdgeInsets.all(20),
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 40,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          'SOS ',
                          style: TextStyle(
                              color: Color.fromARGB(255, 106, 172, 67),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text('Contacts',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 18)),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.navigate_next_rounded,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Container(
              padding: EdgeInsets.all(20),
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      Icons.power_settings_new_rounded,
                      size: 40,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          'Log ',
                          style: TextStyle(
                              color: Color.fromARGB(255, 106, 172, 67),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text('Out',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 18)),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.navigate_next_rounded,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
