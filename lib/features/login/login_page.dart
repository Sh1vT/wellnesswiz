import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/globalScaffold/global_scaffold.dart';
import 'package:wellwiz/features/login/sign_in_button.dart';
import 'package:wellwiz/secrets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: clientid, // 🔧 required
    );

    await GoogleSignIn.instance.disconnect();
    // await GoogleSignIn.instance.signOut(); // Optional: force re-auth

    final googleUser = await GoogleSignIn.instance.authenticate();

    final idToken = googleUser.authentication.idToken;
    final accessToken = (await googleUser.authorizationClient.authorizationForScopes(['email']))?.accessToken;

    if (idToken == null || accessToken == null) {
      print("Missing tokens.");
      return;
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    print("Signed in as: ${userCredential.user?.displayName}");

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', googleUser.displayName ?? '');
    prefs.setString('userimg', googleUser.photoUrl ?? '');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GlobalScaffold()),
    );
  } catch (e) {
    print("Google Sign-In failed: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromRGBO(161, 188, 117, 1),
              width: 10.0,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Container(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 100,
                      width: 100,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
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
                      "Wisher",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          fontSize: 40,
                          color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SignInButton(
                  buttontext: ("Sign In"),
                  iconImage: const AssetImage('assets/images/googlelogo.png'),
                  onPressed: () {
                    // TODO: Implement Google Sign-In and remove Navigator.push in favor of StreamBuilder in SplashScreen
                    _signInWithGoogle(context);
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => const GlobalScaffold()));
                  },
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Made with ",
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        color: Color.fromRGBO(64, 52, 52, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.favorite,
                      color: Colors.green.shade600,
                    ),
                    Text(
                      " by Can-do Crew",
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        color: Color.fromRGBO(64, 52, 52, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 4,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
