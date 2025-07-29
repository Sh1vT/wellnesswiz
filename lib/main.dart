import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:wellwiz/globalScaffold/global_scaffold.dart';
import 'package:wellwiz/login/login_page.dart';
import 'package:wellwiz/providers/user_info_provider.dart';
import 'package:wellwiz/quick_access/content/reminder_only/workmanager_notification_fallback.dart' show callbackDispatcher;
import 'package:workmanager/workmanager.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/onboarding/app_tour_screen.dart';
import 'package:wellwiz/globalScaffold/splash_screen.dart';
import 'package:wellwiz/utils/app_initializer.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// void main() => test.main();
Future<void> clearEmotionMonitorData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('emotion_monitor_data');
  //print('[Main] Cleared emotion_monitor_data from SharedPreferences');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  //print('main.dart: Firebase.apps.length = ${Firebase.apps.length}');
  if (Firebase.apps.isEmpty) {
    //print('main.dart: Initializing Firebase');
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    //print('main.dart: Firebase initialized');
  } else {
    //print('main.dart: Firebase already initialized');
  }

  tz.initializeTimeZones();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // final NotificationService notificationService = NotificationService();
  // await notificationService.init();

  // uploadSampleAchievements();
  // uploadSampleChatrooms();

  // clearOldHealthData();
  // await clearEmotionMonitorData();


  // await ThoughtUploader.uploadThoughts(ThoughtUploader.sampleThoughts);
  // await ExerciseMusicUploader.uploadMusics(ExerciseMusicUploader.sampleMusics);

  runApp(ProviderScope(child: MyApp()));
}

void clearOldHealthData() async {
  final pref = await SharedPreferences.getInstance();
  await pref.remove('scan_history');
  await pref.remove('scan_grouped_history');
  await pref.remove('prof');
  await pref.remove('contacts');
  await pref.remove('table');
  Fluttertoast.showToast(msg: "Old app data cleared.");
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  User? _user;
  bool _isLoading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _showSplashAndInit();
    
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _handleAuthStateChange(user);
      }
    });
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
      //print('DEBUG: Current user:  [38;5;10m [1m [4m [3m [9m${user?.uid} [0m');
      
      if (user != null) {
        // User is logged in - check if onboarding is complete in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool('onboardingCompleted') ?? false;
        //print('DEBUG: SharedPreferences onboarding status: $onboardingDone');
        
        if (onboardingDone) {
          // Onboarding complete - user can go directly to app
          //print('DEBUG: Onboarding complete, going to app directly');
          _user = user;
          _onboardingComplete = true;
          await initializeAppStartup();
          // Await user info loading here!
          await ref.read(userInfoProvider.notifier).loadUserInfo();
        } else {
          // User logged in but onboarding not complete - show onboarding
          //print('DEBUG: Onboarding not complete, showing onboarding');
          _user = user;
          _onboardingComplete = false;
        }
      } else {
        // No user logged in - show login screen, then onboarding
        //print('DEBUG: No user logged in, showing login screen');
        _user = null;
        _onboardingComplete = false;
      }
      // REMOVE: await UserInfoCache.getUserInfo();
    } catch (e) {
      //print('DEBUG: Error in _checkAuthAndOnboarding: $e');
      // If any error, default to login flow
      _user = null;
      _onboardingComplete = false;
    }
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (user != null && _user == null) {
      // User just logged in
      
      // Temporary: Clear Firebase onboarding status for testing
      // await clearFirebaseOnboardingStatus(); // This line is removed
      
      await _checkAuthAndOnboarding();
      setState(() {});
    } else if (user == null && _user != null) {
      // User just logged out
      setState(() {
        _user = null;
        _onboardingComplete = false;
      });
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
          onPrimary: Colors.white,
          onSecondary: Colors.white,
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
                    
                    // Show splash screen while initializing app
                    rootNavigatorKey.currentState?.pushReplacement(
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                    );
                    
                    // Run initialization in background
                    await initializeAppStartup();
                    
                    // Navigate to main app after initialization
                    rootNavigatorKey.currentState?.pushReplacement(
                      MaterialPageRoute(builder: (_) => GlobalScaffold()),
                    );
                  },
                ),
    );
  }
}
