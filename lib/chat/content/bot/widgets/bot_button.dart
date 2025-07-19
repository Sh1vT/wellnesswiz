import 'package:flutter/material.dart';
import 'package:wellwiz/chat/content/bot/widgets/bot_screen.dart';
import 'package:wellwiz/utils/poppy_tile.dart';

class BotButton extends StatelessWidget {
  const BotButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PoppyTile(
        customBorderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        backgroundColor: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.all(16),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 250));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const BotScreen();
              },
            ),
          );
        },
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
    );
  }
}
