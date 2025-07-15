import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';

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

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(hintText: 'Phone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text;
                final phone = phoneController.text;
                if (name.isNotEmpty && phone.isNotEmpty) {
                  _saveContacts(ContactData(name: name, phone: phone));
                  setState(() {});
                  Navigator.pop(context);
                } else {
                  // Show snackbar or other error message for missing data
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _getPermission() async {
    await Permission.sms.request();
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUserInfo();
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "SOS",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromRGBO(106, 172, 67, 1)),
              ),
              Text(
                " Contacts",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
          SizedBox(height: 12),
          contacts.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(16),
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.shade100,
                  ),
                  child: const Center(
                    child: Text(
                      'Add some emergency contacts!',
                      style: TextStyle(fontFamily: 'Mulish'),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
          Center(
            child: Container(
              height: 42,
              width: 42,
              margin: const EdgeInsets.only(right: 12, top: 10),
              child: IconButton(
                color: Colors.green.shade500,
                onPressed: () {
                  _getPermission();
                  _showAddContactDialog();
                },
                icon: const Icon(
                  Icons.add,
                  size: 20,
                ),
              ),
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
    final List<Color> colorPalette = [
      Color.fromARGB(255, 145, 197, 123),
      Color.fromARGB(255, 96, 172, 128),
      Color.fromARGB(255, 66, 128, 113),
    ];
    Color randomColor = colorPalette[index % colorPalette.length];
    return Column(
      children: [
        SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
              // gradient: LinearGradient(colors: [randomColor, Colors.green.shade400]),
              borderRadius: BorderRadius.circular(12),
              color: randomColor),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: randomColor,
                ),
              ),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        color: Colors.white),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 10),
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDelete(index),
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
