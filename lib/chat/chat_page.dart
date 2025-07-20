import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_info_provider.dart';
import 'content/bot/widgets/bot_button.dart';
import 'content/alerts/widgets/sos_alert_button.dart';
import 'content/alerts/widgets/sos_contacts_button.dart';
import 'content/thoughts/widgets/thought_card.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(userInfoProvider);
    return userInfoAsync.when(
      loading: () => SizedBox.shrink(), // No progress indicator needed
      error: (e, st) => Center(child: Text('Error loading user info')), 
      data: (userInfo) {
        final firstName = userInfo.name.trim().split(' ').first;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hi, ",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  fontSize: 40,
                  color: Color.fromARGB(255, 106, 172, 67),
                ),
              ),
              Text(
                    firstName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  fontSize: 40,
                  color: const Color.fromRGBO(97, 97, 97, 1),
                ),
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
      },
    );
  }
}
