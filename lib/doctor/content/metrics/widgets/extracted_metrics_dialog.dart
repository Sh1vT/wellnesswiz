import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'report_type_selector.dart';

final selectedTypeChipBG = ColorPalette.greenSwatch[100];
final selectedTypeChipBorder = ColorPalette.green;

class ExtractedMetricsDialog extends StatefulWidget {
  final List<List<dynamic>> extractedMetrics;
  final List<String> reportTypes;
  final String detectedType;
  final void Function(List<List<dynamic>> metrics, String selectedType) onSave;

  const ExtractedMetricsDialog({
    super.key,
    required this.extractedMetrics,
    required this.reportTypes,
    required this.detectedType,
    required this.onSave,
  });

  @override
  State<ExtractedMetricsDialog> createState() => _ExtractedMetricsDialogState();
}

class _ExtractedMetricsDialogState extends State<ExtractedMetricsDialog> {
  late String? dialogSelectedType;
  String dialogCustomType = '';
  late List<List<dynamic>> editableMetrics;
  late TextEditingController _customTypeController;
  // Add controllers for new metric
  final TextEditingController _newChemicalController = TextEditingController();
  final TextEditingController _newValueController = TextEditingController();
  String? _addError;

  @override
  void initState() {
    super.initState();
    dialogSelectedType = widget.detectedType;
    // Deep copy to allow editing
    editableMetrics = widget.extractedMetrics
        .map((row) => List<dynamic>.from(row))
        .toList();
    _customTypeController = TextEditingController(text: dialogCustomType);
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    _newChemicalController.dispose();
    _newValueController.dispose();
    super.dispose();
  }

  void _showEditValueDialog(int idx) async {
    final metric = editableMetrics[idx];
    final valueStr = metric[1].toString();
    final unit = _extractUnit(valueStr);
    final numValue = double.tryParse(_extractNumber(valueStr));
    final controller = TextEditingController(text: numValue?.toString() ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Value'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: unit),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && double.tryParse(result) != null) {
      setState(() {
        metric[1] = unit.isNotEmpty ? '$result $unit' : result;
      });
    }
  }

  String _extractNumber(String value) {
    final match = RegExp(r'([\d.]+)').firstMatch(value);
    return match?.group(1) ?? value;
  }

  String _extractUnit(String value) {
    final match = RegExp(r'([\d.]+)\s*([a-zA-Z%/]+)?').firstMatch(value);
    return match?.group(2) ?? '';
  }

  void _incrementValue(int idx, double step) {
    final metric = editableMetrics[idx];
    final valueStr = metric[1].toString();
    final numValue = double.tryParse(_extractNumber(valueStr));
    final unit = _extractUnit(valueStr);
    if (numValue != null) {
      final newValue = (numValue + step).toStringAsFixed(2);
      setState(() {
        metric[1] = unit.isNotEmpty ? '$newValue $unit' : newValue;
      });
    }
  }

  void _decrementValue(int idx, double step) {
    final metric = editableMetrics[idx];
    final valueStr = metric[1].toString();
    final numValue = double.tryParse(_extractNumber(valueStr));
    final unit = _extractUnit(valueStr);
    if (numValue != null) {
      final newValue = (numValue - step).toStringAsFixed(2);
      setState(() {
        metric[1] = unit.isNotEmpty ? '$newValue $unit' : newValue;
      });
    }
  }

  String _sanitizeChemicalName(String name) {
    // Remove asterisks, hyphens, and extra spaces, similar to sanitizer logic
    return name
        .replaceAll('*', '')
        .replaceAll('-', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Review"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
              },
              // border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade300),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Chemical',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 18.0,
                        right: 8.0,
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        'Value',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...editableMetrics.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final valueStr = row[1].toString();
                  final numValue = double.tryParse(_extractNumber(valueStr));
                  return TableRow(
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    editableMetrics.removeAt(idx);
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.07),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.close,
                                    size: 10,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _sanitizeChemicalName(row[0].toString()),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                          child: numValue != null
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 15,
                                        ),
                                        color: Colors.red,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        onPressed: () =>
                                            _decrementValue(idx, 0.1),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showEditValueDialog(idx),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 1.0,
                                            vertical: 2.0,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            maxWidth: 60,
                                          ),
                                          child: Text(
                                            valueStr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: ColorPalette.black,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 15),
                                        color: Colors.green,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        onPressed: () =>
                                            _incrementValue(idx, 0.1),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(valueStr, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            // Add new metric row
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newChemicalController,
                    decoration: InputDecoration(
                      labelText: 'Chemical',
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newValueController,
                    decoration: InputDecoration(
                      labelText: 'Value',
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final name = _newChemicalController.text.trim();
                    final value = _newValueController.text.trim();
                    if (name.isEmpty || value.isEmpty) {
                      setState(() { _addError = 'Both fields required.'; });
                      return;
                    }
                    // Accept value with optional unit (e.g. 5.2, 5.2 mg/dL)
                    final numPart = RegExp(r'^([\d.]+)').firstMatch(value)?.group(1);
                    if (numPart == null || double.tryParse(numPart) == null) {
                      setState(() { _addError = 'Value must start with a number.'; });
                      return;
                    }
                    setState(() {
                      editableMetrics.add([name, value, 0]);
                      _newChemicalController.clear();
                      _newValueController.clear();
                      _addError = null;
                    });
                  },
                  child: const Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (_addError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(_addError!, style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            Divider(thickness: 1.2, color: Colors.grey, height: 24),
            const SizedBox(height: 8),
            ReportTypeSelector(
              reportTypes: widget.reportTypes,
              selectedType: dialogSelectedType,
              onSelected: (type) => setState(() {
                dialogSelectedType = type;
                if (type != 'Custom') {
                  dialogCustomType = '';
                  _customTypeController.text = '';
                }
              }),
              customType: dialogCustomType,
              onCustomChanged: (val) => setState(() {
                dialogCustomType = val;
                _customTypeController.value = TextEditingValue(
                  text: val,
                  selection: TextSelection.collapsed(offset: val.length),
                );
              }),
              controller: _customTypeController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ColorPalette.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: ColorPalette.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            widget.onSave(
              editableMetrics,
              dialogSelectedType == 'Custom'
                  ? dialogCustomType
                  : (dialogSelectedType ?? ''),
            );
            Navigator.of(context).pop();
          },
          child: const Text(
            "Save",
            style: TextStyle(color: Colors.white, fontFamily: 'Mulish'),
          ),
        ),
      ],
    );
  }
}
