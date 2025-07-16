import 'package:flutter/material.dart';
import 'package:wellwiz/mental_peace/content/emotion_bot/emotion_bot_screen.dart';

class EmotionSelector extends StatelessWidget {
  const EmotionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0), // Remove extra margin
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey.shade50,
                      title: Text(
                        "How do you feel today?",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade700,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600),
                      ),
                      content: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _emotionButton(context, 'Happy', Colors.lightGreen),
                            _emotionButton(context, 'Sad', Colors.blueAccent),
                            _emotionButton(context, 'Angry', Colors.red),
                            _emotionButton(context, 'Anxious', Colors.orange),
                            _emotionButton(context, 'Frustrated', Colors.purple),
                            _emotionButton(context, 'Stressed', Colors.grey),
                          ],
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Color.fromARGB(255, 106, 172, 67),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.only(top: 20, bottom: 20, left: 16, right: 16), // Reduce horizontal padding
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
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
        },
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
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return EmotionBotScreen(emotion: emotion);
        }));
      },
      child: Text(
        emotion,
        style: TextStyle(color: color),
      ),
    );
  }
} 