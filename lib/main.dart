import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:wellwiz/globalScaffold/global_scaffold.dart';
import 'package:wellwiz/login/login_page.dart';
import 'package:wellwiz/quick_access/content/reminder_only/notification_service.dart';
import 'package:wellwiz/quick_access/content/reminder_only/workmanager_handler.dart';
import 'package:wellwiz/utils/achievement_uploader.dart';
import 'package:wellwiz/utils/chatroom_uploader.dart';
import 'package:wellwiz/utils/hospital_utils.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wellwiz/doctor/doctor_page.dart';
import 'package:wellwiz/utils/color_palette.dart';

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

  // uploadSampleAchievements();
  // uploadSampleChatrooms();

  // Fetch user's real location and pre-populate hospital lists
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLng = position.longitude;
      final hospitals1km = await fetchNearbyHospitals(userLat: userLat, userLng: userLng, geohashPrecision: 6, maxResults: 20);
      final hospitals5kmRaw = await fetchNearbyHospitals(userLat: userLat, userLng: userLng, geohashPrecision: 5, maxResults: 20);
      final hospitals20kmRaw = await fetchNearbyHospitals(userLat: userLat, userLng: userLng, geohashPrecision: 4, maxResults: 20);
      // Deduplicate: only show hospitals in their closest tier
      final hospitals1kmSet = hospitals1km.map((h) => h.name + h.latitude.toString() + h.longitude.toString()).toSet();
      final hospitals5km = hospitals5kmRaw.where((h) => !hospitals1kmSet.contains(h.name + h.latitude.toString() + h.longitude.toString())).toList();
      final hospitals5kmSet = hospitals5km.map((h) => h.name + h.latitude.toString() + h.longitude.toString()).toSet();
      final hospitals20km = hospitals20kmRaw.where((h) =>
        !hospitals1kmSet.contains(h.name + h.latitude.toString() + h.longitude.toString()) &&
        !hospitals5kmSet.contains(h.name + h.latitude.toString() + h.longitude.toString())
      ).toList();
      DoctorPage.setupHospitals(
        within20km: hospitals20km,
        within5km: hospitals5km,
        within1km: hospitals1km,
      );
    }
  } catch (e) {
    print('Error fetching user location or hospitals: $e');
  }
  // clearOldHealthData();

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
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_user == null)
              ? const LoginScreen()
              : GlobalScaffold(),
    );
  }
}
