import 'package:flutter/material.dart';
import 'content/widgets/bot_button.dart';
import 'content/widgets/sos_alert_button.dart';
import 'content/widgets/sos_contacts_button.dart';
import 'content/widgets/thought_card.dart';

class ChatPage extends StatelessWidget {
  final String uname;
  const ChatPage({super.key, required this.uname});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hi, ",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromARGB(255, 106, 172, 67)),
              ),
              Text(
                uname,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        const BotButton(),
        const SOSAlertButton(),
        const SOSContactsButton(),
        const ThoughtCard(),
        SizedBox(height: 20),
      ],
    );
  }
}
