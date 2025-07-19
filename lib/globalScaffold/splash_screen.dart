import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.jpeg',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'WellWiz',
              style: TextStyle(
                fontFamily: 'Mulish',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7CB518),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your all-in-one medical assistant',
              style: TextStyle(
                fontFamily: 'Mulish',
                fontSize: 16,
                color: Colors.black54,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 