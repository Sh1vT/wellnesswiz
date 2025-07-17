import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/chatroom_screen.dart';
import 'package:wellwiz/secrets.dart';
// import 'package:wellwiz/secrets.dart';

class MoodSegment {
  String mood;
  DateTime startTime;
  DateTime? endTime;
  MoodSegment({required this.mood, required this.startTime, this.endTime});
}

class EmotionBotScreen extends StatefulWidget {
  EmotionBotScreen({super.key});
  // Removed emotion parameter
  @override
  State<EmotionBotScreen> createState() => _EmotionBotScreenState();
}

class _EmotionBotScreenState extends State<EmotionBotScreen> {
  bool recommendedMhp = false;
  String currentEmotion = "";
  List<ChatResponse> history = [];
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  static const _apiKey = geminikey; // TODO: Replace with your actual key or import from secrets
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  late DateTime _startTime;
  late SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String mentalissues = "";
  List<MoodSegment> moodSegments = [];
  String currentMood = "Neutral";
  int messageCount = 0;
  List<ChatLogEntry> recentChatLog = [];
  static const List<String> keyEmotions = [
    'Happy', 'Sad', 'Angry', 'Anxious', 'Frustrated', 'Stressed', 'Neutral'
  ];

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  void _suggestmhp(String message) async {
    if (recommendedMhp == true) {
      return;
    }
    String analysisPrompt =
        """You are being used as a mental health chatbot for demonstration purposes and not commercially or professionally.\nThe user has entered this message : $message. You have to summarise the message and link up the current and existing analysis.\nThe current analysis is $mentalissues. The current session belongs to this emotion so the user was initially feeling this :$currentEmotion.\nNow generate a short summary so that the current analysis can be replaced with a better analysis including the current message.""";

    var analysisResponse =
        await _chat.sendMessage(Content.text(analysisPrompt));
    setState(() {
      mentalissues = analysisResponse.text!;
    });

    QuerySnapshot querySnapshot = await _firestore.collection('mhp').get();
    List<Map<String, dynamic>> map = await querySnapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'profession': doc['profession'],
      };
    }).toList();

    String prompt =
        """You are being used as a mental health chatbot for demonstration purposes and not commercially or professionally. \nYou have to detect the user's messages and analyse how the user is currently feeling so that you can recommend an appropriate doctor.\nThe user is currently feeling $currentEmotion, so take that into consideration too.\nWe have a map of doctors with their name and profession that starts now : $map.\nThe messages of the user so far have been these: $mentalissues. \nIf you cant suggest a doctor yet, simply respond with a plain text of \"none\" and nothing else.\nBut Once you think a doctor matches to the user's current mental condition, respond a message that is formatted like this:\nTell user that you cant replace an actual mental health professional. Tell them you've looked into the messages so far and it seems user has [issue]. \nThen suggest them a [doctor] who specializes in [specialization]... Retur the doctor name and their specialization in bolded letters""";

    var response = await _chat.sendMessage(Content.text(prompt));

    if (response.text!.trim().toLowerCase() == "none." ||
        response.text!.trim().toLowerCase() == "none") {
      return;
    } else {
      setState(() {
        history.add(ChatResponse(isUser: false, text: response.text!));
        recommendedMhp = true;
      });
      _scrollDown();
    }
  }

  Future<void> _detectMood() async {
    String chatContext = recentChatLog.map((e) => "${e.sender}: ${e.message}").join("\n");
    String prompt = "Based on the following conversation (user and Gemini), what is the user's current mood? Respond with only one of: ${keyEmotions.join(", ")}. Conversation:\n$chatContext";
    var response = await _chat.sendMessage(Content.text(prompt));
    String detectedMood = keyEmotions.firstWhere(
      (m) => response.text != null && response.text!.toLowerCase().contains(m.toLowerCase()),
      orElse: () => "Neutral",
    );
    if (detectedMood != currentMood) {
      // End previous segment
      moodSegments.last.endTime = DateTime.now();
      // Start new segment
      moodSegments.add(MoodSegment(mood: detectedMood, startTime: DateTime.now()));
      setState(() {
        currentMood = detectedMood;
      });
    }
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
    });

    _scrollDown();
    _suggestmhp(message);
    // Track both user and Gemini messages for mood detection
    messageCount++;
    recentChatLog.add(ChatLogEntry(sender: 'user', message: message));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profile = prefs.getString('prof');
      String prompt =
          "You are being used as a mental health chatbot for queries regarding mental issues. It is only a demonstration prototype and you are not being used for something professional or commercial. The user will enter his message now: $message. User message has ended. Currently the user is feeling this emotion: $currentMood. Give responses in context to the current emotion. Try utilising CBT principles i.e. converting negative thought patterns into positive ones. Also, keep the text short to make it look like test bubbles. Avoid paragraphs, say it all in a single line. The chat history so far has been this : $history";
      var response = await _chat.sendMessage(Content.text(prompt));
      // Log Gemini's response for context
      messageCount++;
      recentChatLog.add(ChatLogEntry(sender: 'gemini', message: response.text ?? ''));
      // Check for mood after every 20 messages (10 user, 10 gemini)
      if (recentChatLog.length == 20) {
        await _detectMood();
        recentChatLog.clear();
      }
      setState(() {
        history.add(ChatResponse(isUser: false, text: response.text));
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

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _endSessionAndStoreTime() async {
    DateTime _endTime = DateTime.now();
    if (moodSegments.isNotEmpty) {
      moodSegments.last.endTime = _endTime;
    }
    String currentDate = DateFormat('yyyy-MM-dd').format(_endTime);
    Map<String, dynamic> dayData = {};
    if (_prefs.containsKey(currentDate)) {
      String? jsonData = _prefs.getString(currentDate);
      if (jsonData != null) {
        dayData = Map<String, dynamic>.from(jsonDecode(jsonData));
      }
    }
    for (var segment in moodSegments) {
      if (segment.endTime == null) continue;
      int duration = segment.endTime!.difference(segment.startTime).inMinutes;
      if (duration <= 0) continue;
      if (dayData.containsKey(segment.mood)) {
        dayData[segment.mood] += duration;
      } else {
        dayData[segment.mood] = duration;
      }
    }
    _prefs.setString(currentDate, jsonEncode(dayData));
    print(dayData);
  }

  @override
  void initState() {
    currentMood = "Neutral";
    moodSegments = [MoodSegment(mood: currentMood, startTime: DateTime.now())];
    _initSpeech();
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _sendChatMessage(
        "This is the first message before user has interacted. Just give an intro message.");
    _startTime = DateTime.now();
    _initializeSharedPreferences();
  }

  @override
  void dispose() {
    _endSessionAndStoreTime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wisher',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Colors.grey),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.sizeOf(context).width /
                                          1.3,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 13),
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft:
                                                const Radius.circular(5),
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomRight:
                                                const Radius.circular(12),
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
                                                        Colors.green.shade400),
                                              ),
                                              onPressed:
                                                  content.button!.onPressed,
                                              child: Text(
                                                content.button!.label,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Mulish',
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                    senderName: content.isUser ? 'You' : 'Wisher',
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                              _textController.text = result.recognizedWords;
                            });
                          });
                        }
                      },
                      onTap: () {
                        final message = _textController.text.trim();

                        if (message.isNotEmpty) {
                          setState(() {
                            history
                                .add(ChatResponse(isUser: true, text: message));
                            _loading = true;
                          });

                          _sendChatMessage(message).then((_) {
                            setState(() {
                              _loading = false;
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
                                child: const CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.white,
                                ),
                              )
                            : _textController.text.isEmpty
                                ? const Icon(Icons.mic, color: Colors.white)
                                : const Icon(Icons.send, color: Colors.white),
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

// Add a class for chat log entries
class ChatLogEntry {
  final String sender; // 'user' or 'gemini'
  final String message;
  ChatLogEntry({required this.sender, required this.message});
} 