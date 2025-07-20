import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/doctor/content/metrics/models/scan_entry.dart';
import '../doctor/content/metrics/models/metric_entry.dart';
import 'metrics_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> saveScan(
  List<List<dynamic>> metrics,
  String? reportType,
) async {
  final pref = await SharedPreferences.getInstance();
  String key = (reportType ?? 'Unknown').trim().isEmpty ? 'custom_report' : '${reportType!.toLowerCase().replaceAll(' ', '_')}_report';
  String? groupedJson = pref.getString('scan_grouped_history');
  Map<String, List<ScanEntry>> groupedHistory = {};
  if (groupedJson != null && groupedJson.isNotEmpty) {
    try {
      final decoded = jsonDecode(groupedJson);
      decoded.forEach((k, v) {
        groupedHistory[k] = List<Map<String, dynamic>>.from(v)
            .map((e) => ScanEntry.fromMap(e))
            .toList();
      });
    } catch (e) {}
  }
  // Sanitize metrics and convert to map (now with value/unit)
  final sanitizedMetrics = sanitizeExtractedMetrics(metrics);
  final metricEntries = sanitizedMetrics.map((k, v) => MapEntry(k, MetricEntry(
    name: k,
    value: v['value'],
    unit: v['unit'],
    raw: v['raw'],
  )));
  final entry = ScanEntry(
    timestamp: DateTime.now(),
    metrics: metricEntries,
  );
  if (!groupedHistory.containsKey(key)) {
    groupedHistory[key] = [];
  }
  groupedHistory[key]!.add(entry);
  await pref.setString('scan_grouped_history', jsonEncode(
    groupedHistory.map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList())),
  ));
  Fluttertoast.showToast(msg: "Scan saved to history.");
}

Future<Map<String, List<ScanEntry>>> loadGroupedHistory() async {
  final pref = await SharedPreferences.getInstance();
  String? groupedJson = pref.getString('scan_grouped_history');
  Map<String, List<ScanEntry>> groupedHistory = {};
  if (groupedJson != null && groupedJson.isNotEmpty) {
    try {
      final decoded = jsonDecode(groupedJson);
      decoded.forEach((k, v) {
        groupedHistory[k] = List<Map<String, dynamic>>.from(v)
            .map((e) => ScanEntry.fromMap(e))
            .toList();
      });
    } catch (e) {}
  }
  return groupedHistory;
} 