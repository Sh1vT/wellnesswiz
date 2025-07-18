import 'package:flutter/material.dart';
import 'package:wellwiz/chat/content/alerts/widgets/emergency_service.dart';

class SosContactsButton extends StatelessWidget {
  const SosContactsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                SizedBox(width: 20),
                Row(
                  children: [
                    Text(
                      'SOS ',
                      style: TextStyle(
                          color: Color.fromARGB(255, 106, 172, 67),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Mulish',
                      ),
                    ),
                    Text('Contacts',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 18,
                            fontFamily: 'Mulish',
                        )),
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