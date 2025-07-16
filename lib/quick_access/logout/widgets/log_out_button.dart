import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/login/login_page.dart';

class LogOutButton extends StatelessWidget {
  const LogOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 30),
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
                  Icons.logout,
                  size: 40,
                  color: Colors.red.shade700,
                ),
                SizedBox(width: 20),
                Text(
                  'Log Out',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 18),
                ),
                Spacer(),
                Icon(
                  Icons.navigate_next_rounded,
                  color: Colors.red.shade700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 