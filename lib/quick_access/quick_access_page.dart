import 'package:flutter/material.dart';
import 'package:wellwiz/quick_access/content/reminder_only/thoughts_service.dart';
import 'content/widgets/quick_access_title.dart';
import 'content/widgets/my_bookings_button.dart';
import 'content/widgets/my_reminders_button.dart';
import 'content/widgets/daily_positivity_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'content/widgets/sos_contacts_button.dart';
import 'content/widgets/log_out_button.dart';

class QuickAccessPage extends StatefulWidget {
  const QuickAccessPage({super.key});

  @override
  State<QuickAccessPage> createState() => _QuickAccessPageState();
}

class _QuickAccessPageState extends State<QuickAccessPage> {
  final ThoughtsService _thoughtsService = ThoughtsService();

  Future<void> _pickTimeAndScheduleDailyThought() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      helpText: "Choose time for daily positive thoughts!",
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color.fromRGBO(106, 172, 67, 1),
            colorScheme: ColorScheme.light(primary: Color.fromRGBO(106, 172, 67, 1)),
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
              "Daily positive thought scheduled for "+selectedTime.format(context)+"!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const QuickAccessTitle(),
        const SizedBox(height: 20),
        const MyBookingsButton(),
        const MyRemindersButton(),
        DailyPositivityButton(onTap: _pickTimeAndScheduleDailyThought),
        SosContactsButton(),
        LogOutButton(),
      ],
    );
  }
}
