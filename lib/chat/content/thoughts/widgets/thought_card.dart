import 'dart:math';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ThoughtCard extends StatefulWidget {
  const ThoughtCard({super.key});

  @override
  State<ThoughtCard> createState() => _ThoughtCardState();
}

class _ThoughtCardState extends State<ThoughtCard> {
  int currentThoughtIndex = 0;
  late List<int> imageIndices;
  final CarouselSliderController _carouselController = CarouselSliderController();

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
    final rand = Random();
    // Assign a random image index to each thought
    imageIndices = List.generate(thoughts.length, (_) => rand.nextInt(7));
    currentThoughtIndex = rand.nextInt(thoughts.length);
    // Start auto-scroll
    Future.delayed(const Duration(seconds: 10), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    _carouselController.nextPage(duration: Duration(milliseconds: 600));
    Future.delayed(const Duration(seconds: 10), _autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
        carouselController: _carouselController,
        itemCount: thoughts.length,
        options: CarouselOptions(
          height: 340,
          viewportFraction: 1.0, // Only center card visible
          enlargeCenterPage: false,
          padEnds: true,
          autoPlay: false, // We handle auto-scroll manually for more control
          enableInfiniteScroll: true,
          initialPage: currentThoughtIndex,
          onPageChanged: (index, reason) {
            setState(() {
              currentThoughtIndex = index;
            });
          },
          scrollPhysics: BouncingScrollPhysics(),
          pageSnapping: true,
          scrollDirection: Axis.horizontal,
        ),
        itemBuilder: (context, index, realIdx) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
              ),
              color: Colors.grey.shade800,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      'assets/thought/${imageIndices[index]}.png',
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
                        "“" + thoughts[index] + "”",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Mulish',
                            fontSize: 16),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Wisher",
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
          );
        },
      );
  }
} 