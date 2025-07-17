Map<String, Map<String, dynamic>> sanitizeExtractedMetrics(List<List<dynamic>> metrics) {
  final Map<String, Map<String, dynamic>> sanitized = {};
  final unitRegex = RegExp(r'([\d.]+)\s*([a-zA-Z%/]+)?');
  for (var row in metrics) {
    if (row.length < 2) continue;
    String name = row[0].toString().replaceAll('*', '').replaceAll('-', '').replaceAll(RegExp(r'\s+'), ' ').trim();
    name = name.replaceAll(RegExp(r'[:\-]+$'), '').trim(); // Remove trailing colons/dashes
    name = normalizeMetricName(name); // Normalize to canonical name
    String valueStr = row[1].toString().replaceAll('*', '').replaceAll('-', '').replaceAll(RegExp(r'\s+'), ' ').trim();
    double? value;
    String? unit;
    final match = unitRegex.firstMatch(valueStr);
    if (match != null) {
      value = double.tryParse(match.group(1) ?? '');
      unit = match.group(2);
    } else {
      value = double.tryParse(valueStr);
    }
    sanitized[name] = {
      'value': value,
      'unit': unit ?? '',
      'raw': valueStr,
    };
  }
  return sanitized;
}

const Map<String, String> metricNameMap = {
  'bun': 'BUN',
  'blood urea nitrogen': 'BUN',
  'wbc': 'WBC',
  'white blood cell': 'WBC',
  'hemoglobin': 'Hemoglobin',
  // Add more as needed
};

String normalizeMetricName(String name) {
  final key = name.toLowerCase().trim();
  return metricNameMap[key] ?? name;
} 