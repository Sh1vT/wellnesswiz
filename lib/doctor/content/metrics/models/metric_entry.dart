// Model for a single metric (e.g., Hemoglobin)
class MetricEntry {
  final String name;
  final double? value;
  final String unit;
  final String raw;

  MetricEntry({
    required this.name,
    required this.value,
    required this.unit,
    required this.raw,
  });

  factory MetricEntry.fromMap(String name, Map<String, dynamic> map) {
    return MetricEntry(
      name: name,
      value: map['value'] is num ? (map['value'] as num).toDouble() : double.tryParse(map['value'].toString()),
      unit: map['unit'] ?? '',
      raw: map['raw'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'value': value,
    'unit': unit,
    'raw': raw,
  };
} 