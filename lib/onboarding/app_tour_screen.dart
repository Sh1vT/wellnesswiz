import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as GeolocatorPlatform;
import 'package:permission_handler/permission_handler.dart';

class AppTourScreen extends StatefulWidget {
  final Future<void> Function() onFinish;
  const AppTourScreen({super.key, required this.onFinish});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _requestingLocation = false;
  String? _locationError;
  bool _requestingCamera = false;
  String? _cameraError;
  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _notificationsGranted = false;
  bool _requestingNotifications = false;
  String? _notificationsError;
  bool _bluetoothGranted = false;
  bool _requestingBluetooth = false;
  String? _bluetoothError;
  bool _smsGranted = false;
  bool _contactsGranted = false;
  bool _requestingSmsContacts = false;
  String? _smsContactsError;
  final bool _finalStep = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    setState(() { _requestingLocation = true; _locationError = null; });
    try {
      final GeolocatorPlatform.GeolocatorPlatform geo = GeolocatorPlatform.GeolocatorPlatform.instance;
      LocationPermission permission = await geo.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await geo.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() { _locationError = 'Location access denied.'; _locationGranted = false; });
        return;
      }
      setState(() { _locationError = null; _locationGranted = true; });
      // Go to next page (camera permission)
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      setState(() { _locationError = 'Location error.'; _locationGranted = false; });
    } finally {
      setState(() { _requestingLocation = false; });
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() { _requestingCamera = true; _cameraError = null; });
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          setState(() { _cameraError = 'Camera access denied.'; _cameraGranted = false; });
          return;
        }
      }
      setState(() { _cameraError = null; _cameraGranted = true; });
      // Go to next page (notification permission)
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      setState(() { _cameraError = 'Camera error.'; _cameraGranted = false; });
    } finally {
      setState(() { _requestingCamera = false; });
    }
  }

  Future<void> _requestNotificationsPermission() async {
    setState(() { _requestingNotifications = true; _notificationsError = null; });
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          setState(() { _notificationsError = 'Notifications denied.'; _notificationsGranted = false; });
          return;
        }
      }
      setState(() { _notificationsError = null; _notificationsGranted = true; });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      setState(() { _notificationsError = 'Notification error.'; _notificationsGranted = false; });
    } finally {
      setState(() { _requestingNotifications = false; });
    }
  }

  Future<void> _requestBluetoothPermission() async {
    setState(() { _requestingBluetooth = true; _bluetoothError = null; });
    try {
      // For Android 12+ (API 31+), use bluetoothScan and bluetoothConnect
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      bool granted = true;
      if (!scanStatus.isGranted) {
        final result = await Permission.bluetoothScan.request();
        if (!result.isGranted) granted = false;
      }
      if (!connectStatus.isGranted) {
        final result = await Permission.bluetoothConnect.request();
        if (!result.isGranted) granted = false;
      }
      if (!granted) {
        setState(() { _bluetoothError = 'Bluetooth denied.'; _bluetoothGranted = false; });
        return;
      }
      setState(() { _bluetoothError = null; _bluetoothGranted = true; });
      // Go to next page (camera permission)
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      setState(() { _bluetoothError = 'Bluetooth error.'; _bluetoothGranted = false; });
    } finally {
      setState(() { _requestingBluetooth = false; });
    }
  }

  Future<void> _requestSmsContactsPermission() async {
    setState(() { _requestingSmsContacts = true; _smsContactsError = null; });
    try {
      bool granted = true;
      // SMS permissions
      final sendSmsStatus = await Permission.sms.status;
      if (!sendSmsStatus.isGranted) {
        final result = await Permission.sms.request();
        if (!result.isGranted) granted = false;
      }
      // Contacts permission
      final contactsStatus = await Permission.contacts.status;
      if (!contactsStatus.isGranted) {
        final result = await Permission.contacts.request();
        if (!result.isGranted) granted = false;
      }
      if (!granted) {
        setState(() { _smsContactsError = 'SMS/Contacts denied.'; _smsGranted = false; _contactsGranted = false; });
        return;
      }
      setState(() { _smsContactsError = null; _smsGranted = true; _contactsGranted = true; });
      // Go to next page (notifications)
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      setState(() { _smsContactsError = 'Permission error.'; _smsGranted = false; _contactsGranted = false; });
    } finally {
      setState(() { _requestingSmsContacts = false; });
    }
  }

  void _onNext() async {
    if (_currentPage == 0 || _currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else if (_currentPage == 2) {
      if (!_locationGranted) {
        await _requestLocationPermission();
      } else {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } else if (_currentPage == 3) {
      if (!_bluetoothGranted) {
        await _requestBluetoothPermission();
      } else {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } else if (_currentPage == 4) {
      if (!_cameraGranted) {
        await _requestCameraPermission();
      } else {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } else if (_currentPage == 5) {
      if (!_smsGranted || !_contactsGranted) {
        await _requestSmsContactsPermission();
      } else {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } else if (_currentPage == 6) {
      if (!_notificationsGranted) {
        await _requestNotificationsPermission();
      } else {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } else if (_currentPage == 7) {
      await widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonTop = MediaQuery.of(context).size.height * 0.75;
    return Scaffold(
      // No AppBar for a cleaner look
      body: Builder(
        builder: (scaffoldContext) => Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // Welcome page
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome to',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 38,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'WellWiz',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Color(0xFF7CB518),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Disclaimer page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, size: 48, color: Color(0xFF7CB518)),
                        SizedBox(height: 24),
                        Text(
                          'Disclaimer',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'This app uses Gemini API and AI services to power its chatbot.\n\nActual medical advice from your doctor or hospital must always be followed. WellWiz is an assistant for patients, not a replacement for medical professionals or institutions.',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Location permission page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 48, color: Color(0xFF7CB518)),
                        const SizedBox(height: 24),
                        const Text(
                          'Find Nearby Hospitals',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WellWiz can help you locate nearby hospitals. To do this, we need access to your location. Please allow location permission.',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_locationError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _locationError!,
                              style: const TextStyle(color: Colors.red, fontFamily: 'Mulish'),
                            ),
                          ),
                        if (_requestingLocation)
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                // Bluetooth permission page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bluetooth_searching, size: 48, color: Color(0xFF7CB518)),
                        const SizedBox(height: 24),
                        const Text(
                          'Enable Bluetooth',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WellWiz can use Bluetooth to help find nearby devices and improve location accuracy. Please allow Bluetooth access.',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_bluetoothError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _bluetoothError!,
                              style: const TextStyle(color: Colors.red, fontFamily: 'Mulish'),
                            ),
                          ),
                        if (_requestingBluetooth)
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                // Camera permission page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt, size: 48, color: Color(0xFF7CB518)),
                        const SizedBox(height: 24),
                        const Text(
                          'Scan Reports Instantly',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WellWiz lets you scan your medical reports directly from the camera and analyze trends. Please allow camera access to use this feature.',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_cameraError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _cameraError!,
                              style: const TextStyle(color: Colors.red, fontFamily: 'Mulish'),
                            ),
                          ),
                        if (_requestingCamera)
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                // SMS and Contacts permission page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sms_failed, size: 48, color: Color(0xFF7CB518)),
                        const SizedBox(height: 24),
                        const Text(
                          'Emergency SOS',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WellWiz lets you send SOS messages to selected contacts in case of emergency. Please allow SMS and Contacts access to use this feature.',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_smsContactsError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _smsContactsError!,
                              style: const TextStyle(color: Colors.red, fontFamily: 'Mulish'),
                            ),
                          ),
                        if (_requestingSmsContacts)
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                // Notification permission page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active, size: 48, color: Color(0xFF7CB518)),
                        const SizedBox(height: 24),
                        const Text(
                          'Stay Notified',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Get notifications for your medications, custom reminders, and positive thoughts. Please allow notifications to stay updated.',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_notificationsError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _notificationsError!,
                              style: const TextStyle(color: Colors.red, fontFamily: 'Mulish'),
                            ),
                          ),
                        if (_requestingNotifications)
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                // Final trust/thank you page
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_user, size: 48, color: Color(0xFF7CB518)),
                        SizedBox(height: 24),
                        Text(
                          'Thank You!',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7CB518),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "We know you've just given a lot of permissions, but WellWiz aims to cover all of your needs.\n\nWe trust you to use WellWiz responsibly, and you can trust us to make this a great ecosystem for everyone.",
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 24,
              top: buttonTop,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentPage > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ColorPalette.green,
                          textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: BorderSide(color: ColorPalette.green, width: 2)),
                          elevation: 0,
                        ),
                        child: const Text('Prev', style: TextStyle(fontFamily: 'Mulish', fontSize: 14, color: ColorPalette.green)),
                      ),
                    ),
                  // Permission pages: show Skip button
                  if (_currentPage >= 2 && _currentPage <= 6)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ColorPalette.black,
                          textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                            side: BorderSide(color: ColorPalette.black, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Skip', style: TextStyle(fontFamily: 'Mulish', fontSize: 14, color: ColorPalette.black)),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => _onNextWithContext(scaffoldContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      elevation: 3,
                    ),
                    child: Text(
                      _currentPage == 0
                          ? 'Next'
                          : _currentPage == 1
                              ? 'I understand'
                              : _currentPage == 7
                                  ? 'Sure'
                                  : 'Allow',
                      style: const TextStyle(fontFamily: 'Mulish', fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNextWithContext(BuildContext scaffoldContext) async {
    if (_currentPage == 0 || _currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else if (_currentPage == 2) {
      await _requestLocationPermissionWithContext(scaffoldContext);
    } else if (_currentPage == 3) {
      await _requestBluetoothPermissionWithContext(scaffoldContext);
    } else if (_currentPage == 4) {
      await _requestCameraPermissionWithContext(scaffoldContext);
    } else if (_currentPage == 5) {
      await _requestSmsContactsPermissionWithContext(scaffoldContext);
    } else if (_currentPage == 6) {
      await _requestNotificationsPermissionWithContext(scaffoldContext);
    } else if (_currentPage == 7) {
      await widget.onFinish();
    }
  }

  Future<void> _requestLocationPermissionWithContext(BuildContext scaffoldContext) async {
    if (!mounted) return;
    setState(() { _requestingLocation = true; _locationError = null; });
    try {
      final geo = GeolocatorPlatform.GeolocatorPlatform.instance;
      LocationPermission permission = await geo.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await geo.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() { _locationError = 'Location access permanently denied. Please enable it in settings.'; _locationGranted = false; });
        return;
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() { _locationError = 'Location access denied.'; _locationGranted = false; });
        return;
      }
      if (!mounted) return;
      setState(() { _locationError = null; _locationGranted = true; });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      if (!mounted) return;
      setState(() { _locationError = 'Location error.'; _locationGranted = false; });
    } finally {
      if (!mounted) return;
      setState(() { _requestingLocation = false; });
    }
  }

  Future<void> _requestBluetoothPermissionWithContext(BuildContext scaffoldContext) async {
    if (!mounted) return;
    setState(() { _requestingBluetooth = true; _bluetoothError = null; });
    try {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      bool granted = true;
      if (!scanStatus.isGranted || scanStatus.isDenied) {
        final result = await Permission.bluetoothScan.request();
        if (!result.isGranted) granted = false;
      }
      if (!connectStatus.isGranted || connectStatus.isDenied) {
        final result = await Permission.bluetoothConnect.request();
        if (!result.isGranted) granted = false;
      }
      if (!granted) {
        if (!mounted) return;
        setState(() { _bluetoothError = 'Bluetooth denied.'; _bluetoothGranted = false; });
        return;
      }
      if (!mounted) return;
      setState(() { _bluetoothError = null; _bluetoothGranted = true; });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      if (!mounted) return;
      setState(() { _bluetoothError = 'Bluetooth error.'; _bluetoothGranted = false; });
    } finally {
      if (!mounted) return;
      setState(() { _requestingBluetooth = false; });
    }
  }

  Future<void> _requestCameraPermissionWithContext(BuildContext scaffoldContext) async {
    if (!mounted) return;
    setState(() { _requestingCamera = true; _cameraError = null; });
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted || status.isDenied) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (!mounted) return;
          setState(() { _cameraError = 'Camera access denied.'; _cameraGranted = false; });
          return;
        }
      }
      if (!mounted) return;
      setState(() { _cameraError = null; _cameraGranted = true; });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      if (!mounted) return;
      setState(() { _cameraError = 'Camera error.'; _cameraGranted = false; });
    } finally {
      if (!mounted) return;
      setState(() { _requestingCamera = false; });
    }
  }

  Future<void> _requestSmsContactsPermissionWithContext(BuildContext scaffoldContext) async {
    if (!mounted) return;
    setState(() { _requestingSmsContacts = true; _smsContactsError = null; });
    try {
      bool granted = true;
      final sendSmsStatus = await Permission.sms.status;
      if (!sendSmsStatus.isGranted || sendSmsStatus.isDenied) {
        final result = await Permission.sms.request();
        if (!result.isGranted) granted = false;
      }
      final contactsStatus = await Permission.contacts.status;
      if (!contactsStatus.isGranted || contactsStatus.isDenied) {
        final result = await Permission.contacts.request();
        if (!result.isGranted) granted = false;
      }
      if (!granted) {
        if (!mounted) return;
        setState(() { _smsContactsError = 'SMS/Contacts denied.'; _smsGranted = false; _contactsGranted = false; });
        return;
      }
      if (!mounted) return;
      setState(() { _smsContactsError = null; _smsGranted = true; _contactsGranted = true; });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      if (!mounted) return;
      setState(() { _smsContactsError = 'Permission error.'; _smsGranted = false; _contactsGranted = false; });
    } finally {
      if (!mounted) return;
      setState(() { _requestingSmsContacts = false; });
    }
  }

  Future<void> _requestNotificationsPermissionWithContext(BuildContext scaffoldContext) async {
    if (!mounted) return;
    setState(() { _requestingNotifications = true; _notificationsError = null; });
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted || status.isDenied) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          if (!mounted) return;
          setState(() { _notificationsError = 'Notifications denied.'; _notificationsGranted = false; });
          return;
        }
      }
      if (!mounted) return;
      setState(() { _notificationsError = null; _notificationsGranted = true; });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      if (!mounted) return;
      setState(() { _notificationsError = 'Notification error.'; _notificationsGranted = false; });
    } finally {
      if (!mounted) return;
      setState(() { _requestingNotifications = false; });
    }
  }
} 