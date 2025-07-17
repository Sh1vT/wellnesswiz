import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'metric_trend_chart.dart';

class MetricTrendDialog extends StatelessWidget {
  final String metric;
  final String unit;
  final List<Map<String, dynamic>> data;

  const MetricTrendDialog({
    Key? key,
    required this.metric,
    required this.unit,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return AlertDialog(
        title: Text('$metric${unit.isNotEmpty ? ' ($unit)' : ''}'),
        content: const Text('Not enough data for a trend.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text('$metric Trend${unit.isNotEmpty ? ' ($unit)' : ''}'),
      content: SizedBox(
        height: 220,
        width: 340,
        child: MetricTrendChart(data: data, unit: unit),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: ColorPalette.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
} 