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
import 'package:another_telephony/telephony.dart';
import 'package:wellwiz/chat/chat_page.dart';
import 'package:wellwiz/mental_peace/mental_peace_page.dart';
import 'package:wellwiz/doctor/doctor_page.dart';
import 'package:wellwiz/quick_access/quick_access_page.dart';

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
  // Removed falldone, contacts, and all chat-related fields

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _pageController = PageController(initialPage: _selectedItemPosition);
    // Removed fall_detection and related logic
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ChatPage(
        uname: username.trim().substring(
          0,
          username.trim().indexOf(' ') == -1
              ? username.length
              : username.indexOf(' ')),
      ),
      const MentalPeacePage(),
      DoctorPage(),
      QuickAccessPage()
    ];

    return Scaffold(
      appBar:
          PreferredSize(preferredSize: Size.fromHeight(20), child: Container()),
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
