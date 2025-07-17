import 'metric_entry.dart';

class ScanEntry {
  final DateTime timestamp;
  final Map<String, MetricEntry> metrics;

  ScanEntry({required this.timestamp, required this.metrics});

  factory ScanEntry.fromMap(Map<String, dynamic> map) {
    final metricsMap = Map<String, dynamic>.from(map['metrics'] ?? {});
    return ScanEntry(
      timestamp: DateTime.parse(map['timestamp']),
      metrics: metricsMap.map((k, v) => MapEntry(k, MetricEntry.fromMap(k, Map<String, dynamic>.from(v)))),
    );
  }

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'metrics': metrics.map((k, v) => MapEntry(k, v.toMap())),
  };
} 