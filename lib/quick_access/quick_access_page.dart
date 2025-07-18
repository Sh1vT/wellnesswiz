import 'package:flutter/material.dart';
import 'package:wellwiz/quick_access/content/account/widgets/my_account_button.dart';
import 'package:wellwiz/quick_access/content/account/widgets/quick_access_title.dart';
import 'package:wellwiz/quick_access/content/bookings/widgets/my_bookings_button.dart';
import 'package:wellwiz/quick_access/content/reminder_only/thoughts_service.dart';
import 'package:wellwiz/quick_access/content/logout/widgets/log_out_button.dart';
import 'package:wellwiz/quick_access/content/positivity/widgets/daily_positivity_button.dart';
import 'package:wellwiz/quick_access/content/reminders/widgets/my_reminders_button.dart';
import 'package:wellwiz/quick_access/content/sos/widgets/sos_contacts_button.dart';
import 'content/account/account_page.dart';

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
        MyAccountButton(onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPage()));
        }),
        const MyBookingsButton(),
        const MyRemindersButton(),
        DailyPositivityButton(onTap: _pickTimeAndScheduleDailyThought),
        SosContactsButton(),
        LogOutButton(),
      ],
    );
  }
}
