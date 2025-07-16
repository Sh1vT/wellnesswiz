import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TraitsSection extends StatefulWidget {
  const TraitsSection({super.key});

  @override
  State<TraitsSection> createState() => _TraitsSectionState();
}

class _TraitsSectionState extends State<TraitsSection> {
  Map<String, String> profileMap = {};
  bool emptyNow = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _populateProfile();
  }

  void _populateProfile() async {
    final pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof') ?? "";
    if (prefval.isEmpty || prefval == "{}") {
      setState(() {
        emptyNow = true;
      });
    } else {
      setState(() {
        profileMap = Map<String, String>.from(jsonDecode(prefval));
        emptyNow = false;
      });
    }
  }

  void _deleteProfileValue(String key) async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      profileMap.remove(key);
    });
    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
    _populateProfile();
  }

  void _addProfileValue(String newValue) async {
    final pref = await SharedPreferences.getInstance();
    String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    setState(() {
      profileMap[currentDateTime] = newValue;
      emptyNow = false;
    });
    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
    _populateProfile();
  }

  void _showAddProfileDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Profile Entry'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Enter profile detail'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addProfileValue(_controller.text);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          icon: Icon(
                            !_isExpanded
                                ? Icons.arrow_right_rounded
                                : Icons.arrow_drop_down_rounded,
                            color: Color.fromARGB(255, 96, 168, 82),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Your Traits',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_box_outlined,
                        color: Color.fromARGB(255, 96, 168, 82)),
                    onPressed: () {
                      _showAddProfileDialog(context);
                    },
                  ),
                ],
              ),
            ),
            if (_isExpanded) ...[
              SizedBox(height: 15),
              emptyNow
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.shade100,
                      ),
                      child: const Center(
                        child: Text(
                          'Add something about yourself!',
                          style: TextStyle(fontFamily: 'Mulish'),
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      child: ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: profileMap.length,
                        itemBuilder: (context, index) {
                          String key = profileMap.keys.elementAt(index);
                          String value = profileMap[key]!;
                          String datePart = key.split(' ')[0];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 96, 168, 82),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Created on : $datePart",
                                          style: TextStyle(
                                            color: Colors.grey.shade100,
                                            fontFamily: 'Mulish',
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          value,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Mulish',
                                            fontSize: 16,
                                          ),
                                          maxLines: null,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _deleteProfileValue(key);
                                    },
                                    icon: Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              SizedBox(height: 15),
            ],
          ],
        ),
      ),
    );
  }
} 