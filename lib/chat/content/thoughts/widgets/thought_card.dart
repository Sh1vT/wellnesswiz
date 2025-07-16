import 'dart:math';
import 'package:flutter/material.dart';

class ThoughtCard extends StatefulWidget {
  const ThoughtCard({super.key});

  @override
  State<ThoughtCard> createState() => _ThoughtCardState();
}

class _ThoughtCardState extends State<ThoughtCard> {
  int randomImageIndex = 1;
  int currentThoughtIndex = 0;

  final List<String> thoughts = [
    "In the garden of health, every breath is a petal, every heartbeat a bloom.",
    "Well-being is the gentle rain that nourishes the roots of our soul.",
    "A calm mind is the sunlight that helps the body’s flowers unfold.",
    "To care for the body is to write poetry with every step and every meal.",
    "Health is the silent music that lets our spirit dance in the wind.",
    "Let gratitude be the water that helps your wellness grow tall and strong.",
    "In the quiet of self-care, the heart learns to sing again.",
    "Each act of kindness to yourself is a seed for tomorrow’s joy.",
    "Rest is the moonlight that lets the garden of your being renew.",
    "Hope is the gentle breeze that carries the fragrance of healing."
  ];

  @override
  void initState() {
    super.initState();
    randomImageIndex = Random().nextInt(7);
    currentThoughtIndex = Random().nextInt(thoughts.length);
  }

  void showNextThought() {
    setState(() {
      randomImageIndex = Random().nextInt(7);
      int newIndex;
      do {
        newIndex = Random().nextInt(thoughts.length);
      } while (newIndex == currentThoughtIndex && thoughts.length > 1);
      currentThoughtIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          showNextThought();
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'assets/thought/${randomImageIndex}.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
                color: Colors.grey.shade800,
              ),
              padding:
                  EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 20),
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    "“" + thoughts[currentThoughtIndex] + "”",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Mulish',
                        fontSize: 16),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "- Wisher   ",
                      style: TextStyle(
                          fontFamily: 'Mulish',
                          color: Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 