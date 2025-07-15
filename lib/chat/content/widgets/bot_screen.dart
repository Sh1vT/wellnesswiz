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
import 'package:wellwiz/chat/content/widgets/message_tile.dart';
import 'package:wellwiz/doctor/content/widgets/doc_view.dart';
// TODO: Modularize and import emergency_service.dart from the new location
// import 'package:wellwiz/chat/content/widgets/emergency_service.dart';
import 'package:wellwiz/chat/content/widgets/sos_alert_button.dart'; // For ContactData
import 'package:wellwiz/secrets.dart';

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
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _charloading = false;
  late File _image;
  bool imageInitialized = false;
  final Telephony telephony = Telephony.instance;

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
          'hasButton': chat.hasButton,
          'button': chat.button != null
              ? {
                  'label': chat.button!.label,
                }
              : null,
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
          hasButton: data['hasButton'] as bool? ?? false,
          button: data['button'] != null
              ? ChatButton(
                  label: data['button']['label'] as String? ?? '',
                  onPressed: () {}, // Placeholder; adjust as needed
                )
              : null,
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
    _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        safetySettings: safetysettings);
    _chat = _model.startChat();
    _loadChatHistory();
    _getUserInfo();
    _initSpeech();
    // _clearProfileValues();
    // _testFirestorePermissions();
    _setupFCM();
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

    // Fetch the existing prescription list from SharedPreferences
    String? prescriptionsJson = pref.getString("prescriptions");
    List<List<dynamic>> prescriptionsList = [];

    if (prescriptionsJson != null && prescriptionsJson.isNotEmpty) {
      try {
        prescriptionsList = List<List<dynamic>>.from(
            jsonDecode(prescriptionsJson)
                .map((item) => List<dynamic>.from(item)));
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }

    // Prepare the prompt for the model
    String prompt = """
  You're being used for demonstration purposes only. 
Analyze the following message for any mentions of medication and dosage. 
A proper response should be in the format "Medication : Dosage" where both values are directly taken from the message provided.
Do not generate or assume medications or dosages that are not explicitly mentioned in the message.

Examples:
- "I have been asked to take apixaban 5 mg every day" -> "Apixaban : 5 mg"
- "I have been prescribed 20 mg of aspirin" -> "Aspirin : 20 mg"

The message starts now: $message.
The message has ended.

If there is no mention of a medication or dosage, respond with "none."
  """;

    var content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    // Exit early if the response is "none"
    if (response.text!.toLowerCase().trim() == "none") {
      print('Model response: ${response.text}');
      return;
    }
    print('triggered');

    // Split the response into medication and dosage
    List<String> parts = response.text!.split(':');
    if (parts.length == 2) {
      print('Model response: ${response.text}');
      String medication = parts[0].trim();
      String dosage = parts[1].trim();

      // Check if the medication already exists in the list, update if necessary
      bool found = false;
      for (var entry in prescriptionsList) {
        if (entry[0] == medication) {
          entry[1] = dosage; // Update dosage
          found = true;
          break;
        }
      }

      // If the medication is not found, add a new entry
      if (!found) {
        prescriptionsList.add([medication, dosage]);
      }

      // Save the updated list back to SharedPreferences
      prescriptionsJson = jsonEncode(prescriptionsList);
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
    if (response.text!.toLowerCase().trim().contains("done")) {
      String text = response.text!;
      List<String> lines = text.split('\n');
      List<String> newLines = lines.sublist(0, lines.length - 2);
      String modifiedText = newLines.join('\n');
      setState(() {
        history.add(ChatResponse(isUser: false, text: modifiedText));
        symptomprediction = false;
        // print(symptomprediction);
        _loading = false;
        _scrollDown();
        _saveChatHistory();
      });
      return;
    }
    setState(() {
      history.add(ChatResponse(isUser: false, text: response.text));
      _loading = false;
      _scrollDown();
    });
    _saveChatHistory();
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
          """You are being used as a medical chatbot for health related queries or appointment scheduling. 
          It is only a demonstration prototype and you are not being used for something professional or commercial. 
          The user will enter his message now: $message. User message has ended. 
          The user can also have a profile section where they may have been asked to avoid or take care of some things. 
          The profile section starts now: $profile. Profile section has ended. 
          Respond naturally to the user as a chatbot, but if the user is asking some advice then and only then use the profile section. 
          Also if the user is asking for appointment booking, simply respond with the word "appointment" and nothing else. 
          Also if the user is asking for scanning a report or their message implies they want to scan a report, simply respond with the word "report" and nothing else. 
          Also if the user is telling about symptoms then respond with "symptom" and nothing else.""";
      var response = await _chat.sendMessage(Content.text(prompt));
      // print("Response from model: ${response.text}");

      setState(() {
        if (response.text!.toLowerCase().trim() == ("appointment") ||
            response.text!.toLowerCase().trim() == ("appointment.")) {
          history.add(ChatResponse(
            isUser: false,
            hasButton: true,
            button: ChatButton(
              label: 'Book Appointment',
              onPressed: () async {
                print('e');
                String userId = await FirebaseAuth.instance.currentUser!.uid;
                print(userId);
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DocView(userId: userId);
                }));
              },
            ),
          ));
        } else if (response.text!.toLowerCase().trim() == ("symptom") ||
            response.text!.toLowerCase().trim() == ("symptom.")) {
          setState(() {
            symptomprediction = true;
          });
          _symptomLoop(message);
        } else if (response.text!.toLowerCase().trim() == ("report") ||
            response.text!.toLowerCase().trim() == ("report.")) {
          history.add(ChatResponse(
            isUser: false,
            hasButton: true,
            button: ChatButton(
              label: 'Scan a Report',
              onPressed: () async {
                print('Success');
                getImageCamera(context);
              },
            ),
          ));
        } else {
          history.add(ChatResponse(isUser: false, text: response.text));
        }
        _loading = false;
      });
      _saveChatHistory();
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

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
            )),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        // title: Text(
        //   'Wizard',
        //   style: TextStyle(
        //       color: Colors.green.shade600,
        //       fontSize: 18,
        //       fontWeight: FontWeight.w700,
        //       fontFamily: 'Mulish'),
        // ),
      ),
      body: _charloading
          ? Center(
              child: CircularProgressIndicator(
              color: Colors.green.shade600,
            ))
          : SafeArea(
              child: Stack(
                children: [
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
                    itemCount: history.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      var content = history[index];

                      if (content.hasButton && content.button != null) {
                        return Align(
                          alignment: content.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              child: Column(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Wizard',
                                        style: const TextStyle(
                                            fontSize: 11.5, color: Colors.grey),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                              width: MediaQuery.sizeOf(context)
                                                      .width /
                                                  1.3,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 13),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomLeft:
                                                        const Radius.circular(
                                                            5),
                                                    topLeft:
                                                        const Radius.circular(
                                                            12),
                                                    topRight:
                                                        const Radius.circular(
                                                            12),
                                                    bottomRight:
                                                        const Radius.circular(
                                                            12),
                                                  )),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Seems like we provide that service! Click below to do that.",
                                                    style: TextStyle(
                                                        fontFamily: 'Mulish',
                                                        fontSize: 14),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Center(
                                                    child: ElevatedButton(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            WidgetStatePropertyAll(
                                                                Colors.green
                                                                    .shade400),
                                                      ),
                                                      onPressed: content
                                                          .button!.onPressed,
                                                      child: Text(
                                                        content.button!.label,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Mulish',
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (content.text != null && content.text!.isNotEmpty) {
                        return MessageTile(
                          sendByMe: content.isUser,
                          message: content.text!,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 15);
                    },
                  ),
                  // Your bottom input UI
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: TextField(
                                cursorColor: Colors.green.shade400,
                                controller: _textController,
                                autofocus: false,
                                focusNode: _textFieldFocus,
                                decoration: InputDecoration(
                                  hintText: 'What is troubling you...',
                                  hintStyle: const TextStyle(
                                      color: Colors.grey, fontFamily: 'Mulish'),
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onLongPressEnd: (details) {
                              if (_speechToText.isListening) {
                                _speechToText.stop();
                                setState(() {});
                              }
                            },
                            onLongPress: () async {
                              await Permission.microphone.request();
                              await Permission.speech.request();

                              if (_speechEnabled) {
                                setState(() {
                                  _speechToText.listen(onResult: (result) {
                                    _textController.text =
                                        result.recognizedWords;
                                    // print(result.recognizedWords);
                                  });
                                });
                              }
                            },
                            onTap: () {
                              final message = _textController.text.trim();

                              if (message.isNotEmpty) {
                                setState(() {
                                  history.add(ChatResponse(
                                      isUser: true, text: message));
                                  _loading =
                                      true; // Show loading indicator when sending the message
                                });

                                _sendChatMessage(message).then((_) {
                                  setState(() {
                                    _loading =
                                        false; // Hide loading indicator after sending
                                  });
                                });
                              }
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 3,
                                    spreadRadius: 3,
                                    color: Colors.black.withOpacity(0.05),
                                  ),
                                ],
                              ),
                              child: _loading
                                  ? Padding(
                                      padding: EdgeInsets.all(15),
                                      child: const CircularProgressIndicator
                                          .adaptive(
                                        backgroundColor: Colors.white,
                                      ),
                                    )
                                  : _textController.text.isEmpty
                                      ? const Icon(Icons.mic,
                                          color: Colors.white)
                                      : const Icon(Icons.send,
                                          color: Colors.white),
                            ),
                          )
                        ],
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
  final bool hasButton;
  final ChatButton? button;

  ChatResponse({
    required this.isUser,
    this.text,
    this.hasButton = false,
    this.button,
  });
} 