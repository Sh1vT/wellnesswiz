import 'package:flutter/material.dart';
import 'package:wellwiz/mental_peace/content/emotion_bot/emotion_bot_screen.dart';
import 'package:wellwiz/utils/poppy_tile.dart';

class EmotionSelector extends StatelessWidget {
  const EmotionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PoppyTile(
      borderRadius: 0, // We'll use custom border radius below
      backgroundColor: Colors.transparent,
      boxShadow: [],
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EmotionBotScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 20, bottom: 20, left: 28, right: 28),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hello There',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Color.fromARGB(255, 106, 172, 67),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    height: 2.0,
                    width: 100.0,
                    color: Colors.grey.shade800,
                  ),
                  Text(
                    'Are you fine?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      fontFamily: 'Mulish',
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emotionButton(BuildContext context, String emotion, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return EmotionBotScreen();
            },
          ),
        );
      },
      child: Text(emotion, style: TextStyle(color: color)),
    );
  }
}
