import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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
      // Skip known non-emotion keys
      if (key == 'userimg' || key == 'username' || key == 'scan_grouped_history' || key == 'custom_report_types') continue;
      // Skip keys that are not String (e.g., List<String> from setStringList)
      final value = _prefs.get(key);
      if (value is! String) continue;
      String jsonData = value;
      try {
        Map<String, dynamic> dayData = Map<String, dynamic>.from(jsonDecode(jsonData));
        data[key] = dayData.map((k, v) => MapEntry(k, v as int));
      } catch (e) {
        print('Error decoding JSON for key $key: $e');
      }
    }
    return data;
  }

  void _onBarTap(String day) {
    final moodMap = allData[day] ?? {};
    _showPieChartDialog(day, moodMap);
  }

  void _showPieChartDialog(String day, Map<String, int> moodMap) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Your chat sessions for $day',
            style: TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  child: _buildPieChart(moodMap),
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
                // No summary, just show the pie chart and logo
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChart(Map<String, int> moodMap) {
    return PieChart(
      PieChartData(
        sections: moodMap.entries.map((entry) {
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

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case 'Happy':
        return Colors.lightGreen;
      case 'Sad':
        return Colors.blueAccent;
      case 'Angry':
        return Colors.redAccent;
      case 'Anxious':
        return Colors.orangeAccent;
      case 'Frustrated':
        return Colors.purple;
      case 'Stressed':
        return Colors.grey;
      case 'Neutral':
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  Widget _buildBarChart() {
    // Bar chart: x-axis is days of the week, y-axis is total minutes, color by dominant mood
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60, // y-axis up to 60 minutes
        barGroups: _getCurrentWeekDays().asMap().entries.map((entry) {
          int i = entry.key;
          String day = entry.value;
          final moods = allData[day] ?? {};
          double total = moods.values.fold(0, (a, b) => a + b).toDouble();
          // Pick the dominant mood for color
          String dominantMood = moods.entries.isNotEmpty ? moods.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'Neutral';
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: total,
                color: _getColorForEmotion(dominantMood),
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
                  case 0:
                    return Text('Mon', style: TextStyle(color: Colors.black));
                  case 1:
                    return Text('Tue', style: TextStyle(color: Colors.black));
                  case 2:
                    return Text('Wed', style: TextStyle(color: Colors.black));
                  case 3:
                    return Text('Thu', style: TextStyle(color: Colors.black));
                  case 4:
                    return Text('Fri', style: TextStyle(color: Colors.black));
                  case 5:
                    return Text('Sat', style: TextStyle(color: Colors.black));
                  case 6:
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
              String day = _getCurrentWeekDays()[group.x.toInt()];
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