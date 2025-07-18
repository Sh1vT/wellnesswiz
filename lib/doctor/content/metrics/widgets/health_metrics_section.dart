import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/doctor/content/metrics/models/scan_entry.dart';
import 'package:wellwiz/secrets.dart';
import 'package:wellwiz/doctor/content/metrics/models/metric_entry.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/metric_table.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/metric_trend_chart.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/report_type_selector.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/extracted_metrics_dialog.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/image_picker_dialog.dart';
import 'package:wellwiz/utils/metrics_utils.dart';
import 'package:wellwiz/utils/scan_history_service.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/metric_trend_dialog.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'report_history_dialog.dart';

class HealthMetricsSection extends StatefulWidget {
  const HealthMetricsSection({super.key});

  @override
  State<HealthMetricsSection> createState() => _HealthMetricsSectionState();
}

class _HealthMetricsSectionState extends State<HealthMetricsSection> {
  List<List<dynamic>> tableList = [];
  bool _isTableExpanded = false;
  late File _image;
  late final GenerativeModel _model;
  static const _apiKey = geminikey;
  late final ChatSession _chat;
  bool imageInitialized = false;
  // Report type selection
  String? selectedReportType;
  String customReportType = '';
  List<String> reportTypes = [
    "CBC",
    "Urine Routine",
    "LFT",
    "KFT",
    "Lipid Profile",
    "Blood Sugar",
    "Thyroid Profile",
    "Vitamin & Mineral",
    "Electrolyte Panel",
    "Imaging",
    "Infectious Disease",
    "Hormonal Profile",
    "Allergy Panel",
    "Cancer Markers",
    "Custom",
  ];
  static const String customTypesKey = 'custom_report_types';

  // Add mapping for auto-detect
  final Map<String, List<String>> reportTypeMetrics = {
    "CBC": [
      "Hemoglobin",
      "RBC",
      "WBC",
      "Platelets",
      "Hematocrit",
      "MCV",
      "MCH",
      "MCHC",
    ],
    "Urine Routine": [
      "pH",
      "Protein",
      "Glucose",
      "Ketones",
      "Pus cells",
      "RBCs",
    ],
    "LFT": [
      "SGPT",
      "ALT",
      "SGOT",
      "AST",
      "Bilirubin",
      "Alkaline phosphatase",
      "Albumin",
      "Globulin",
    ],
    "KFT": [
      "Urea",
      "Creatinine",
      "Uric acid",
      "Sodium",
      "Potassium",
      "Chloride",
    ],
    "Lipid Profile": [
      "Total Cholesterol",
      "HDL",
      "LDL",
      "VLDL",
      "Triglycerides",
    ],
    "Blood Sugar": [
      "Fasting Blood Sugar",
      "FBS",
      "Postprandial Blood Sugar",
      "PPBS",
      "HbA1c",
    ],
    "Thyroid Profile": ["T3", "T4", "TSH"],
    "Vitamin & Mineral": [
      "Vitamin D3",
      "Vitamin B12",
      "Calcium",
      "Iron",
      "Magnesium",
      "Zinc",
    ],
    "Electrolyte Panel": ["Sodium", "Potassium", "Chloride"],
    "Imaging": ["ECG", "Echo", "X-ray", "CT", "MRI"],
    "Infectious Disease": [
      "COVID-19",
      "Dengue",
      "Malaria",
      "Typhoid",
      "Hepatitis",
      "HIV",
      "HBsAg",
    ],
    "Hormonal Profile": [
      "Insulin",
      "Testosterone",
      "Estrogen",
      "Progesterone",
      "LH",
      "FSH",
      "Prolactin",
    ],
    "Allergy Panel": ["IgE"],
    "Cancer Markers": ["PSA", "CA-125", "CEA"],
  };

  // Helper for auto-detect
  String autoDetectReportType(List<String> extractedMetrics) {
    String bestType = "Custom";
    int bestMatch = 0;
    reportTypeMetrics.forEach((type, metrics) {
      int matches = metrics
          .where(
            (m) => extractedMetrics.any(
              (em) => em.toLowerCase().contains(m.toLowerCase()),
            ),
          )
          .length;
      if (matches > bestMatch) {
        bestMatch = matches;
        bestType = type;
      }
    });
    return bestType;
  }

