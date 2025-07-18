import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';

class SOSAlertButton extends StatefulWidget {
  const SOSAlertButton({super.key});

  @override
  State<SOSAlertButton> createState() => _SOSAlertButtonState();
}

class _SOSAlertButtonState extends State<SOSAlertButton> {
  bool falldone = false;
  final Telephony telephony = Telephony.instance;
  List contacts = [];

  Future<void> sendSOSMessages(List<String> recipients, String message) async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      Fluttertoast.showToast(msg: "SMS permission not granted");
      return;
    }
    for (final number in recipients) {
      await telephony.sendSms(
        to: number,
        message: message,
      );
    }
    Fluttertoast.showToast(msg: "SOS ALERT SENT TO ALL CONTACTS");
  }

  Future<void> _sendEmergencyMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getString('contacts');
    final decodedContacts = jsonDecode(encodedContacts!) as List;
    contacts.clear();
    contacts.addAll(decodedContacts.map((c) => ContactData.fromJson(c)).toList());
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    List<String> recipients = contacts.map<String>((c) => "+91${c.phone}").toList();
    String message =
        "I am facing some critical medical condition. Please call an ambulance or arrive here: https://www.google.com/maps/place/$lat+$lng";
    await sendSOSMessages(recipients, message);
    launchUrl(Uri.parse("tel:108"));
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Needed'),
          content: const Text('Location access is required to send your location to emergency contacts. It is only used for SOS and nothing else.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return false;
    }
    return true;
  }

  _sosprotocol() async {
    if (!await _ensureLocationPermission()) return;
    bool popped = false;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Are you okay?"),
            content: const Text(
              "You just pressed the SOS button. This button is used to trigger emergency. Please tell us if you're fine. Or else the emergency contacts will be informed.",
              textAlign: TextAlign.justify,
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color.fromARGB(255, 106, 172, 67)),
                onPressed: () {
                  falldone = false;
                  setState(() {
                    falldone = false;
                    popped = true;
                    Navigator.pop(context);
                  });
                  return;
                },
                child: const Text(
                  "I'm fine",
                  style: TextStyle(
                      fontFamily: 'Mulish',
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          );
        });
    await Future.delayed(const Duration(seconds: 10));
    if (popped == false) {
      _sendEmergencyMessage();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _sosprotocol,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 80,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          child: Center(
            child: Row(
              children: [
                const Icon(
                  Icons.alarm,
                  size: 40,
                  color: Colors.red,
                ),
                const SizedBox(
                  width: 20,
                ),
                Row(
                  children: [
                    Text(
                      'Send ',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    Text('Alerts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 18,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ],
                ),
                Spacer(),
                const Icon(
                  Icons.navigate_next_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
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

  factory ContactData.fromJson(Map<String, dynamic> json) => ContactData(
        name: json['name'] as String,
        phone: json['phone'] as String,
      );
} 