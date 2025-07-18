import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/globalScaffold/global_scaffold.dart';
import 'package:wellwiz/login/sign_in_button.dart';
import 'package:wellwiz/secrets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? gender;
  List<String> selectedGoals = [];
  final List<String> allGoals = [
    'Better Sleep', 'Stress Reduction', 'Fitness', 'Medication Adherence', 'Healthy Eating', 'Mental Peace', 'Weight Loss', 'Quit Smoking', 'Other'
  ];
  bool _isSigningIn = false;
  bool isSignUp = true;
  String? previewHandle;

  void _updateHandlePreview() {
    String baseHandle = _nameController.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String randomDigits = (Random().nextInt(900) + 100).toString();
    setState(() {
      previewHandle = baseHandle.isNotEmpty ? baseHandle + randomDigits : null;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateHandlePreview);
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.isEmpty || _ageController.text.isEmpty || gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        return;
      }
    }
    if (_currentPage < 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }
    if (selectedGoals.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 goals.')),
      );
      return;
    }
    setState(() { _isSigningIn = true; });
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: clientid, // 🔧 required
      );
      await GoogleSignIn.instance.disconnect();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      final accessToken = (await googleUser.authorizationClient.authorizationForScopes(['email']))?.accessToken;
      if (idToken == null || accessToken == null) {
        print("Missing tokens.");
        setState(() { _isSigningIn = false; });
        return;
      }
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print("Signed in as:  {userCredential.user?.displayName}");
      // Save FCM token to Firestore
      String? userId = userCredential.user?.uid;
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (userId != null && fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
        print('[DEBUG] FCM token saved to Firestore for user: $userId');
      }
      // Generate user handle
      String baseHandle = _nameController.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      String randomDigits = (Random().nextInt(900) + 100).toString();
      String userHandle = baseHandle + randomDigits;
      // Save onboarding fields to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid ?? '').set({
        'name': _nameController.text,
        'email': userCredential.user?.email ?? '',
        'profilePicUrl': userCredential.user?.photoURL ?? '',
        'age': int.tryParse(_ageController.text),
        'gender': gender,
        'goals': selectedGoals,
        'handle': userHandle,
        'onboardingCompleted': true,
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('username', _nameController.text);
      prefs.setString('userhandle', userHandle);
      prefs.setString('userimg', googleUser.photoUrl ?? '');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GlobalScaffold()),
      );
    } catch (e) {
      print("Google Sign-In failed: $e");
    }
    setState(() { _isSigningIn = false; });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 350),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: isSignUp
                      ? Column(
                          key: const ValueKey('signup-header'),
                          children: [
                            const SizedBox(height: 20),
                            ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpeg',
                                height: 100,
                                width: 100,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Well",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                      fontSize: 40,
                                      color: Color.fromRGBO(180, 207, 126, 1)),
                                ),
                                Text(
                                  "Wiz",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                      fontSize: 40,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Toggle for Sign Up / Login
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => isSignUp = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSignUp ? ColorPalette.green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: isSignUp ? Colors.white : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => isSignUp = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !isSignUp ? ColorPalette.green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          color: !isSignUp ? Colors.white : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('login-header'),
                          children: [
                            const SizedBox(height: 20),
                            ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpeg',
                                height: 100,
                                width: 100,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Well",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                      fontSize: 40,
                                      color: Color.fromRGBO(180, 207, 126, 1)),
                                ),
                                Text(
                                  "Wiz",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                      fontSize: 40,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Toggle for Sign Up / Login
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => isSignUp = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSignUp ? ColorPalette.green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: isSignUp ? Colors.white : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => isSignUp = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !isSignUp ? ColorPalette.green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          color: !isSignUp ? Colors.white : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 350),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: isSignUp
                      ? Container(
                          key: const ValueKey('signup'),
                          height: 420,
                          child: Stack(
                            children: [
                              PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (i) => setState(() => _currentPage = i),
                                children: [
                                  // Page 1: About You
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text('About You', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 24)),
                                        const SizedBox(height: 24),
                                        TextField(
                                          controller: _nameController,
                                          style: const TextStyle(fontFamily: 'Mulish'),
                                          decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(fontFamily: 'Mulish')),
                                        ),
                                        if (previewHandle != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4, left: 4),
                                            child: Text(
                                              '@$previewHandle',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontFamily: 'Mulish',
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _ageController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontFamily: 'Mulish'),
                                          decoration: const InputDecoration(labelText: 'Age', labelStyle: TextStyle(fontFamily: 'Mulish')),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Text('Gender', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600)),
                                            Spacer(),
                                            _GenderIconButton(
                                              icon: Icons.male_rounded,
                                              selected: gender == 'Male',
                                              onTap: () => setState(() => gender = 'Male'),
                                            ),
                                            const SizedBox(width: 8),
                                            _GenderIconButton(
                                              icon: Icons.female_rounded,
                                              selected: gender == 'Female',
                                              onTap: () => setState(() => gender = 'Female'),
                                            ),
                                            const SizedBox(width: 8),
                                            _GenderIconButton(
                                              icon: Icons.transgender_rounded,
                                              selected: gender == 'Transgender',
                                              onTap: () => setState(() => gender = 'Transgender'),
                                            ),
                                            const SizedBox(width: 8),
                                            _GenderIconButton(
                                              icon: Icons.question_mark_rounded,
                                              selected: gender == 'Rather not say',
                                              onTap: () => setState(() => gender = 'Rather not say'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                  // Page 2: Wellness Goals
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('Goals', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 24)),
                                            const SizedBox(width: 8),
                                            Builder(
                                              builder: (context) {
                                                final remaining = 3 - selectedGoals.length;
                                                if (remaining > 0) {
                                                  return Transform.translate(
                                                    offset: const Offset(0, -10), // Move up for superscript effect
                                                    child: Text(
                                                      '${remaining} more',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.redAccent,
                                                        fontWeight: FontWeight.w600,
                                                        fontFamily: 'Mulish',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return SizedBox.shrink();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Wrap(
                                          spacing: 8,
                                          children: allGoals.map((goal) {
                                            final selected = selectedGoals.contains(goal);
                                            return ChoiceChip(
                                              label: Text(goal, style: const TextStyle(fontFamily: 'Mulish')),
                                              selected: selected,
                                              selectedColor: ColorPalette.green,
                                              backgroundColor: Colors.grey[200],
                                              onSelected: (isSelected) {
                                                setState(() {
                                                  if (isSelected) {
                                                    selectedGoals.add(goal);
                                                  } else {
                                                    selectedGoals.remove(goal);
                                                  }
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 32,
                                right: 24,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_currentPage > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.grey.shade700,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(32),
                                              side: BorderSide(color: Colors.grey.shade700, width: 2),
                                            ),
                                          ),
                                          onPressed: _isSigningIn ? null : () {
                                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                          },
                                          child: const Text('Prev', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    SignInButton(
                                      buttontext: _currentPage < 1 ? "Next" : "Sign In",
                                      iconImage: _currentPage < 1 ? null : const AssetImage('assets/images/googlelogo.png'),
                                      onPressed: _isSigningIn
                                          ? null
                                          : () {
                                              if (_currentPage < 1) {
                                                _nextPage();
                                              } else {
                                                _signInWithGoogle(context);
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          key: const ValueKey('login'),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SignInButton(
                                buttontext: "Sign In",
                                iconImage: const AssetImage('assets/images/googlelogo.png'),
                                onPressed: _isSigningIn ? null : () => _signInWithGoogle(context),
                              ),
                              if (_isSigningIn)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderIconButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? ColorPalette.green : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ColorPalette.green : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey.shade700),
        ),
      ),
    );
  }
}
