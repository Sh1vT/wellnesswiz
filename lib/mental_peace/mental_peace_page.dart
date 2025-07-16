import 'package:flutter/material.dart';
import 'content/emotion_bot/widgets/emotion_selector.dart';
import 'content/socialize/widgets/chatrooms_button.dart';
import 'content/exercises/widgets/breathing_exercises.dart';
import 'content/monitor/widgets/emotion_monitor.dart';

class MentalPeacePage extends StatelessWidget {
  const MentalPeacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // const SizedBox(height: 20),
        // const SizedBox(height: 10),
        // Add 'Let it out' text above the selector row
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Let",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  fontSize: 40,
                  color: Color.fromARGB(255, 106, 172, 67),
                ),
              ),
              SizedBox(width: 4),
              Text(
                " It out",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  fontSize: 40,
                  color: Color.fromRGBO(97, 97, 97, 1),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 26, right: 26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: EmotionSelector()),
              SizedBox(width: 20),
              ChatroomsButton(),
            ],
          ),
        ),
        const BreathingExercises(),
        const EmotionMonitor(),
        const SizedBox(height: 20),
      ],
    );
  }
}
