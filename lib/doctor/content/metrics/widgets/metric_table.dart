import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class NormalRange {
  final double? min;
  final double? max;
  final String unit;
  const NormalRange({this.min, this.max, required this.unit});
}

const Map<String, NormalRange> normalRanges = {
  "Hemoglobin": NormalRange(min: 13.0, max: 17.0, unit: "g/dL"),
  "WBC": NormalRange(min: 4.5, max: 11.0, unit: "x10³/uL"),
  "Platelets": NormalRange(min: 150, max: 450, unit: "x10³/uL"),
  "SGPT": NormalRange(min: 0, max: 40, unit: "U/L"),
  // Add more as needed
};

class MetricTable extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final void Function(String metricName) onMetricTap;

  const MetricTable({
    Key? key,
    required this.metrics,
    required this.onMetricTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(),
            1: FixedColumnWidth(36), // For the icon
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Chemical',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 36), // Header for icon column
                Padding(
                  padding: EdgeInsets.only(left: 28.0, right: 8.0, top: 8.0, bottom: 8.0),
                  child: Text(
                    'Value',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Normal Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...metrics.entries.map((entry) {
              final metricName = entry.key;
              final metricObj = entry.value;
              final value = _extractValue(metricObj);
              final range = normalRanges[metricName];
              final valueColor = _getValueColor(value, range);
              return TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(metricName),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () => onMetricTap(metricName),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: ColorPalette.green,
                          child: const Icon(Icons.timeline, size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28.0, right: 8.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        _formatValueWithUnit(metricObj),
                        style: TextStyle(
                          color: valueColor,
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: range != null
                          ? Text(_formatRange(range), style: const TextStyle(color: Colors.grey))
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 10), // Add space after the table
      ],
    );
  }

  String _formatValueWithUnit(dynamic metricObj) {
    if (metricObj is Map<String, dynamic>) {
      final value = metricObj['value'] ?? metricObj['raw'] ?? '';
      final unit = metricObj['unit'] ?? '';
      return unit != null && unit.toString().isNotEmpty ? '$value $unit' : value.toString();
    }
    if (metricObj is dynamic && metricObj.value != null) {
      final value = metricObj.value ?? metricObj.raw;
      final unit = metricObj.unit;
      return unit.isNotEmpty ? '$value $unit' : value.toString();
    }
    return metricObj?.toString() ?? '';
  }

  double? _extractValue(dynamic metricObj) {
    if (metricObj is Map<String, dynamic>) {
      final v = metricObj['value'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    }
    if (metricObj is dynamic && metricObj.value != null) {
      if (metricObj.value is num) return (metricObj.value as num).toDouble();
      return double.tryParse(metricObj.value.toString());
    }
    return null;
  }

  String _formatRange(NormalRange range) {
    if (range.min != null && range.max != null) {
      return '${range.min}–${range.max} ${range.unit}';
    } else if (range.min != null) {
      return '≥${range.min} ${range.unit}';
    } else if (range.max != null) {
      return '≤${range.max} ${range.unit}';
    }
    return range.unit;
  }

  Color _getValueColor(double? value, NormalRange? range) {
    if (value == null || range == null) return Colors.black;
    if (range.min != null && value < range.min!) return Colors.red;
    if (range.max != null && value > range.max!) return Colors.red;
    return Colors.green;
  }
} 