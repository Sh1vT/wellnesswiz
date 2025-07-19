import 'package:flutter/material.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/social_section.dart';
import 'package:wellwiz/utils/poppy_tile.dart';

class ChatroomsButton extends StatelessWidget {
  const ChatroomsButton({super.key});

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
          MaterialPageRoute(
            builder: (context) {
              return SocialSection();
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(35),
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
              topLeft: Radius.circular(12),
              topRight: Radius.circular(35),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.chat_bubble, color: Colors.grey.shade800, size: 80),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Socialize',
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
                    width: 100.0,
                    color: Colors.grey.shade800,
                  ),
                  Text(
                    'How\'s life?',
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
