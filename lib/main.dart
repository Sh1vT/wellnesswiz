import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wellwiz/features/globalScaffold/global_scaffold.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/reminder/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:wellwiz/features/reminder/workmanager_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('main.dart: Firebase.apps.length = ${Firebase.apps.length}');
  if (Firebase.apps.isEmpty) {
    print('main.dart: Initializing Firebase');
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    print('main.dart: Firebase initialized');
  } else {
    print('main.dart: Firebase already initialized');
  }

  tz.initializeTimeZones();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initialiseUser();
  }

  Future<void> initialiseUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WellWiz',
      theme: ThemeData(
        fontFamily: 'Mulish',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_user == null)
              ? const LoginScreen()
              : GlobalScaffold(),
    );
  }
}
