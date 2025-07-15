import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wellwiz/features/emergency/emergency_service.dart';
import 'package:wellwiz/features/pages/chat_home_page.dart';
import 'package:wellwiz/features/pages/diagnosis_page.dart';
import 'package:wellwiz/features/pages/mental_peace_page.dart';
import 'package:wellwiz/features/pages/shortcuts_page.dart';
import 'package:another_telephony/telephony.dart';

class GlobalScaffold extends StatefulWidget {
  @override
  _GlobalScaffoldState createState() => _GlobalScaffoldState();
}

class _GlobalScaffoldState extends State<GlobalScaffold> {
  int _selectedItemPosition = 0;
  SnakeBarBehaviour snakeBarStyle = SnakeBarBehaviour.pinned;
  SnakeShape snakeShape = SnakeShape.circle;
  bool showSelectedLabels = false;
  bool showUnselectedLabels = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";
  late PageController _pageController;
  bool falldone = false;
  List contacts = [];

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
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
          title: Text('Location Permission Needed'),
          content: Text('Location access is required to send your location to emergency contacts. It is only used for SOS and nothing else.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
      return false;
    }
    return true;
  }

  final Telephony telephony = Telephony.instance;

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
    if (!await _ensureLocationPermission()) return;
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

  _fallprotocol() async {
    setState(() {
      falldone = true;
    });
    bool popped = false;
    print(falldone);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Fall detected",
              style: TextStyle(fontFamily: 'Mulish'),
            ),
            content: Text(
              "We just detected a fall from your device. Please tell us if you're fine. Or else the emergency contacts will be informed.",
              style: TextStyle(fontFamily: 'Mulish'),
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
                  print("falldone val $falldone");
                  return;
                },
                child: Text(
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
    await Future.delayed(Duration(seconds: 10));
    // print("poppedvalue : $popped");
    if (popped == false) {
      _sendEmergencyMessage();
      // print("didnt respond");
      setState(() {
        falldone = false;
      });
      Navigator.pop(context);
    }
    // print("Wait complete");
  }

  void fall_detection() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      num _accelX = event.x.abs();
      num _accelY = event.y.abs();
      num _accelZ = event.z.abs();
      num x = pow(_accelX, 2);
      num y = pow(_accelY, 2);
      num z = pow(_accelZ, 2);
      num sum = x + y + z;
      num result = sqrt(sum);
      if ((result < 1) ||
          (result > 70 && _accelZ > 60 && _accelX > 60) ||
          (result > 70 && _accelX > 60 && _accelY > 60)) {
        print("FALL DETECTED");
        print(falldone);
        if (falldone == false) {
          _fallprotocol();
        }
        return;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _pageController = PageController(initialPage: _selectedItemPosition);
    fall_detection();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ChatHomePage(
          uname: username.trim().substring(
              0,
              username.trim().indexOf(' ') == -1
                  ? username.length
                  : username.indexOf(' '))),
      PeacePage(),
      DiagnosisPage(),
      ShortcutsPage()
    ];

    return Scaffold(
      appBar:
          PreferredSize(preferredSize: Size.fromHeight(20), child: Container()),
      // drawer: Navbar(
      //   userId: _auth.currentUser?.uid ?? '',
      //   username: username,
      //   userimg: userimg,
      // ),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedItemPosition = index;
            });
          },
          children: _pages),
      bottomNavigationBar: SnakeNavigationBar.color(
        backgroundColor: Colors.grey.shade300,
        behaviour: snakeBarStyle,
        snakeShape: snakeShape,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        ),
        snakeViewColor: const Color.fromARGB(
          255,
          106,
          172,
          67,
        ),
        selectedItemColor: SnakeShape.indicator == snakeShape
            ? const Color.fromARGB(
                255,
                106,
                172,
                67,
              )
            : null,
        showUnselectedLabels: showUnselectedLabels,
        showSelectedLabels: showSelectedLabels,
        currentIndex: _selectedItemPosition,
        onTap: (index) {
          setState(() {
            _selectedItemPosition = index;
          });
          _pageController.animateToPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Shortcuts',
          ),
        ],
      ),
    );
  }
}
