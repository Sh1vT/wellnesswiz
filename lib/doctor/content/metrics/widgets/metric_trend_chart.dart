import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'dart:math';

class MetricTrendChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String unit;
  const MetricTrendChart({super.key, required this.data, required this.unit});

  @override
  State<MetricTrendChart> createState() => _MetricTrendChartState();
}

class _MetricTrendChartState extends State<MetricTrendChart> {
  int? selectedIdx;
  Offset? selectedOffset;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedData = List<Map<String, dynamic>>.from(widget.data);
    sortedData.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    final points = sortedData.asMap().entries.map((e) {
      final idx = e.key;
      final val = (e.value['value'] is num)
          ? (e.value['value'] as num).toDouble()
          : double.tryParse(e.value['value'].toString().replaceAll(RegExp(r'[^0-9\.\-]'), '')) ?? 0.0;
      return Offset(idx.toDouble(), val);
    }).toList();
    final minVal = points.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    final maxVal = points.map((e) => e.dy).reduce((a, b) => a > b ? a : b);
    final dateLabels = sortedData.map((e) {
      final dt = DateTime.tryParse(e['timestamp'] ?? '') ?? DateTime.now();
      return DateFormat('MM/yy').format(dt);
    }).toList();
    final chartWidth = max(380.0, 60.0 * widget.data.length);
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          // Tap logic commented out for now. To re-enable, restore GestureDetector and indicator overlay.
          child: SizedBox(
            height: 220,
            width: chartWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              child: Column(
                children: [
                  Expanded(
                    child: CustomPaint(
                      painter: _TrendLinePainter(points, minVal, maxVal, dateLabels, widget.unit),
                      child: Container(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: dateLabels.map((label) => Text(label, style: const TextStyle(fontSize: 10, fontFamily: 'Mulish'))).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Indicator overlay commented out for now.
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<Offset> points;
  final double minVal;
  final double maxVal;
  final List<String> dateLabels;
  final String unit;
  _TrendLinePainter(this.points, this.minVal, this.maxVal, this.dateLabels, this.unit);
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final plotLeft = 30.0;
    final plotRight = size.width - 10.0;
    final plotTop = 10.0;
    final plotBottom = size.height - 20.0;
    final plotWidth = plotRight - plotLeft;
    final plotHeight = plotBottom - plotTop;
    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = plotTop + plotHeight * (i / 4);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
    }
    // Draw axes
    final axisPaint = Paint()
      ..color = ColorPalette.blackDarker
      ..strokeWidth = 2.2;
    // Y axis
    canvas.drawLine(Offset(plotLeft, plotTop), Offset(plotLeft, plotBottom), axisPaint);
    // X axis
    canvas.drawLine(Offset(plotLeft, plotBottom), Offset(plotRight, plotBottom), axisPaint);
    // Draw smooth trend line (Catmull-Rom spline)
    final linePaint = Paint()
      ..color = ColorPalette.green
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    List<Offset> scaledPoints = points.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      final x = plotLeft + plotWidth * (i / (points.length - 1));
      final y = plotBottom - ((p.dy - minVal) / ((maxVal - minVal) == 0 ? 1 : (maxVal - minVal)) * plotHeight);
      return Offset(x, y);
    }).toList();
    if (scaledPoints.length > 1) {
      path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
      for (int i = 0; i < scaledPoints.length - 1; i++) {
        final p0 = scaledPoints[i];
        final p1 = scaledPoints[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        if (i == 0) {
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        } else {
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        }
      }
      path.lineTo(scaledPoints.last.dx, scaledPoints.last.dy);
    }
    canvas.drawPath(path, linePaint);
    // Y axis labels
    final textStyle = const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Mulish');
    final textPainterMin = TextPainter(
      text: TextSpan(text: minVal.toStringAsFixed(1), style: textStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainterMin.paint(canvas, Offset(0, plotBottom - 10));
    final textPainterMax = TextPainter(
      text: TextSpan(text: maxVal.toStringAsFixed(1), style: textStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainterMax.paint(canvas, Offset(0, plotTop - 6));
    // Y axis unit label
    if (unit.isNotEmpty) {
      final unitPainter = TextPainter(
        text: TextSpan(text: unit, style: textStyle.copyWith(fontSize: 11)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      unitPainter.paint(canvas, Offset(0, plotTop + plotHeight / 2 - 10));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 