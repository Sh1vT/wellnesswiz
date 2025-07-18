import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/doctor/content/docs/widgets/app_page.dart';

class MyBookingsButton extends StatelessWidget {
  const MyBookingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    return GestureDetector(
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
                SizedBox(width: 20),
                Row(
                  children: [
                    Text(
                      'My ',
                      style: TextStyle(
                          color: Color.fromARGB(255, 106, 172, 67),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Mulish',
                      ),
                    ),
                    Text('Bookings',
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