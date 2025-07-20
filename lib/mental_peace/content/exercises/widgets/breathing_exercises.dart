import 'package:flutter/material.dart';
import 'package:wellwiz/mental_peace/content/exercises/widgets/exercise_screen.dart';
import 'package:wellwiz/utils/poppy_tile.dart';
import 'package:wellwiz/utils/color_palette.dart';

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
          content: Text('Do you want to start $exercise Breathing?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ColorPalette.black,
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Start',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                fontFamily: 'Mulish',
                color: Colors.grey.shade700),
          ),
        ),
        Container(
          // margin: EdgeInsets.only(left: 20),
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(left: 20, top: 8, bottom: 16),
                child: PoppyTile(
                  borderRadius: 10,
                  backgroundColor: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  padding: EdgeInsets.zero,
                  onTap: () async {
                    await Future.delayed(const Duration(milliseconds: 250));
                    _showConfirmationDialog(context, exercises[index]);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 