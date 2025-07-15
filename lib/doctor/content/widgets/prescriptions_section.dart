import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/chat/content/widgets/bot_screen.dart';

class PrescriptionsSection extends StatefulWidget {
  const PrescriptionsSection({super.key});

  @override
  State<PrescriptionsSection> createState() => _PrescriptionsSectionState();
}

class _PrescriptionsSectionState extends State<PrescriptionsSection> {
  List<List<dynamic>> prescriptionsList = [];
  bool _isPrescriptionsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final pref = await SharedPreferences.getInstance();
    String? prescriptionsJson = pref.getString('prescriptions');
    if (prescriptionsJson != null && prescriptionsJson.isNotEmpty) {
      setState(() {
        prescriptionsList = List<List<dynamic>>.from(
            jsonDecode(prescriptionsJson).map((item) => List<dynamic>.from(item)));
      });
    }
  }

  void _deletePrescriptionData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      prescriptionsList.clear();
    });
    await pref.remove('prescriptions');
  }

  Widget _buildPrescriptionsTable() {
    if (prescriptionsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade100,
        ),
        child: const Center(
          child: Text(
            textAlign: TextAlign.justify,
            'Tell WellWiz about your medicines!',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
        ),
      );
    }
    prescriptionsList.sort((a, b) => a[0].compareTo(b[0]));
    return Table(
      border: TableBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Color.fromRGBO(106, 172, 67, 1),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Medication',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Dosage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        ...prescriptionsList.map((row) {
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
                        !_isPrescriptionsExpanded
                            ? Icons.arrow_right_rounded
                            : Icons.arrow_drop_down_rounded,
                        color: Color.fromARGB(255, 96, 168, 82),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPrescriptionsExpanded = !_isPrescriptionsExpanded;
                        });
                      },
                    ),
                    Text(
                      'Prescriptions',
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
                      icon: Icon(Icons.chat_outlined,
                          color: Color.fromARGB(255, 96, 168, 82)),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return BotScreen();
                        }));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: Color.fromARGB(255, 96, 168, 82)),
                      onPressed: () {
                        _deletePrescriptionData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isPrescriptionsExpanded) _buildPrescriptionsTable(),
        ],
      ),
    );
  }
} 