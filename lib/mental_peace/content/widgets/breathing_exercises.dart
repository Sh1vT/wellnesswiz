import 'package:flutter/material.dart';
import 'package:wellwiz/mental_peace/content/widgets/exercise_screen.dart';

class BreathingExercises extends StatelessWidget {
  const BreathingExercises({super.key});

  final List<String> exercises = const [
    'Deep',
    'Box',
    '4-7-8',
    'Alternate Nostril',
    'Happy',
    'Calm Down',
    'Stress Relief',
    'Relaxed Mind',
  ];

  final List<IconData> breathingIcons = const [
    Icons.air,
    Icons.fitness_center,
    Icons.spa,
    Icons.favorite,
    Icons.accessibility,
    Icons.cloud,
    Icons.air,
    Icons.fitness_center,
  ];

  void _showConfirmationDialog(BuildContext context, String exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Exercise'),
          content: Text('Do you want to start $exercise?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseScreen(exercise: exercise),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "Try Breathing Exercises",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade700),
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 20),
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showConfirmationDialog(context, exercises[index]);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          breathingIcons[index],
                          size: 40,
                          color: Color.fromARGB(255, 106, 172, 67),
                        ),
                        Text(
                          exercises[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Mulish',
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 