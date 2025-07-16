import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/secrets.dart';

class EmotionMonitor extends StatefulWidget {
  const EmotionMonitor({super.key});

  @override
  State<EmotionMonitor> createState() => _EmotionMonitorState();
}

class _EmotionMonitorState extends State<EmotionMonitor> {
  Map<String, Map<String, int>> allData = {};
  String? selectedDay;
  Map<String, int> emotionDistribution = {};
  late SharedPreferences _prefs;
  late final ChatSession _chat;
  static const _apiKey = geminikey;
  late final GenerativeModel _model;

  @override
  void initState() {
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
          Map<String, dynamic> dayData = Map<String, dynamic>.from(jsonDecode(jsonData));
          data[key] = dayData.map((k, v) => MapEntry(k, v as int));
        } catch (e) {
          print('Error decoding JSON for key $key: $e');
        }
      }
    }
    return data;
  }

  void _onBarTap(String day) async {
    setState(() {
      selectedDay = day;
      emotionDistribution = allData[day] ?? {};
    });
    String prompt =
        """You are a mental health chatbot being used purely for demonstration purposes and not commercially or professionally.\nHere how the user has felt for a given day : $emotionDistribution. The distribution is a map of emotion and integer. The integer is the duration in minutes.\nBasically different predfined sessions are created and based on the session duration this integer is obtained.\nGenerate a short 30-40 word insight summarising how the user felt and give your advice to the user too. If negative, tell user ways to make them feel positive.\nStart with: On this day you felt...""";
    var response = await _chat.sendMessage(Content.text(prompt));
    _showPieChartDialog(response.text!.replaceAll('\n', ''));
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
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 177, 221, 152),
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12)),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

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
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Text(
              emotion,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  List<String> _getCurrentWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: today.weekday - 1)).add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    });
  }

  int _getTotalTimeForDay(String day) {
    if (allData[day] == null) return 0;
    return allData[day]!.values.fold(0, (a, b) => a + b);
  }

  Color _getColorForDay(String day) {
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

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60, // Adjust as needed
        barGroups: _getCurrentWeekDays().map((day) {
          return BarChartGroupData(
            x: DateFormat('yyyy-MM-dd').parse(day).weekday,
            barRods: [
              BarChartRodData(
                toY: _getTotalTimeForDay(day).toDouble(),
                color: _getColorForDay(day),
                width: 20,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }).toList(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 1:
                    return Text('Mon', style: TextStyle(color: Colors.black));
                  case 2:
                    return Text('Tue', style: TextStyle(color: Colors.black));
                  case 3:
                    return Text('Wed', style: TextStyle(color: Colors.black));
                  case 4:
                    return Text('Thu', style: TextStyle(color: Colors.black));
                  case 5:
                    return Text('Fri', style: TextStyle(color: Colors.black));
                  case 6:
                    return Text('Sat', style: TextStyle(color: Colors.black));
                  case 7:
                    return Text('Sun', style: TextStyle(color: Colors.black));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
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

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case 'Happy':
        return Colors.lightGreen;
      case 'Sad':
        return Colors.blueAccent;
      case 'Frustrated':
        return Colors.purple;
      case 'Stressed':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
} 