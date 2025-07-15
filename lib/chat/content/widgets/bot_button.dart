import 'package:flutter/material.dart';
import 'package:wellwiz/chat/content/widgets/bot_screen.dart';

class BotButton extends StatelessWidget {
  const BotButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const BotScreen();
        }));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12))),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat with Wisher',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Color.fromARGB(255, 106, 172, 67),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    height: 2.0,
                    width: 180.0,
                    color: Colors.grey.shade800,
                  ),
                  Text(
                    'Your personal medical assistant',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      fontFamily: 'Mulish',
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 