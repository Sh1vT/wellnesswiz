import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:wellwiz/globalScaffold/global_scaffold.dart';
import 'package:wellwiz/login/login_page.dart';
import 'package:wellwiz/quick_access/content/reminder_only/workmanager_notification_fallback.dart' show callbackDispatcher;
import 'package:wellwiz/utils/achievement_uploader.dart';
import 'package:wellwiz/utils/chatroom_uploader.dart';
import 'package:wellwiz/utils/hospital_utils.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wellwiz/doctor/doctor_page.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wellwiz/onboarding/app_tour_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/globalScaffold/splash_screen.dart';
import 'package:wellwiz/utils/app_initializer.dart';
import 'package:wellwiz/utils/user_info_cache.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// void main() => test.main();
Future<void> clearEmotionMonitorData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('emotion_monitor_data');
  print('[Main] Cleared emotion_monitor_data from SharedPreferences');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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

  // FCM setup
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
  print('FCM permission status: ${settings.authorizationStatus}');
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: ${fcmToken ?? "(null)"}');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('FCM onMessage: ${message.notification?.title} - ${message.notification?.body}');
  });

  tz.initializeTimeZones();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // final NotificationService notificationService = NotificationService();
  // await notificationService.init();

  // uploadSampleAchievements();
  // uploadSampleChatrooms();

  // clearOldHealthData();
  // await clearEmotionMonitorData();

  runApp(ProviderScope(child: MyApp()));
}

void clearOldHealthData() async {
  final pref = await SharedPreferences.getInstance();
  await pref.remove('scan_history');
  await pref.remove('scan_grouped_history');
  await pref.remove('prof');
  await pref.remove('contacts');
  await pref.remove('table');
  Fluttertoast.showToast(msg: "Old health/profile data cleared.");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  bool _isLoading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _showSplashAndInit();
  }

  Future<void> _showSplashAndInit() async {
    // Start both splash delay and auth/onboarding check in parallel
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _checkAuthAndOnboarding(),
    ]);
    setState(() { _isLoading = false; });
  }

  Future<void> _checkAuthAndOnboarding() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _user = null;
        _onboardingComplete = false;
        await initializeAppStartup();
        await UserInfoCache.getUserInfo();
        return;
      }
      // Check onboarding status in Firebase
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final onboardingDone = doc.data()?['onboardingCompleted'] == true;
      // Fallback to local storage if needed
      final prefs = await SharedPreferences.getInstance();
      final localOnboarding = prefs.getBool('onboardingCompleted') ?? false;
      _user = user;
      _onboardingComplete = onboardingDone || localOnboarding;
      await initializeAppStartup();
      await UserInfoCache.getUserInfo();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: SplashScreen(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WellWiz',
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        fontFamily: 'Mulish',
        scaffoldBackgroundColor: Colors.white,
        primaryColor: ColorPalette.green,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: ColorPalette.greenSwatch,
          backgroundColor: Colors.white,
        ).copyWith(
          primary: ColorPalette.green,
          secondary: ColorPalette.green,
          background: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: ColorPalette.black,
          surface: Colors.white,
          onSurface: ColorPalette.blackDarker,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ColorPalette.black,
          displayColor: ColorPalette.blackDarker,
        ),
        useMaterial3: true,
      ),
      home: _user == null
          ? LoginScreen()
          : _onboardingComplete
              ? GlobalScaffold()
              : AppTourScreen(
                  onFinish: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboardingCompleted', true);
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                        {'onboardingCompleted': true},
                        SetOptions(merge: true),
                      );
                    }
                    rootNavigatorKey.currentState?.pushReplacement(
                      MaterialPageRoute(builder: (_) => GlobalScaffold()),
                    );
                  },
                ),
    );
  }
}
