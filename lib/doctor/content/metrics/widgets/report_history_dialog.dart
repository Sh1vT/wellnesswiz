import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:wellwiz/doctor/content/metrics/models/scan_entry.dart';
import 'package:wellwiz/utils/color_palette.dart';

class ReportHistoryDialog extends StatefulWidget {
  final String reportTypeKey;
  final List<ScanEntry> scans;
  final VoidCallback onHistoryChanged;
  const ReportHistoryDialog({
    super.key,
    required this.reportTypeKey,
    required this.scans,
    required this.onHistoryChanged,
  });

  @override
  State<ReportHistoryDialog> createState() => _ReportHistoryDialogState();
}

class _ReportHistoryDialogState extends State<ReportHistoryDialog> {
  late List<ScanEntry> _scans;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _scans = List<ScanEntry>.from(widget.scans);
  }

  Future<void> _deleteScan(int index) async {
    setState(() => _deleting = true);
    final pref = await SharedPreferences.getInstance();
    String? groupedJson = pref.getString('scan_grouped_history');
    if (groupedJson != null && groupedJson.isNotEmpty) {
      final groupedHistory = jsonDecode(groupedJson);
      final key = widget.reportTypeKey;
      if (groupedHistory.containsKey(key)) {
        List<dynamic> scans = List<dynamic>.from(groupedHistory[key]);
        scans.removeAt(index);
        if (scans.isEmpty) {
          groupedHistory.remove(key);
        } else {
          groupedHistory[key] = scans;
        }
        await pref.setString(
          'scan_grouped_history',
          jsonEncode(groupedHistory),
        );
        setState(() {
          _scans.removeAt(index);
          _deleting = false;
        });
        widget.onHistoryChanged();
      }
    }
  }

  Future<void> _deleteAll() async {
    setState(() => _deleting = true);
    final pref = await SharedPreferences.getInstance();
    String? groupedJson = pref.getString('scan_grouped_history');
    if (groupedJson != null && groupedJson.isNotEmpty) {
      final groupedHistory = jsonDecode(groupedJson);
      final key = widget.reportTypeKey;
      if (groupedHistory.containsKey(key)) {
        groupedHistory.remove(key);
        await pref.setString(
          'scan_grouped_history',
          jsonEncode(groupedHistory),
        );
        setState(() {
          _scans.clear();
          _deleting = false;
        });
        widget.onHistoryChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [const Text('History')],
      ),
      content: SizedBox(
        width: 350,
        child: _scans.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No scans for this report type.'),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _scans.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final scan =
                      _scans[_scans.length - 1 - idx]; // Most recent first
                  return ListTile(
                    title: Text(
                      DateFormat('yyyy-MM-dd – kk:mm').format(scan.timestamp),
                    ),
                    subtitle: Text('${scan.metrics.length} metrics'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete this scan',
                      onPressed: _deleting
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Scan'),
                                  content: const Text('Delete this scan?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            ColorPalette.blackDarker,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red.shade400,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deleteScan(_scans.length - 1 - idx);
                              }
                            },
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (_scans.isNotEmpty)
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.delete_forever, size: 20),
            label: const Text('Delete All'),
            onPressed: _deleting
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete All Reports'),
                        content: const Text(
                          'Are you sure you want to delete all scans for this report type?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorPalette.blackDarker,
                            ),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteAll();
                      Navigator.of(context).pop();
                    }
                  },
          ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(ColorPalette.green),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
