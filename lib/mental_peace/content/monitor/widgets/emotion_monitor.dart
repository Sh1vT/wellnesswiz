import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/utils/color_palette.dart';

class EmotionMonitor extends StatefulWidget {
  const EmotionMonitor({super.key});

  @override
  State<EmotionMonitor> createState() => _EmotionMonitorState();
}

class _EmotionMonitorState extends State<EmotionMonitor> {
  static const String monitorKey = 'emotion_monitor_data';
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
    final raw = _prefs.getString(monitorKey);
    print('[EmotionMonitor] Raw data for key $monitorKey: $raw');
    setState(() {
      allData = _getAllEmotionData();
      print('[EmotionMonitor] Parsed allData: $allData');
    });
  }

  Map<String, Map<String, int>> _getAllEmotionData() {
    final jsonString = _prefs.getString(monitorKey);
    if (jsonString == null) return {};
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, Map<String, int>.from(v)));
    } catch (e) {
      print('Error decoding emotion monitor data: $e');
      return {};
    }
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
            style: TextStyle(fontSize: 18, fontFamily: 'Mulish'),
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
            titleStyle: TextStyle(fontFamily: 'Mulish'),
            badgeWidget: Text(
              emotion,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Mulish'),
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
                    return Text('Mon', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
                  case 1:
                    return Text('Tue', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
                  case 2:
                    return Text('Wed', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
                  case 3:
                    return Text('Thu', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
                  case 4:
                    return Text('Fri', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
                  case 5:
                    return Text('Sat', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
                  case 6:
                    return Text('Sun', style: TextStyle(color: Colors.black, fontFamily: 'Mulish'));
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
                color: Colors.grey.shade700,
                fontFamily: 'Mulish'),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    _buildBarChart(),
                    if (allData.isEmpty || allData.values.every((moods) => moods.isEmpty || moods.values.every((v) => v == 0)))
                      Center(
                        child: Container(
                          height: 120,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              // BoxShadow(
                              //   color: Colors.black.withOpacity(0.05),
                              //   blurRadius: 8,
                              //   offset: Offset(0, 2),
                              // ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lock, color: ColorPalette.black, size: 32),
                              SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Data :(',
                                    style: TextStyle(
                                      color: ColorPalette.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Mulish',
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Have some discussion\nwith Wiz on top left!',
                                    style: TextStyle(
                                      color: ColorPalette.black,
                                      fontFamily: 'Mulish',
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "This one's private",
                                    style: TextStyle(
                                      color: ColorPalette.black,
                                      fontFamily: 'Mulish',
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
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
            ],
          ),
        ),
      ],
    );
  }
} 