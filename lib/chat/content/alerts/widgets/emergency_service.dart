import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/utils/color_palette.dart';
// import 'package:wellwiz/features/bot/bot_screen.dart'; // Not needed in modular

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final List<ContactData> contacts = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  Future<void> _saveContacts(ContactData contactData) async {
    final prefs = await SharedPreferences.getInstance();
    contacts.add(contactData);
    final encodedContacts =
        jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString('contacts', encodedContacts);
    debugPrint('Contact: $encodedContacts');
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getString('contacts');
    if (encodedContacts != null) {
      final decodedContacts = jsonDecode(encodedContacts) as List;
      setState(() {
        contacts.clear();
        contacts.addAll(
            decodedContacts.map((c) => ContactData.fromJson(c)).toList());
      });
    }
  }

  void _removeContact(int index) {
    if (index >= 0 && index < contacts.length) {
      setState(() {
        contacts.removeAt(index);
        _saveContactsAfterDelete(contacts);
      });
    }
  }

  Future<void> _saveContactsAfterDelete(List<ContactData> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedContacts =
        jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString('contacts', encodedContacts);
    debugPrint('Updated Contact List: $encodedContacts');
  }

  void _showAddContactDialog() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      // Permission already granted, proceed
      await _showContactPicker();
      return;
    }
    final result = await Permission.contacts.request();
    if (result.isGranted) {
      await _showContactPicker();
      return;
    } else if (result.isPermanentlyDenied) {
      // Show a dialog explaining why permission is needed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contacts Permission Needed'),
          content: const Text('This app needs access to your contacts to add emergency contacts. Please enable contacts permission in settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    } else {
      // Permission denied (not permanently), optionally show a rationale or do nothing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied. Cannot add contacts.')),
      );
      return;
    }
  }

  Future<void> _showContactPicker() async {
    final List<Contact> allContacts = await FlutterContacts.getContacts(withProperties: true);
    final Set<int> selectedIndexes = {};
    final TextEditingController searchController = TextEditingController();
    List<int> filteredIndexes = List.generate(allContacts.length, (i) => i);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorPalette.black, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Select Contacts',
                    style: TextStyle(
                      color: ColorPalette.blackDarker,
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: ColorPalette.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(selectedIndexes.toList());
                        },
                        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: Colors.white,
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search contacts',
                        prefixIcon: Icon(Icons.search, color: ColorPalette.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                      onChanged: (query) {
                        setState(() {
                          filteredIndexes = List.generate(allContacts.length, (i) => i).where((i) {
                            final contact = allContacts[i];
                            final name = contact.displayName.toLowerCase();
                            final phone = (contact.phones.isNotEmpty) ? contact.phones.first.number : '';
                            return name.contains(query.toLowerCase()) || phone.contains(query);
                          }).toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredIndexes.length,
                      itemBuilder: (context, idx) {
                        final index = filteredIndexes[idx];
                        final contact = allContacts[index];
                        final name = contact.displayName;
                        final phone = (contact.phones.isNotEmpty) ? contact.phones.first.number : null;
                        if (phone == null) return const SizedBox.shrink();
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: ColorPalette.blackDarker,
                                          fontFamily: 'Mulish',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        phone,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontFamily: 'Mulish',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: selectedIndexes.contains(index),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedIndexes.add(index);
                                      } else {
                                        selectedIndexes.remove(index);
                                      }
                                    });
                                  },
                                  activeColor: ColorPalette.green,
                                  side: const BorderSide(color: ColorPalette.black, width: 2),
                                  checkColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((selected) async {
      if (selected is List) {
        for (final idx in selected) {
          final contact = allContacts[idx];
          final name = contact.displayName;
          final phone = (contact.phones.isNotEmpty) ? contact.phones.first.number : null;
          if (phone != null) {
            await _saveContacts(ContactData(name: name, phone: phone));
          }
        }
        setState(() {});
      }
    });
  }

  void _getPermission() async {
    await Permission.sms.request();
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "SOS",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: ColorPalette.green),
              ),
              Text(
                " Contacts",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: ColorPalette.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: ColorPalette.green,
                onPressed: _showAddContactDialog,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: ColorPalette.greenSwatch[50],
              ),
              child: const Text(
                'Add some emergency contacts!',
                style: TextStyle(fontFamily: 'Mulish', fontSize: 15, color: ColorPalette.black),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (contacts.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ContactWidget(
                    name: contacts[index].name,
                    phone: contacts[index].phone,
                    onDelete: _removeContact,
                    index: index,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ContactData {
  final String name;
  final String phone;

  const ContactData({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };

  factory ContactData.fromJson(Map<String, dynamic> json) => ContactData(
        name: json['name'] as String,
        phone: json['phone'] as String,
      );
}

class ContactWidget extends StatelessWidget {
  final String name;
  final String phone;
  final int index;
  final void Function(int) onDelete;

  const ContactWidget(
      {super.key,
      required this.name,
      required this.phone,
      required this.onDelete,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: ColorPalette.blackDarker,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.delete, color: ColorPalette.black, size: 18),
              ),
              onPressed: () => onDelete(index),
              tooltip: 'Delete',
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
} 