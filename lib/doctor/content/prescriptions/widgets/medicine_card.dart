import 'package:flutter/material.dart';
import 'package:wellwiz/doctor/content/prescriptions/models/prescription.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'dart:math' as math;
import 'package:wellwiz/utils/poppy_tile.dart';

class MedicineCard extends StatelessWidget {
  final Prescription prescription;
  final String timeOfDay;
  final VoidCallback? onDelete;
  final VoidCallback? onCheck;
  final bool isTaken;
  const MedicineCard({
    required this.prescription,
    required this.timeOfDay,
    this.onDelete,
    this.onCheck,
    this.isTaken = false,
    Key? key,
  }) : super(key: key);

  static const Map<String, List<String>> timeOfDayRanges = {
    'Morning': ['05:00', '11:59'],
    'Noon': ['12:00', '15:59'],
    'Evening': ['16:00', '19:59'],
    'Night': ['20:00', '04:59'],
  };

  List<String> getTimesForWindow() {
    final range = timeOfDayRanges[timeOfDay]!;
    final start = _parseTime(range[0]);
    final end = _parseTime(range[1]);
    return prescription.times.where((t) {
      final time = _parseTime(t);
      if (start.isBefore(end)) {
        return !time.isBefore(start) && !time.isAfter(end);
      } else {
        // Night: wraps around midnight
        return !time.isBefore(start) || !time.isAfter(end);
      }
    }).toList();
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatDateRange(DateTime from, DateTime? to) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String dayMonth(DateTime d) => '${d.day} ${months[d.month]}';
    if (to != null) {
      return '${dayMonth(from)} - ${dayMonth(to)}';
    } else {
      return dayMonth(from);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timesForWindow = getTimesForWindow();
    double? dosageValue = double.tryParse(prescription.dosage);
    int fullCircles = 0;
    bool hasHalf = false;
    if (dosageValue != null) {
      fullCircles = dosageValue.floor();
      hasHalf = (dosageValue - fullCircles) >= 0.5;
    }
    return Stack(
      children: [
        PoppyTile(
          borderRadius: 16,
          backgroundColor: Colors.grey.shade200,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          padding: EdgeInsets.zero,
          child: Container(
            width: 220,
            constraints: BoxConstraints(
              minHeight: 140,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 16, right: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onCheck,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            isTaken ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isTaken ? ColorPalette.green : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          prescription.medicineName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: ColorPalette.blackDarker,
                            fontFamily: 'Mulish',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 12, right: 8),
                  child: Row(
                    children: [
                      if (dosageValue != null && dosageValue > 0) ...[
                        ...List.generate(fullCircles, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.circle, size: 14, color: ColorPalette.green),
                        )),
                        if (hasHalf)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CustomPaint(
                                    painter: _HalfCirclePainter(color: ColorPalette.green),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ] else ...[
                        ...List.generate(timesForWindow.length, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.circle, size: 14, color: ColorPalette.green),
                        )),
                        if (timesForWindow.isEmpty)
                          Text('No dose', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                if (timesForWindow.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: ColorPalette.green),
                        const SizedBox(width: 4),
                        Text(
                          timesForWindow.join(', '),
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
                if (prescription.instructions != null && prescription.instructions!.trim().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 10, right: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Top-align icon
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            prescription.instructions!,
                            style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8),
                  child: Text(
                    _formatDateRange(prescription.startDate, prescription.endDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Mulish',
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Delete icon (top right, grey 200 bg, black x)
        if (onDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: ColorPalette.black, size: 18),
              ),
            ),
          ),
      ],
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  final Color color;
  _HalfCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, math.pi / 2, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 