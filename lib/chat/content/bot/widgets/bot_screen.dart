import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:another_telephony/telephony.dart';
import 'package:wellwiz/chat/content/alerts/widgets/sos_alert_button.dart';
import 'package:wellwiz/doctor/content/docs/widgets/doc_view.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/chatroom_screen.dart';
// TODO: Modularize and import emergency_service.dart from the new location
// import 'package:wellwiz/chat/content/widgets/emergency_service.dart';
import 'package:wellwiz/secrets.dart';
import 'package:wellwiz/doctor/content/prescriptions/models/prescription.dart';
import 'package:wellwiz/utils/message_tile.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/chat/content/bot/widgets/connecting_dialog.dart';
import 'dart:core';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ChatResponse> history = [];
  late final GenerativeModel _model;
  final safetysettings = [
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  ];
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  static const _apiKey = geminikey;
  bool falldone = false;
  bool symptomprediction = false;
  String symptoms = "";
  List contacts = [];
  String username = "";
  String userimg = "";
  String? userimgUrl;
  // 1. Remove SpeechToText and related fields
  // 2. Remove Permission.microphone and Permission.speech requests
  // 3. Remove mic button UI and handlers
  // 4. Only allow sending text messages
  bool _charloading = false;
  late File _image;
  bool imageInitialized = false;
  final Telephony telephony = Telephony.instance;
  static const String _unsyncedKey = 'unsynced_messages';
  String? _userImg;
  bool _inputEnabled = false; // Add this to control input bar

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveChatHistory() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      CollectionReference chats =
          _firestore.collection('users').doc(user.uid).collection('chats');

      final List<ChatResponse> historyCopy = List.from(history);

      for (var chat in historyCopy) {
        await chats.add({
          'isUser': chat.isUser,
          'text': chat.text,
          'timestamp': Timestamp.now(),
        });
      }

      print('Chat history saved successfully.');
    } catch (e) {
      print('Failed to save chat history: $e');
      _showError('Failed to save chat history.');
    }
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Permission Needed'),
          content: Text('Location access is required to send your location to emergency contacts. It is only used for SOS and nothing else.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> sendSOSMessages(List<String> recipients, String message) async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      Fluttertoast.showToast(msg: "SMS permission not granted");
      return;
    }
    for (final number in recipients) {
      await telephony.sendSms(
        to: number,
        message: message,
      );
    }
    Fluttertoast.showToast(msg: "SOS ALERT SENT TO ALL CONTACTS");
  }

  Future<void> _sendEmergencyMessage() async {
    if (!await _ensureLocationPermission()) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getString('contacts');
    final decodedContacts = jsonDecode(encodedContacts!) as List;
    contacts.clear();
    contacts.addAll(decodedContacts.map((c) => ContactData.fromJson(c)).toList());
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    List<String> recipients = contacts.map<String>((c) => "+91${c.phone}").toList();
    String message =
        "I am facing some critical medical condition. Please call an ambulance or arrive here: https://www.google.com/maps/place/$lat+$lng";
    await sendSOSMessages(recipients, message);
    launchUrl(Uri.parse("tel:108"));
  }

  Future<void> _loadChatHistory({DocumentSnapshot? lastDocument}) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('No user is logged in.');
      return;
    }
    setState(() {
      _charloading = true;
    });

    try {
      CollectionReference chats =
          _firestore.collection('users').doc(user.uid).collection('chats');

      Query query = chats
          .orderBy('timestamp', descending: true)
          .limit(30); // Limit to 30 messages

      // If we have a lastDocument (for pagination), start after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();

      List<ChatResponse> loadedHistory = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return ChatResponse(
          isUser: data['isUser'] as bool? ?? false,
          text: data['text'] as String?,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
        );
      }).toList();

      setState(() {
        history.addAll(loadedHistory.reversed); // Add older messages at the top
        _charloading = false;
      });

      // Save the last document for pagination
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      print('Chat history loaded successfully.');
      _scrollDown();
    } catch (e) {
      print('Failed to load chat history: $e');
      _showError('Failed to load chat history.');
    }
  }

  void _clearProfileValues() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof')!;
    prefval = "";
    pref.setString('prof', prefval);
    // print(prefval);
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await _showDisclaimerDialog();
      if (allowed == true) {
        await _showConnectingAndGeminiHello();
      } else {
        // Optionally: pop the chat screen if not allowed
        if (mounted) Navigator.of(context).pop();
      }
    });
    _model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: _apiKey,
        safetySettings: safetysettings);
    _chat = _model.startChat();
    _syncUnsyncedMessages();
    _loadChatHistory();
    _getUserInfo();
    _setupFCM();
    _fetchUserAvatar();
    _initializeSharedPreferences();
  }

  // Add a helper to insert a divider message
  Future<void> _addDivider() async {
    setState(() {
      history.add(ChatResponse(isUser: false, text: null, timestamp: null));
    });
    // No need to save divider to local or Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  Future<void> _showConnectingAndGeminiHello() async {
    // Show connecting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConnectingDialog(),
    );
    String helloPrompt =
        "Say hello to the user and inform them you are an AI assistant being used in a health and wellness context. Be friendly and brief.";
    try {
      var response = await _chat.sendMessage(Content.text(helloPrompt));
      Navigator.of(context).pop(); // Close connecting dialog
      String? helloText = response.text;
      if (helloText == null || helloText.trim().isEmpty) {
        await _addMessage(ChatResponse(
          isUser: false,
          text: "Our services are busy, try again later.",
          timestamp: DateTime.now(),
        ));
      } else {
        // Find the last non-user message (bot message)
        ChatResponse? lastBotMsg;
        for (var i = history.length - 1; i >= 0; i--) {
          if (!history[i].isUser && (history[i].text != null && history[i].text!.trim().isNotEmpty)) {
            lastBotMsg = history[i];
            break;
          }
        }
        // Regex for greeting
        final greetingRegex = RegExp(r'\b(hello|hi|hey|greetings|welcome|good (morning|afternoon|evening|day))\b', caseSensitive: false);
        bool lastWasGreeting = lastBotMsg != null && greetingRegex.hasMatch(lastBotMsg.text!.toLowerCase());
        if (!lastWasGreeting) {
          // If there are previous messages, add a divider before hello
          if (history.isNotEmpty) {
            await _addDivider();
          }
          await _addMessage(ChatResponse(
            isUser: false,
            text: helloText,
            timestamp: DateTime.now(),
          ));
        }
        // else: do not add another hello, just open chat
      }
    } catch (e) {
      Navigator.of(context).pop();
      await _addMessage(ChatResponse(
        isUser: false,
        text: "Our services are busy, try again later.",
        timestamp: DateTime.now(),
      ));
    }
    setState(() {
      _inputEnabled = true;
    });
  }

  Future<bool?> _showDisclaimerDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Disclaimer', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
        content: Text(
          'This is just an AI assistant powered by Gemini API. It cannot replace human doctors or medical institutes. Use it as an assistant, not for medical advice.',
          style: TextStyle(fontFamily: 'Mulish'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('Back', style: TextStyle(fontFamily: 'Mulish', color: ColorPalette.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 106, 172, 67),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Alright', style: TextStyle(fontFamily: 'Mulish', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userImg = prefs.getString('userimg');
    });
  }

  Future<void> _fetchUserAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['profilePicUrl'] != null && data['profilePicUrl'].toString().isNotEmpty) {
      setState(() {
        userimgUrl = data['profilePicUrl'];
      });
    }
  }

  @override
  void dispose() {
    _uploadBatchToFirestore();
    super.dispose();
  }

  Future<void> _saveMessageLocally(ChatResponse message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cached = prefs.getStringList(_unsyncedKey) ?? [];
    cached.add(jsonEncode(message.toJson()));
    await prefs.setStringList(_unsyncedKey, cached);
  }

  Future<void> _uploadBatchToFirestore() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cached = prefs.getStringList(_unsyncedKey) ?? [];
    if (cached.isEmpty) return;
    final User? user = _auth.currentUser;
    if (user == null) return;
    WriteBatch batch = _firestore.batch();
    final chats = _firestore.collection('users').doc(user.uid).collection('chats');
    for (String msgJson in cached) {
      final msg = ChatResponse.fromJson(jsonDecode(msgJson));
      batch.set(chats.doc(), msg.toFirestoreMap());
    }
    await batch.commit();
    await prefs.remove(_unsyncedKey);
  }

  Future<void> _syncUnsyncedMessages() async {
    await _uploadBatchToFirestore();
  }

  // Replace all history.add(...) with this helper
  Future<void> _addMessage(ChatResponse message) async {
    setState(() {
      history.add(message);
    });
    await _saveMessageLocally(message);
    if (history.length % 10 == 0) {
      await _uploadBatchToFirestore();
    }
    // Schedule scroll after the next frame, when ListView is updated
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Get the device token for sending notifications
    String? token = await messaging.getToken();
    print("FCM Token: $token");

    // Store this token in Firestore for future notifications (Optional)
    // await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': token});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  void _startProfiling(String message) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? profileJson = prefs.getString('prof');
    Map<String, String> profileMap = {};

    if (profileJson != null) {
      profileMap = Map<String, String>.from(jsonDecode(profileJson));
    }
    // String prompt2 =
    //     "You are being used as a medical advisor to help in profiling of a user. The user is going to enter a message at last. Check if the message contains something important in medical aspects i.e.something that would help any doctor or you as an advisor, to give more relevant and personalized information to the user. For example, if the user mentions that they have low blood sugar or their blood pressure is irregular or if they have been asked to avoid spicy food etc. then you have to respond with that extracted information which will be used to profile the user for better advices. You can extract information when user mentions it was said by a doctor. You can also consider the user's body description such as age, gender, physical condition, chemical levels etc for profiling. Please keep the response short and accurate while being descriptive. This action is purely for demonstration purposes. The user message starts now: $message. Also if the message is unrelated to profiling then respond with \"none\". The current profile is attached here : $profileJson. In case whatever you detect is already in the profile, then also reply with \"none\"";
    String prompt =
        """You are being used as a profiler for creating a medical profile of a user.
        This profile must consist everything that is important in terms of a medical enquiry.
        For example, it could contain information imposed on user by doctor, such as dietary restrictions, physical restrictions, dietary preferences, exercise preferences, calorie intake, or anything that a doctor would tell a patient for better and steady recovery. Dont care if the user gives numerical value for bodily fluids like creatinine level, rbc count or some similar body fluid. The user's message is as follows : $message
        The current profile is stored as a json map as follows: $profileMap.
        If any profilable information is found, then return it as a short yet descriptive statement without formatting or quotes, similar to something like : I have low RBC count. or : I am not allowed to eat root vegetables.
        If whatever that is said in the message already exists in the profile map that was attached then respond with a plain text of "none" without formatting and nothing else.
        If the message is unrelated to profiling then also respond with a plain text of "none" without formatting and nothing else.
    """;
    var content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    String newProfValue = response.text!;
    // print(newProfValue.toUpperCase());
    if (newProfValue.toLowerCase().trim() == "none" ||
        newProfValue.toLowerCase().trim() == "none.") {
      return;
    }
    String currentDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    profileMap[currentDate] = newProfValue;
    profileJson = jsonEncode(profileMap);
    prefs.setString('prof', profileJson);
    // print(profileMap);
  }

  void _startTabulatingPrescriptions(String message) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? prescriptionsJson = pref.getString("prescriptions");
    List<Prescription> prescriptionsList = prescriptionsJson != null && prescriptionsJson.isNotEmpty
        ? Prescription.listFromJson(prescriptionsJson)
        : [];

    // Prepare the prompt for the model
    String prompt = """
You're being used for demonstration purposes only. 
Analyze the following message for any mentions of medication and dosage. 
A proper response should be in the format \"Medication : Dosage\" where both values are directly taken from the message provided.
Do not generate or assume medications or dosages that are not explicitly mentioned in the message.

Examples:
- \"I have been asked to take apixaban 5 mg every day\" -> \"Apixaban : 5 mg\"
- \"I have been prescribed 20 mg of aspirin\" -> \"Aspirin : 20 mg\"

The message starts now: $message.
The message has ended.

If there is no mention of a medication or dosage, respond with \"none.\"
""";

    var content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    // Exit early if the response is "none"
    if (response.text!.toLowerCase().trim() == "none") {
      print('Model response:  [33m${response.text} [0m');
      return;
    }
    print('triggered');

    // Split the response into medication and dosage
    List<String> parts = response.text!.split(':');
    if (parts.length == 2) {
      String medication = parts[0].trim();
      String dosage = parts[1].trim();

      // Check if the medication already exists in the list, update if necessary
      bool found = false;
      for (var entry in prescriptionsList) {
        if (entry.medicineName == medication) {
          entry = Prescription(
            medicineName: medication,
            dosage: dosage,
            times: entry.times,
            startDate: entry.startDate,
            endDate: entry.endDate,
            instructions: entry.instructions,
          );
          found = true;
          break;
        }
      }
      // If the medication is not found, add a new entry (default time: 08:00, today as startDate)
      if (!found) {
        prescriptionsList.add(Prescription(
          medicineName: medication,
          dosage: dosage,
          times: ["08:00"],
          startDate: DateTime.now(),
          endDate: null,
          instructions: null,
        ));
      }
      // Save the updated list back to SharedPreferences
      prescriptionsJson = Prescription.listToJson(prescriptionsList);
      pref.setString('prescriptions', prescriptionsJson);
      print(prescriptionsList);
    }
  }

  void _startTabulating(String message) async {
    print("E");
    final SharedPreferences pref = await SharedPreferences.getInstance();

    // Fetch the existing table list from SharedPreferences
    String? tableJson = pref.getString("table");
    List<List<dynamic>> tableList = [];

    if (tableJson != null && tableJson.isNotEmpty) {
      try {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }

    print(tableList);

    // Prepare the prompt for the model
    String prompt = """
    You are being used for fetching details for creating a medical documentation of a user.
    These details must consist everything that is important in terms of a medical enquiry.
    For example, it could contain numerical value of the user's bodily fluids such as rbc, platelet count, creatinine level, glucose level or anything that is calculated in medical test and used by doctors.
    Check if this message by user contains any such information or not: $message. Also see if the mentioned level is high, low or normal. This will be used later.
    The current detail table is stored as a json list as follows: $tableList.
    If any profilable information is found, then respond with a plain text format of "Title : Value : Integer" where the integer is either 0, -1, or 1 depending on the following: 
    The integer will be 0 if the body fluid level is within normal range, -1 if it is below normal range and 1 if it is above normal range.
    If the user does not mention the numerical value, write it as low/high and set the integer to 0. If the value is low, set the integer to -1. If the value is high, set it to 1.
    If whatever is said in the message already exists in the table list, then respond with a plain text of "none" without any formatting and nothing else.
    If the message is unrelated to bodily fluid detail, then also respond with a plain text of "none" without any formatting and nothing else.
  """;

    var content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    // Exit early if the response is "none"
    if (response.text!.toLowerCase().trim() == "none") {
      return;
    }

    // Split the response into title, value, and integer
    List<String> parts = response.text!.split(':');
    if (parts.length == 3) {
      String title = parts[0].trim();
      String value = parts[1].trim();
      int flag = int.parse(parts[2].trim());

      // Check if the title already exists in the list, update if necessary
      bool found = false;
      for (var entry in tableList) {
        if (entry[0] == title) {
          entry[1] = value;
          entry[2] = flag;
          found = true;
          break;
        }
      }

      // If the title is not found, add a new entry
      if (!found) {
        tableList.add([title, value, flag]);
      }

      // Save the updated list back to SharedPreferences
      tableJson = jsonEncode(tableList);
      pref.setString('table', tableJson);

      print(tableList);
    }
  }

  void _symptomLoop(String message) async {
    if (symptomprediction == false) {
      return;
    }
    // print("symptomloop function");
    // print("pred value : $symptomprediction");
    setState(() {
      _addMessage(ChatResponse(isUser: true, text: message, timestamp: DateTime.now()));
    });
    _startTabulating(message);
    _startTabulatingPrescriptions(message);
    QuerySnapshot querySnapshot = await _firestore.collection('doctor').get();
    List<Map<String, dynamic>> map = await querySnapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'degree': doc['degree'],
        'speciality': doc['speciality'],
      };
    }).toList();
    // print(map);

    symptoms = symptoms + " " + message;
    String prompt =
        "You are being used as a medical assistant for symptom prediction. Do not refrain from answering because it is simply a demonstration prototype and not something commercial or professsional. The user has entered their first symptom which starts now: $message. The symptom has ended. Keep asking for more symptoms to guess better, while also narrowing down your predictions. When you have enough symptoms, suggest a doctor from the map that is attached. The map starts now : $map. If you have suggested a doctor, reply with the last sentence as \"Done.\"";
    var response = await _chat.sendMessage(Content.text(prompt));
    // print("receive");
    // print(response.text!);
    // print(response.text!);
    setState(() {
      if (response.text!.toLowerCase().trim().contains("done")) {
        String text = response.text!;
        List<String> lines = text.split('\n');
        List<String> newLines = lines.sublist(0, lines.length - 2);
        String modifiedText = newLines.join('\n');
        _addMessage(ChatResponse(isUser: false, text: modifiedText, timestamp: DateTime.now()));
        symptomprediction = false;
        // print(symptomprediction);
        _loading = false;
        _scrollDown();
      } else {
        _addMessage(ChatResponse(isUser: false, text: response.text, timestamp: DateTime.now()));
      }
    });
  }

  Future<void> getImageCamera(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Select Image Source",
            style: TextStyle(fontFamily: 'Mulish'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Camera",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Permission.camera.request();
                  var image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );

                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    print("sending");
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                    debugPrint('No image selected.');
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Gallery",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  var image = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    print("sending");
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                    debugPrint('No image selected.');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendImageMessage() async {
    final imgBytes = await _image.readAsBytes();
    final SharedPreferences pref = await SharedPreferences.getInstance();

    // Fetch the existing table list from SharedPreferences
    String? tableJson = pref.getString("table");
    List<List<dynamic>> tableList = [];

    if (tableJson != null && tableJson.isNotEmpty) {
      try {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }

    Fluttertoast.showToast(msg: "Extracting information...");

    // Constructing the modified prompt
    String prompt = """
    You are being used as a medical chatbot for demonstration purposes. 
    The user has submitted a medical report in image form, and you need to extract body chemical levels. 
    Here is the current table of body chemical levels stored as a JSON list: $tableList.

    Instructions:
    1. Extract the body chemical levels from the medical report and format them as "Title : Value : Integer" where:
      - "Title" is the name of the chemical or component. If it is written in short then write the full form or the more well known version of that title.
      - "Value" is the numerical level.
      - "Integer" is 0, -1, or 1 depending on the following:
        - 0: Level is within the normal range
        - -1: Level is below the normal range
        - 1: Level is above the normal range

    2. Compare the extracted chemical levels against the provided table list. 
      - If a chemical level is missing from the table, or if its value has changed, return it in the response.
      - Only return those entries that either aren't found in the `tableList` or have updated values.

    Return the list of updated or new chemical levels in the format "Title : Value : Integer".
    If nothing is found, return "none".
  """;

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imgBytes),
      ])
    ];

    final response = await _model.generateContent(content);
    final responseText = response.text!.toLowerCase().trim();

    // Debugging output
    print("Response: $responseText");

    if (responseText == "none") {
      Fluttertoast.showToast(msg: "No new or updated levels found.");
      return;
    }

    // Handle the response as plain text
    try {
      List<String> entries =
          responseText.split('\n').map((e) => e.trim()).toList();

      for (var entry in entries) {
        // Example entry: "Title : Value : Integer"
        List<String> parts = entry.split(':').map((e) => e.trim()).toList();

        if (parts.length == 3) {
          String title = parts[0];
          String value = parts[1];
          int flag = int.tryParse(parts[2]) ?? 0;

          // Check if the title already exists in the list, update if necessary
          bool found = false;
          for (var existingEntry in tableList) {
            if (existingEntry[0] == title) {
              if (existingEntry[1] != value || existingEntry[2] != flag) {
                // Update the existing entry if the value or flag has changed
                existingEntry[1] = value;
                existingEntry[2] = flag;
              }
              found = true;
              break;
            }
          }

          // If the title is not found, add a new entry
          if (!found) {
            tableList.add([title, value, flag]);
          }
        } else {
          print("Unexpected entry format: $entry");
        }
      }

      // Save the updated list back to SharedPreferences
      tableJson = jsonEncode(tableList);
      await pref.setString('table', tableJson);

      print(tableList);
      Fluttertoast.showToast(msg: "Updated levels added to table.");
    } catch (e) {
      Fluttertoast.showToast(msg: "An unknown error occurred!");
      print("Error parsing response: $e");
    }
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) {
      return; // Do nothing if the message is empty
    }

    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
    });
    if (symptomprediction == true) {
      _symptomLoop(message);
      return;
    }
    _scrollDown();
    print("sendchatmessage function");

    try {
      _startProfiling(message);
      _startTabulating(message);
      _startTabulatingPrescriptions(message);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profile = prefs.getString('prof');
      String prompt =
          "You are being used as a medical chatbot for health related queries. It is only a demonstration prototype and you are not being used for commercial purposes. But don't mention that youre some demo or prototype as this breaks the flow. Jut act natural. The user will enter his message now: $message. User message has ended. The user can also have a profile section where they may have been asked to avoid or take care of some things. The profile section starts now: $profile. Profile section has ended. Respond naturally to the user as a chatbot.";
      // Add user message immediately
      await _addMessage(ChatResponse(isUser: true, text: message, timestamp: DateTime.now()));
      await Future.delayed(const Duration(milliseconds: 2500)); // Simulate Gemini reading before typing
      await _addMessage(ChatResponse(isUser: false, isTyping: true, timestamp: DateTime.now()));
      _scrollDown();
      var response = await _chat.sendMessage(Content.text(prompt));
      await Future.delayed(const Duration(seconds: 1)); // Add delay for realism
      setState(() {
        // Remove the last typing indicator
        if (history.isNotEmpty && history.last.isTyping) {
          history.removeLast();
        }
        if (response.text!.toLowerCase().trim() == ("symptom") ||
            response.text!.toLowerCase().trim() == ("symptom.")) {
          symptomprediction = true;
          _symptomLoop(message);
        } else if (response.text!.toLowerCase().trim() == ("report") ||
            response.text!.toLowerCase().trim() == ("report.")) {
          _addMessage(ChatResponse(
            isUser: false,
            text: 'Scan a Report',
            timestamp: DateTime.now(),
          ));
        } else {
          _addMessage(ChatResponse(isUser: false, text: response.text, timestamp: DateTime.now()));
        }
        _loading = false;
      });
      _scrollDown();
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    }
  }

  void _navigateToRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Something went wrong',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(fontFamily: 'Mulish'),
              ),
            ),
          ],
        );
      },
    );
  }

  void fall_detection() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      num _accelX = event.x.abs();
      num _accelY = event.y.abs();
      num _accelZ = event.z.abs();
      num x = pow(_accelX, 2);
      num y = pow(_accelY, 2);
      num z = pow(_accelZ, 2);
      num sum = x + y + z;
      num result = sqrt(sum);
      if ((result < 1) ||
          (result > 70 && _accelZ > 60 && _accelX > 60) ||
          (result > 70 && _accelX > 60 && _accelY > 60)) {
        print("FALL DETECTED");
        print(falldone);
        if (falldone == false) {
          _fallprotocol();
        }
        return;
      }
    });
  }

  _fallprotocol() async {
    setState(() {
      falldone = true;
    });
    bool popped = false;
    print(falldone);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Fall detected",
              style: TextStyle(fontFamily: 'Mulish'),
            ),
            content: Text(
              "We just detected a fall from your device. Please tell us if you're fine. Or else the emergency contacts will be informed.",
              style: TextStyle(fontFamily: 'Mulish'),
              textAlign: TextAlign.justify,
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  falldone = false;
                  setState(() {
                    falldone = false;
                    popped = true;
                    Navigator.pop(context);
                  });
                  print("falldone val $falldone");
                  return;
                },
                child: Text(
                  "I'm fine",
                  style: TextStyle(
                      fontFamily: 'Mulish',
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          );
        });
    await Future.delayed(Duration(seconds: 10));
    // print("poppedvalue : $popped");
    if (popped == false) {
      _sendEmergencyMessage();
      // print("didnt respond");
      setState(() {
        falldone = false;
      });
      Navigator.pop(context);
    }
    // print("Wait complete");
  }

  _sosprotocol() async {
    if (!await _ensureLocationPermission()) return;
    bool popped = false;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Are you okay?"),
            content: Text(
              "You just pressed the SOS button. This button is used to trigger emergency. Please tell us if you're fine. Or else the emergency contacts will be informed.",
              textAlign: TextAlign.justify,
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  setState(() {
                    falldone = false;
                    popped = true;
                    Navigator.pop(context);
                  });
                  return;
                },
                child: Text("I'm fine"),
              )
            ],
          );
        });
    await Future.delayed(Duration(seconds: 10));
    // print("poppedvalue : $popped");
    if (popped == false) {
      _sendEmergencyMessage();
      // print("didnt respond");
      Navigator.pop(context);
    }
    // print("Wait complete");
  }

  // Remove: void _initSpeech() async {
  // Remove: _speechEnabled = await _speechToText.initialize();
  // Remove: setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(78),
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 32, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade800, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Wizard',
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color.fromARGB(255, 106, 172, 67),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
                itemCount: history.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  var content = history[index];

                  // Render divider if text == null and not a typing indicator
                  if (content.text == null && !content.isTyping) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(
                        thickness: 1.5,
                        color: Colors.grey.shade300,
                      ),
                    );
                  }
                  if (content.isTyping) {
                    return MessageTile(
                      sendByMe: false,
                      message: null,
                      senderName: 'Wizard',
                      avatarUrl: 'assets/images/logo.jpeg',
                      timestamp: content.timestamp,
                      typingIndicator: true,
                    );
                  }

                  if (content.text != null && content.text!.isNotEmpty) {
                    return MessageTile(
                      sendByMe: content.isUser,
                      message: content.text!,
                      senderName: content.isUser ? username : 'Wizard',
                      avatarUrl: content.isUser ? (_userImg ?? userimgUrl) : 'assets/images/logo.jpeg',
                      timestamp: content.timestamp,
                    );
                  }

                  return const SizedBox.shrink();
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 15);
                },
              ),
            ),
            // Input bar here, outside the Expanded
            AbsorbPointer(
              absorbing: !_inputEnabled,
              child: Opacity(
                opacity: _inputEnabled ? 1.0 : 0.5,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          cursorColor: Color.fromARGB(255, 106, 172, 67),
                          controller: _textController,
                          autofocus: false,
                          focusNode: _textFieldFocus,
                          style: const TextStyle(fontFamily: 'Mulish'),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: 'Mulish',
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSubmitted: (msg) {
                            if (_inputEnabled && msg.trim().isNotEmpty) _sendChatMessage(msg.trim());
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          if (!_inputEnabled) return;
                          final message = _textController.text.trim();
                          if (message.isNotEmpty) {
                            setState(() {
                              _loading = true;
                            });
                            _sendChatMessage(message).then((_) {
                              setState(() {
                                _loading = false;
                              });
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 120),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 106, 172, 67),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatButton {
  final String label;
  final VoidCallback onPressed;

  ChatButton({required this.label, required this.onPressed});
}

class ChatResponse {
  final bool isUser;
  final String? text;
  final DateTime? timestamp;
  final bool isTyping;

  ChatResponse({
    required this.isUser,
    this.text,
    this.timestamp,
    this.isTyping = false,
  });

  Map<String, dynamic> toJson() => {
    'isUser': isUser,
    'text': text,
    'timestamp': timestamp?.toIso8601String(),
  };

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    isUser: json['isUser'] as bool? ?? false,
    text: json['text'] as String?,
    timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
  );

  Map<String, dynamic> toFirestoreMap() => {
    'isUser': isUser,
    'text': text,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : Timestamp.now(),
  };
} 