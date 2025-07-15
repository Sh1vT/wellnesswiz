import 'dart:convert';
import 'dart:ffi';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/chatrooms/chatroom_screen.dart';
import 'package:wellwiz/features/chatrooms/chatroom_selection_screen.dart';
import 'package:wellwiz/features/emotion/emotion_bot_screen.dart';
import 'package:wellwiz/features/exercise/exercise_screen.dart';
import 'package:wellwiz/secrets.dart';

class PeacePage extends StatefulWidget {
  const PeacePage({super.key});

  @override
  State<PeacePage> createState() => _PeacePageState();
}

class _PeacePageState extends State<PeacePage> {
  Map<String, Map<String, int>> allData = {};
  String? selectedDay;
  Map<String, int> emotionDistribution = {};
  late SharedPreferences _prefs;
  late final ChatSession _chat;
  static const _apiKey = geminikey;
  late final GenerativeModel _model;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      allData = _getAllEmotionData();
    });
  }

  Map<String, Map<String, int>> _getAllEmotionData() {
    Map<String, Map<String, int>> data = {};
    for (String key in _prefs.getKeys()) {
      String? jsonData = _prefs.getString(key);
      if (key == 'userimg' || key == 'username') {
        continue;
      }

      if (jsonData != null) {
        try {
          Map<String, dynamic> dayData =
              Map<String, dynamic>.from(jsonDecode(jsonData));
          data[key] = dayData.map((k, v) => MapEntry(k, v as int));
        } catch (e) {
          print('Error decoding JSON for key $key: $e');
        }
      }
    }
    return data;
  }

  final List<String> exercises = [
    'Deep',
    'Box',
    '4-7-8',
    'Alternate Nostril',
    'Happy',
    'Calm Down',
    'Stress Relief',
    'Relaxed Mind',
  ];

  final List<IconData> breathingIcons = [
    Icons.air, // Air icon
    Icons.fitness_center, // Fitness center icon
    Icons.spa, // Spa icon
    Icons.favorite, // Favorite icon
    Icons.accessibility, // Accessibility icon
    Icons.cloud, // Cloud icon
    Icons.air, // Air icon
    Icons.fitness_center, // Fitness center icon
  ];

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: emotionDistribution.entries.map((entry) {
          final emotion = entry.key;
          final time = entry.value;

          return PieChartSectionData(
            color: _getColorForEmotion(emotion),
            value: time.toDouble(),
            title: '',
            radius: 60, // Adjust radius for better appearance
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Text(
              emotion,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  void _showPieChartDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Your chat sessions for $selectedDay',
            style: TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Ensure the dialog size adjusts to content
              children: [
                SizedBox(
                  height: 200, // Fixed height for the pie chart
                  child: _buildPieChart(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 45,
                      width: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 4), // Add spacing between pie chart and message
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                        255, 177, 221, 152), // Light blue color for the bubble
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12)), // Rounded corners
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.justify,
                    style:
                        TextStyle(fontSize: 14), // Adjust text size as needed
                  ),
                ) // Use a custom message bubble widget
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      Color.fromARGB(255, 106, 172, 67))),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getCurrentWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today
          .subtract(Duration(days: today.weekday - 1))
          .add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    });
  }

  int _getTotalTimeForDay(String day) {
    if (allData[day] == null) return 0;
    return allData[day]!.values.reduce((a, b) => a + b);
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'sad':
        return Colors.blue;
      case 'happy':
        return Colors.green;
      case 'angry':
        return Colors.red;
      case 'anxious':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  Color _getColorForDay(String day) {
    // Example: Change color dynamically based on the day
    switch (DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(day))) {
      case 'Monday':
        return Colors.blueAccent;
      case 'Tuesday':
        return Colors.greenAccent;
      case 'Wednesday':
        return Colors.orangeAccent;
      case 'Thursday':
        return Colors.purpleAccent;
      case 'Friday':
        return Colors.redAccent;
      case 'Saturday':
        return Colors.yellowAccent;
      case 'Sunday':
        return Colors.tealAccent;
      default:
        return Colors.black;
    }
  }

  void _onBarTap(String day) async {
    setState(() {
      selectedDay = day;
      emotionDistribution = allData[day] ?? {};
    });
    String prompt =
        """You are a mental health chatbot being used purely for demonstration purposes and not commercially or professionally.
    Here how the user has felt for a given day : $emotionDistribution. The distribution is a map of emotion and integer. The integer is the duration in minutes.
    Basically different predfined sessions are created and based on the session duration this integer is obtained.
    Generate a short 30-40 word insight summarising how the user felt and give your advice to the user too. If negative, tell user ways to make them feel positive.
    Start with: On this day you felt...""";
    var response = await _chat.sendMessage(Content.text(prompt));

    _showPieChartDialog(response.text!.replaceAll('\n', ''));
    print(emotionDistribution);
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60, // Adjust based on the expected maximum time
        barGroups: _getCurrentWeekDays().map((day) {
          return BarChartGroupData(
            x: DateFormat('yyyy-MM-dd')
                .parse(day)
                .weekday, // Use weekday as x value
            barRods: [
              BarChartRodData(
                toY: _getTotalTimeForDay(day).toDouble(),
                color:
                    _getColorForDay(day), // Use dynamic color based on the day
                width: 20,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }).toList(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), // Hide left titles
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Map the weekdays to their names
                    switch (value.toInt()) {
                      case 1:
                        return Text('Mon',
                            style: TextStyle(color: Colors.black));
                      case 2:
                        return Text('Tue',
                            style: TextStyle(color: Colors.black));
                      case 3:
                        return Text('Wed',
                            style: TextStyle(color: Colors.black));
                      case 4:
                        return Text('Thu',
                            style: TextStyle(color: Colors.black));
                      case 5:
                        return Text('Fri',
                            style: TextStyle(color: Colors.black));
                      case 6:
                        return Text('Sat',
                            style: TextStyle(color: Colors.black));
                      case 7:
                        return Text('Sun',
                            style: TextStyle(color: Colors.black));
                      default:
                        return const Text('');
                    }
                  })),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String day = _getCurrentWeekDays()[group.x.toInt() - 1];
              return BarTooltipItem(
                '$day\n${rod.toY.toInt()} mins',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final day = _getCurrentWeekDays()[
                  barTouchResponse.spot!.touchedBarGroupIndex];
              _onBarTap(day);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Let It ",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromARGB(255, 106, 172, 67)),
              ),
              Text(
                "Out",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
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
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return EmotionBotScreen(emotion: "Happy");
                                  }));
                                },
                                child: Text(
                                  'Happy',
                                  style: TextStyle(color: Colors.lightGreen),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return EmotionBotScreen(emotion: "Sad");
                                  }));
                                },
                                child: Text(
                                  'Sad',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return EmotionBotScreen(emotion: "Angry");
                                  }));
                                },
                                child: Text(
                                  'Angry',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return EmotionBotScreen(emotion: "Anxious");
                                  }));
                                },
                                child: Text(
                                  'Anxious',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return EmotionBotScreen(
                                        emotion: "Frustrated");
                                  }));
                                },
                                child: Text(
                                  'Frustrated',
                                  style: TextStyle(color: Colors.purple),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return EmotionBotScreen(
                                        emotion: "Stressed");
                                  }));
                                },
                                child: Text(
                                  'Stressed',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
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
                  padding:
                      EdgeInsets.only(top: 20, bottom: 20, left: 28, right: 28),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 160,
                color: Theme.of(context).colorScheme.surface,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ChatRoomSelectionScreen();
                  }));
                },
                child: Container(
                  padding:
                      EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
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
                      Icon(
                        Icons.people,
                        color: Colors.grey.shade800,
                        size: 80,
                      ),
                      const SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Chat Rooms',
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
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
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
                  // width: 160,
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
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Text(
            "Emotion Monitor",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade700),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                height: 300,
                child: _buildBarChart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
}
