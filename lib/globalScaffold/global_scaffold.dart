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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wellwiz/providers/page_navigation_provider.dart';

class GlobalScaffold extends ConsumerStatefulWidget {
  @override
  ConsumerState<GlobalScaffold> createState() => _GlobalScaffoldState();
}

class _GlobalScaffoldState extends ConsumerState<GlobalScaffold> {
  // int _selectedItemPosition = 0; // Remove local state
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
      username = pref.getString('username') ?? 'User';
      userimg = pref.getString('userimg') ?? 'https://ui-avatars.com/api/?name=User&background=7CB518&color=fff&size=128';
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    final selectedIndex = ref.read(pageNavigationProvider);
    _pageController = PageController(initialPage: selectedIndex);
    // Removed fall_detection and related logic
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(pageNavigationProvider);
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
            ref.read(pageNavigationProvider.notifier).state = index;
          },
          children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32), // Increased bottom padding for more space
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () {
                  ref.read(pageNavigationProvider.notifier).state = 0;
                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                },
              ),
              _NavBarItem(
                icon: Icons.self_improvement_rounded,
                label: 'Calendar',
                selected: selectedIndex == 1,
                onTap: () {
                  ref.read(pageNavigationProvider.notifier).state = 1;
                  _pageController.animateToPage(1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                },
              ),
              _NavBarItem(
                icon: Icons.supervised_user_circle_rounded,
                label: 'Alerts',
                selected: selectedIndex == 2,
                onTap: () {
                  ref.read(pageNavigationProvider.notifier).state = 2;
                  _pageController.animateToPage(2, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                },
              ),
              _NavBarItem(
                icon: Icons.settings,
                label: 'Shortcuts',
                selected: selectedIndex == 3,
                onTap: () {
                  ref.read(pageNavigationProvider.notifier).state = 3;
                  _pageController.animateToPage(3, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.transparent, // No background color for selection
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: selected ? 44 : 32, // Slightly larger when selected
                height: selected ? 44 : 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200, // Always the same background
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 4, // Reduced blur for a crisper shadow
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: selected ? Color(0xFF6AAC43) : Colors.grey.shade600,
                  size: selected ? 26 : 22,
                ),
              ),
              // Removed the label/text under the icon for a minimal look
              // const SizedBox(height: 4),
              // AnimatedDefaultTextStyle(
              //   duration: Duration(milliseconds: 250),
              //   style: TextStyle(
              //     color: selected ? Color(0xFF6AAC43) : Colors.grey.shade600,
              //     fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              //     fontSize: selected ? 13 : 12,
              //   ),
              //   child: Text(label),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
