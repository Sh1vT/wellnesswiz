import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isSignUp = false; // Default to Login mode
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
    _checkIfUserIsReturning();
  }

  Future<void> _checkIfUserIsReturning() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Already signed in, let main app handle navigation
      return;
    }
    // If user is not signed in, but has previously completed onboarding, default to Login
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('onboardingCompleted') == true) {
      setState(() {
        isSignUp = false;
      });
    }
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
    // print('[DEBUG] Google sign-in started');
    setState(() { _isSigningIn = true; });
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: clientid, // 🔧 required
      );
      await GoogleSignIn.instance.disconnect();
      final googleUser = await GoogleSignIn.instance.authenticate();
      // print('[DEBUG] Google user: $googleUser');
      final idToken = googleUser.authentication.idToken;
      final accessToken = (await googleUser.authorizationClient.authorizationForScopes(['email']))?.accessToken;
      // print('[DEBUG] idToken: $idToken, accessToken: $accessToken');
      if (idToken == null || accessToken == null) {
        // print('[DEBUG] Missing tokens.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed: Missing tokens.')),
        );
        setState(() { _isSigningIn = false; });
        return;
      }
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      //print('[DEBUG] Firebase userCredential: $userCredential');
      // print('[DEBUG] Signed in as:  {userCredential.user?.displayName}');
      // print('[DEBUG] FirebaseAuth.currentUser: ${FirebaseAuth.instance.currentUser}');
      String? userId = userCredential.user?.uid;
      // Check if user exists in Firestore and onboarding is complete
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      // print('[DEBUG] Firestore userDoc.exists: ${userDoc.exists}, data: ${userDoc.data()}');
      
      // If user is trying to login (not sign up) and doesn't exist in Firestore, prevent login
      if (!isSignUp && !userDoc.exists) {
        // print('[DEBUG] User trying to login but account doesn\'t exist.');
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account not found. Please sign up first.')),
        );
        setState(() { _isSigningIn = false; });
        return;
      }
      
      // Prevent duplicate sign up: If in sign up mode and user exists, show error and do not proceed
      if (isSignUp && userDoc.exists && (userDoc.data()?['onboardingCompleted'] == true)) {
        // print('[DEBUG] Duplicate sign up detected.');
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This Google account is already registered. Please use Login instead.')),
        );
        setState(() { _isSigningIn = false; });
        return;
      }
      if (userDoc.exists && (userDoc.data()?['onboardingCompleted'] == true)) {
        // print('[DEBUG] Existing user, onboarding complete.');
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('username', userDoc.data()?['name'] ?? userCredential.user?.displayName ?? '');
        prefs.setString('userhandle', userDoc.data()?['handle'] ?? '');
        prefs.setString('userimg', userCredential.user?.photoURL ?? '');
        // Don't set onboardingCompleted here - let main app handle it
        // Save FCM token to Firestore
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (userId != null && fcmToken != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'fcmToken': fcmToken,
          }, SetOptions(merge: true));
        }
        setState(() { _isSigningIn = false; });
        // print('[DEBUG] Sign-in flow complete, returning.');
        return;
      }
      // If new user or onboarding not complete, require onboarding fields
      if (_nameController.text.isEmpty || _ageController.text.isEmpty || gender == null) {
        // print('[DEBUG] Missing onboarding fields.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        setState(() { _isSigningIn = false; });
        return;
      }
      if (selectedGoals.length < 3) {
        // print('[DEBUG] Not enough goals selected.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 3 goals.')),
        );
        setState(() { _isSigningIn = false; });
        return;
      }
      // Save FCM token to Firestore
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (userId != null && fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
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
      // print('[DEBUG] New user onboarding fields saved to Firestore.');
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('username', _nameController.text);
      prefs.setString('userhandle', userHandle);
      prefs.setString('userimg', googleUser.photoUrl ?? '');
      setState(() { _isSigningIn = false; });
      // print('[DEBUG] Sign-in flow complete for new user.');
    } catch (e, stack) {
      // print('[DEBUG] Google Sign-In failed: $e');
      // print(stack);
      String errorMsg = e.toString();
      if (errorMsg.contains('sign_in_canceled') || errorMsg.contains('SignInCancelledException') || errorMsg.contains('User closed') || errorMsg.contains('user_cancelled') || errorMsg.contains('user_cancelled') || errorMsg.contains('canceled')) {
        errorMsg = 'No account selected.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
    //print('[DEBUG] _signInWithGoogle finished. _isSigningIn=$_isSigningIn');
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
                                    onTap: () {
                                      setState(() {
                                        isSignUp = true;
                                        _currentPage = 0;
                                      });
                                      if (_pageController.hasClients) {
                                        _pageController.jumpToPage(0);
                                      }
                                    },
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
                                    onTap: () {
                                      setState(() {
                                        isSignUp = true;
                                        _currentPage = 0;
                                      });
                                      if (_pageController.hasClients) {
                                        _pageController.jumpToPage(0);
                                      }
                                    },
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
                      ? SizedBox(
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
                                                      '$remaining more',
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
                                      loading: _isSigningIn && _currentPage == 1,
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
                                buttontext: "Log In",
                                iconImage: const AssetImage('assets/images/googlelogo.png'),
                                loading: _isSigningIn,
                                onPressed: _isSigningIn ? null : () => _signInWithGoogle(context),
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
  });

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