  // Show extracted metrics and let user select/override report type
  Future<void> _showExtractedMetricsDialog(
    List<List<dynamic>> extractedMetrics,
  ) async {
    // Sanitize metric names for auto-detect
    final metricNames = extractedMetrics
        .map((e) => e[0].toString().trim())
        .toList();
    String detectedType = autoDetectReportType(metricNames);
    await showDialog(
      context: context,
      builder: (context) => ExtractedMetricsDialog(
        extractedMetrics: extractedMetrics,
        reportTypes: reportTypes,
        detectedType: detectedType,
        onSave: (metrics, selectedType) async {
          // If custom, persist it
          if (selectedType != null && selectedType.trim().isNotEmpty &&
              !reportTypes.contains(selectedType.trim()) && selectedType != 'Custom') {
            await _addCustomReportType(selectedType.trim());
          }
          saveScan(metrics, selectedType);
        },
      ),
    ).then((_) => setState(() {}));
  }

  // Save scan with report type and timestamp (grouped by report type)
  Future<void> _saveScan(
    List<List<dynamic>> metrics,
    String? reportType,
  ) async {
    final pref = await SharedPreferences.getInstance();
    String key = (reportType ?? 'Unknown').trim().isEmpty
        ? 'custom_report'
        : reportType!.toLowerCase().replaceAll(' ', '_') + '_report';
    String? groupedJson = pref.getString('scan_grouped_history');
    Map<String, List<ScanEntry>> groupedHistory = {};
    if (groupedJson != null && groupedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(groupedJson);
        decoded.forEach((k, v) {
          groupedHistory[k] = List<Map<String, dynamic>>.from(
            v,
          ).map((e) => ScanEntry.fromMap(e)).toList();
        });
      } catch (e) {}
    }
    // Sanitize metrics and convert to map (now with value/unit)
    final sanitizedMetrics = sanitizeExtractedMetrics(metrics);
    final metricEntries = sanitizedMetrics.map(
      (k, v) => MapEntry(
        k,
        MetricEntry(name: k, value: v['value'], unit: v['unit'], raw: v['raw']),
      ),
    );
    final entry = ScanEntry(timestamp: DateTime.now(), metrics: metricEntries);
    if (!groupedHistory.containsKey(key)) {
      groupedHistory[key] = [];
    }
    groupedHistory[key]!.add(entry);
    await pref.setString(
      'scan_grouped_history',
      jsonEncode(
        groupedHistory.map(
          (k, v) => MapEntry(k, v.map((e) => e.toMap()).toList()),
        ),
      ),
    );
    setState(() {
      // Optionally, update UI or reload history
    });
  }

  Future<void> getImageCamera(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImagePickerDialog(
          onCamera: () async {
                  Navigator.of(context).pop();
                  await Permission.camera.request();
                  var image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
              await _sendImageMessageAndShowDialog();
                  } else {
                  }
                },
          onGallery: () async {
                  Navigator.of(context).pop();
            var image = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
              await _sendImageMessageAndShowDialog();
                  } else {
                  }
                },
        );
      },
    );
  }

  // After extraction, show dialog for review and type selection
  Future<void> _sendImageMessageAndShowDialog() async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.green,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 5,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Scanning Report...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    final imgBytes = await _image.readAsBytes();
    String prompt = """
  You are being used as a medical chatbot for demonstration purposes. 
  The user has submitted a medical report in image form, and you need to extract body chemical levels. 

  Instructions:
  1. Extract the body chemical levels from the medical report and format them as \"Title : Value : Integer\" where:
    - \"Title\" is the name of the chemical or component. If it is written in short then write the full form or the more well-known version of that title.
    - \"Value\" is the numerical level.
    - \"Integer\" is 0, -1, or 1 depending on the following:
      - 0: Level is within the normal range
      - -1: Level is below the normal range
      - 1: Level is above the normal range

  Return the list of chemical levels in the format \"Title : Value : Integer\".\nIf nothing is found, return \"none\".
  """;
    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imgBytes)]),
    ];
    final response = await _model.generateContent(content);
    final responseText = response.text!.toLowerCase().trim();
    // Dismiss progress dialog
    Navigator.of(context).pop();
    if (responseText == "none") {
      Fluttertoast.showToast(msg: "No levels found.");
      return;
    }
    try {
      List<List<dynamic>> extractedMetrics = [];
      List<String> entries = response.text!
          .split('\n')
          .map((e) => e.trim())
          .toList();
      for (var entry in entries) {
        List<String> parts = entry.split(':').map((e) => e.trim()).toList();
        if (parts.length == 3) {
          String title = parts[0];
          String value = parts[1];
          int flag = int.tryParse(parts[2]) ?? 0;
          extractedMetrics.add([title, value, flag]);
        }
      }
      await _showExtractedMetricsDialog(extractedMetrics);
    } catch (e) {
      Fluttertoast.showToast(msg: "An unknown error occurred!");
    }
  }

  Future<void> _loadTable() async {
    final pref = await SharedPreferences.getInstance();
    String? tableJson = pref.getString('table');
    if (tableJson != null && tableJson.isNotEmpty) {
      setState(() {
        tableList = List<List<dynamic>>.from(
          jsonDecode(tableJson).map((item) => List<dynamic>.from(item)),
        );
      });
    }
  }

  // Widget for report type selection
  void _deleteTableData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      tableList.clear();
    });
    await pref.remove('table');
  }

  Widget _buildTable() {
    if (tableList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade100,
        ),
        child: const Center(
          child: Text(
            'Try scanning some reports!',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
        ),
      );
    }
    tableList.sort((a, b) => a[0].compareTo(b[0]));
    return Table(
      border: TableBorder(borderRadius: BorderRadius.circular(12)),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(80),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Color.fromRGBO(106, 172, 67, 1)),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Chemical',
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Value',
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Status',
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        ...tableList.map((row) {
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(row[0])),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(row[1])),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: () {
                  if (row[2] == 1) {
                    return const Icon(Icons.arrow_upward, color: Colors.red);
                  } else if (row[2] == -1) {
                    return const Icon(Icons.arrow_downward, color: Colors.red);
                  } else {
                    return const Icon(
                      Icons.thumb_up_sharp,
                      color: Colors.green,
                    );
                  }
                }(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Helper to load grouped scan history from SharedPreferences
  Future<Map<String, List<ScanEntry>>> _loadGroupedHistory() async {
    final pref = await SharedPreferences.getInstance();
    String? groupedJson = pref.getString('scan_grouped_history');
    Map<String, List<ScanEntry>> groupedHistory = {};
    if (groupedJson != null && groupedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(groupedJson);
        decoded.forEach((k, v) {
          groupedHistory[k] = List<Map<String, dynamic>>.from(
            v,
          ).map((e) => ScanEntry.fromMap(e)).toList();
        });
      } catch (e) {}
    }
    return groupedHistory;
  }

  // Widget to show report type chips and the latest scan's table
  Widget _buildTableWithTrends() {
    return FutureBuilder<Map<String, List<ScanEntry>>>(
      future: _loadGroupedHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final groupedHistory = snapshot.data!;
        if (groupedHistory.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No scan history yet.'),
          );
        }
        // Report type chips
        List<String> reportTypeKeys = groupedHistory.keys.toList();
        String? selectedType = selectedReportType;
        if (selectedType == null || !reportTypeKeys.contains(selectedType)) {
          selectedType = reportTypeKeys.isNotEmpty
              ? reportTypeKeys.first
              : null;
        }
        final entries = selectedType != null
            ? List<ScanEntry>.from(groupedHistory[selectedType] ?? [])
            : <ScanEntry>[];
        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No scans for this report type yet.'),
          );
        }
        // Show the latest scan for the selected type
        final latest = entries.last;
        final metrics = latest.metrics;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Select Report Type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: reportTypeKeys
                  .map(
                    (type) => ChoiceChip(
                      label: Text(
                        type
                            .replaceAll('_report', '')
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                      ),
                      selected: selectedType == type,
                      onSelected: (selected) {
                        if (selected)
                          setState(() {
                            selectedReportType = type;
                          });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Latest Scan: ${DateFormat('yyyy-MM-dd – kk:mm').format(latest.timestamp)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            MetricTable(
              metrics: metrics,
              onMetricTap: (metricName) =>
                  _showMetricTrendDialog(metricName, entries),
            ),
          ],
        );
      },
    );
  }

  // Show a dialog with the trend for a metric
  void _showMetricTrendDialog(String metric, List<ScanEntry> entries) {
    // Gather all values for this metric
    final data = entries.where((e) => e.metrics.containsKey(metric)).map((e) {
      final metricObj = e.metrics[metric]!;
      return {
        'timestamp': e.timestamp.toIso8601String(),
        'value': metricObj.value,
        'unit': metricObj.unit,
      };
    }).toList();
    final unit = data.isNotEmpty ? (data.first['unit']?.toString() ?? '') : '';
    showDialog(
      context: context,
      builder: (context) =>
          MetricTrendDialog(metric: metric, unit: unit, data: data),
    );
  }

  // Helper to format value with unit
  String _formatValueWithUnit(dynamic metricObj) {
    if (metricObj is MetricEntry) {
      final value = metricObj.value ?? metricObj.raw;
      final unit = metricObj.unit;
      return unit.isNotEmpty ? '$value $unit' : value.toString();
    }
    if (metricObj is Map<String, dynamic>) {
      final value = metricObj['value'] ?? metricObj['raw'] ?? '';
      final unit = metricObj['unit'] ?? '';
      return unit != null && unit.toString().isNotEmpty
          ? '$value $unit'
          : value.toString();
    }
    return metricObj?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: _apiKey);
    _chat = _model.startChat();
    _loadTable();
    _loadCustomReportTypes();
  }

  Future<void> _loadCustomReportTypes() async {
    final pref = await SharedPreferences.getInstance();
    final customTypes = pref.getStringList(customTypesKey) ?? [];
    setState(() {
      // Insert before 'Custom' chip
      reportTypes = [
        ...reportTypes.where((t) => t != 'Custom'),
        ...customTypes.where((t) => !reportTypes.contains(t)),
        'Custom',
      ];
    });
  }

  Future<void> _addCustomReportType(String type) async {
    final pref = await SharedPreferences.getInstance();
    final customTypes = pref.getStringList(customTypesKey) ?? [];
    final normalized = type.trim();
    if (normalized.isEmpty || reportTypes.contains(normalized) || customTypes.contains(normalized)) return;
    final updated = [...customTypes, normalized];
    await pref.setStringList(customTypesKey, updated);
    setState(() {
      reportTypes = [
        ...reportTypes.where((t) => t != 'Custom'),
        normalized,
        'Custom',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and spacing WITH padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Your Reports',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.black,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Report type selector (chips row) WITHOUT padding
          FutureBuilder<Map<String, List<ScanEntry>>>(
            future: _loadGroupedHistory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final groupedHistory = snapshot.data!;
              if (groupedHistory.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan button as chip WITH left padding, always visible
                    SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => getImageCamera(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: ColorPalette.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Scan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: ColorPalette.greenSwatch[50],
                      ),
                      child: const Center(
                        child: Text(
                          'Try scanning some reports!',
                          style: TextStyle(fontFamily: 'Mulish'),
                        ),
                      ),
                    ),
                  ],
                );
              }
              List<String> reportTypeKeys = groupedHistory.keys.toList();
              String? selectedType = selectedReportType;
              if (selectedType == null || !reportTypeKeys.contains(selectedType)) {
                selectedType = reportTypeKeys.isNotEmpty ? reportTypeKeys.first : null;
              }
              final entries = selectedType != null
                  ? List<ScanEntry>.from(groupedHistory[selectedType] ?? [])
                  : <ScanEntry>[];
              if (entries.isEmpty) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: ColorPalette.greenSwatch[50],
                  ),
                  child: const Center(
                    child: Text('No scans for this report type yet.'),
                  ),
                );
              }
              final latest = entries.last;
              final metrics = latest.metrics;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips with scan button as first item (NO padding)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: reportTypeKeys.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        if (idx == 0) {
                          // Scan button as chip WITH left padding
                          return Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => getImageCamera(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ColorPalette.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
            child: Row(
              children: [
                                    Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Scan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        final type = reportTypeKeys[idx - 1];
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(
                            type.replaceAll('_report', '').replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : ColorPalette.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: ColorPalette.green,
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            if (selected)
                              setState(() {
                                selectedReportType = type;
                              });
                          },
                        );
                      },
                    ),
                  ),
                  // The rest of the section WITH padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Card for latest scan
                        Card(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                    Text(
                                            "Report",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                                              color: ColorPalette.green,
                        fontFamily: 'Mulish',
                      ),
                    ),
                                          const SizedBox(width: 8),
                                              Material(
                                                color: ColorPalette.green,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  customBorder: const CircleBorder(),
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => ReportHistoryDialog(
                                                        reportTypeKey: selectedType!,
                                                        scans: entries,
                                                        onHistoryChanged: () => setState(() {}),
                                                      ),
                                                    );
                                                  },
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(6.0),
                                                    child: Icon(Icons.history, color: Colors.white, size: 20),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                                          Text(
                                            'Date: ' +
                                                (latest.timestamp != null
                                                    ? '${latest.timestamp.year}-${latest.timestamp.month.toString().padLeft(2, '0')}-${latest.timestamp.day.toString().padLeft(2, '0')}'
                                                    : ''),
                                            style: TextStyle(
                                              color: ColorPalette.blackDarker,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Time: ' +
                                                (latest.timestamp != null
                                                    ? '${latest.timestamp.hour.toString().padLeft(2, '0')}:${latest.timestamp.minute.toString().padLeft(2, '0')}'
                                                    : ''),
                                            style: TextStyle(
                                              color: ColorPalette.blackDarker,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
                                MetricTable(
                                  metrics: metrics,
                                  onMetricTap: (metricName) =>
                                      _showMetricTrendDialog(metricName, entries),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
} 
