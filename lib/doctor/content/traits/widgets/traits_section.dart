import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/utils/poppy_tile.dart';

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

  void _showTraitDialog(BuildContext context, {String? initialValue, String? editKey}) {
    TextEditingController _controller = TextEditingController(text: initialValue ?? '');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(editKey == null ? 'New Trait' : 'Edit Trait'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Details'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: ColorPalette.black)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: ColorPalette.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  if (editKey != null) {
                    await _editProfileValue(editKey, _controller.text);
                  } else {
                    _addProfileValue(_controller.text);
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text(editKey == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProfileValue(String key, String newValue) async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      profileMap[key] = newValue;
    });
    String updatedProfile = jsonEncode(profileMap);
    await pref.setString('prof', updatedProfile);
    _populateProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and add button row
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Traits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.black,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: Icon(Icons.add, color: Colors.white, size: 20),
              label: Text('Add', style: TextStyle(color: Colors.white, fontFamily: 'Mulish', fontWeight: FontWeight.w600)),
              backgroundColor: Color.fromARGB(255, 96, 168, 82),
              onPressed: () => _showTraitDialog(context),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          if (emptyNow)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: ColorPalette.greenSwatch[50],
              ),
              child: const Center(
                child: Text(
                  'Add something about yourself!',
                  style: TextStyle(fontFamily: 'Mulish', fontSize: 14, color: ColorPalette.black),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: profileMap.length,
              itemBuilder: (context, index) {
                String key = profileMap.keys.elementAt(index);
                String value = profileMap[key]!;
                String datePart = key.split(' ')[0];
                return PoppyTile(
                  borderRadius: 12,
                  backgroundColor: Colors.grey.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Created on : $datePart",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontFamily: 'Mulish',
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: const TextStyle(
                                color: Colors.black,
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
                          _showTraitDialog(context, initialValue: value, editKey: key);
                        },
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit, color: ColorPalette.black, size: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _deleteProfileValue(key);
                        },
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.delete, color: ColorPalette.black, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
} 