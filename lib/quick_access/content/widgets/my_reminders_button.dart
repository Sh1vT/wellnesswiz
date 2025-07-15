import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/quick_access/content/widgets/reminder_page.dart';

class MyRemindersButton extends StatelessWidget {
  const MyRemindersButton({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    return GestureDetector(
      onTap: () {
        String userId = _auth.currentUser?.uid ?? '';
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ReminderPage(userId: userId);
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
                SizedBox(width: 20),
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
    );
  }
} 