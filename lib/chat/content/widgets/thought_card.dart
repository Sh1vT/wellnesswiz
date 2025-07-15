import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:wellwiz/secrets.dart';

class ThoughtCard extends StatefulWidget {
  const ThoughtCard({super.key});

  @override
  State<ThoughtCard> createState() => _ThoughtCardState();
}

class _ThoughtCardState extends State<ThoughtCard> {
  int randomImageIndex = 1;
  String thought = "To be, or not to be, that is the question";
  bool thoughtGenerated = false;
  late final ChatSession _chat;
  static const _apiKey = geminikey;
  late final GenerativeModel _model;

  void generateThought() async {
    String prompt =
        "Generate a deep philosophical Shakespearean thought for a mental health application that is purely for demonstration purposes and no commercial use. The thought has to be unique and should be positive. Respond with only the thought without formatting and nothing else. Keep the thought limited to 30 words.";
    var response = await _chat.sendMessage(Content.text(prompt));
    setState(() {
      thought = response.text!;
      thoughtGenerated = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    randomImageIndex = (Random().nextInt(7));
    generateThought();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          setState(() {
            randomImageIndex = (Random().nextInt(7));
            generateThought();
          });
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
                    thoughtGenerated
                        ? "“" + thought.replaceAll('\n', '') + "”"
                        : thought,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Mulish',
                        fontSize: 16),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      thoughtGenerated ? "- Wisher   " : "-Shakespeare",
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