import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/secrets.dart';

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

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _loadTable();
  }

  Future<void> _loadTable() async {
    final pref = await SharedPreferences.getInstance();
    String? tableJson = pref.getString('table');
    if (tableJson != null && tableJson.isNotEmpty) {
      setState(() {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      });
    }
  }

  Future<void> getImageCamera(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Select Image Source",
            style: TextStyle(fontFamily: 'Mulish'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Camera",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
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
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Gallery",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  var image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendImageMessage() async {
    final imgBytes = await _image.readAsBytes();
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? tableJson = pref.getString("table");
    List<List<dynamic>> tableList = [];
    if (tableJson != null && tableJson.isNotEmpty) {
      try {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }
    Fluttertoast.showToast(msg: "Extracting information...");
    String prompt = """
  You are being used as a medical chatbot for demonstration purposes. 
  The user has submitted a medical report in image form, and you need to extract body chemical levels. 
  Here is the current table of body chemical levels stored as a JSON list: $tableList.

  Instructions:
  1. Extract the body chemical levels from the medical report and format them as \"Title : Value : Integer\" where:
    - \"Title\" is the name of the chemical or component. If it is written in short then write the full form or the more well-known version of that title.
    - \"Value\" is the numerical level.
    - \"Integer\" is 0, -1, or 1 depending on the following:
      - 0: Level is within the normal range
      - -1: Level is below the normal range
      - 1: Level is above the normal range

  2. Compare the extracted chemical levels against the provided table list. 
    - If a chemical level is missing from the table, or if its value has changed, return it in the response.
    - Only return those entries that either aren't found in the `tableList` or have updated values.

  Return the list of updated or new chemical levels in the format \"Title : Value : Integer\".
  If nothing is found, return \"none\".
  """;
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imgBytes),
      ])
    ];
    final response = await _model.generateContent(content);
    final responseText = response.text!.toLowerCase().trim();
    if (responseText == "none") {
      Fluttertoast.showToast(msg: "No new or updated levels found.");
      return;
    }
    try {
      List<String> entries =
          responseText.split('\n').map((e) => e.trim()).toList();
      for (var entry in entries) {
        List<String> parts = entry.split(':').map((e) => e.trim()).toList();
        if (parts.length == 3) {
          String title = parts[0];
          String value = parts[1];
          int flag = int.tryParse(parts[2]) ?? 0;
          bool found = false;
          for (var existingEntry in tableList) {
            if (existingEntry[0] == title) {
              if (existingEntry[1] != value || existingEntry[2] != flag) {
                existingEntry[1] = value;
                existingEntry[2] = flag;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            tableList.add([title, value, flag]);
          }
        }
      }
      tableJson = jsonEncode(tableList);
      await pref.setString('table', tableJson);
      Fluttertoast.showToast(msg: "Updated levels added to table.");
      setState(() {
        this.tableList = tableList;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "An unknown error occurred!");
    }
  }

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
      border: TableBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(80),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Color.fromRGBO(106, 172, 67, 1),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Chemical',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Value',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        ...tableList.map((row) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[0]),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[1]),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: () {
                  if (row[2] == 1) {
                    return const Icon(Icons.arrow_upward, color: Colors.red);
                  } else if (row[2] == -1) {
                    return const Icon(Icons.arrow_downward, color: Colors.red);
                  } else {
                    return const Icon(Icons.thumb_up_sharp,
                        color: Colors.green);
                  }
                }(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              color: Colors.grey.shade300,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isTableExpanded
                            ? Icons.arrow_drop_down_rounded
                            : Icons.arrow_right_rounded,
                        color: Color.fromARGB(255, 96, 168, 82),
                      ),
                      onPressed: () {
                        setState(() {
                          _isTableExpanded = !_isTableExpanded;
                        });
                      },
                    ),
                    Text(
                      'Health Metrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt,
                          color: Color.fromARGB(255, 96, 168, 82)),
                      onPressed: () {
                        getImageCamera(context);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: Color.fromARGB(255, 96, 168, 82)),
                      onPressed: () {
                        _deleteTableData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isTableExpanded) _buildTable(),
        ],
      ),
    );
  }
} 