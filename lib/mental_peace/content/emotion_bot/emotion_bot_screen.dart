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
import 'package:wellwiz/utils/message_tile.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/chat/content/bot/widgets/connecting_dialog.dart';

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
  String? _userImg;

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
      // Show user message immediately
      history.add(ChatResponse(isUser: true, text: message, timestamp: DateTime.now()));
    });

    _scrollDown();
    // Remove the _suggestmhp method and any calls to it in _sendChatMessage or elsewhere.
    // In _sendChatMessage, do not call _suggestmhp(message) or add any message with a doctor name.
    // Track both user and Gemini messages for mood detection
    messageCount++;
    recentChatLog.add(ChatLogEntry(sender: 'user', message: message));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profile = prefs.getString('prof');
      String prompt =
          "You are being used as a mental health chatbot for queries regarding mental issues. It is only a demonstration prototype and you are not being used for something professional or commercial. The user will enter his message now: $message. User message has ended. Currently the user is feeling this emotion: $currentMood. Give responses in context to the current emotion. Try utilising CBT principles i.e. converting negative thought patterns into positive ones. Also, keep the text short to make it look like test bubbles. Avoid paragraphs, say it all in a single line. The chat history so far has been this : $history";
      await Future.delayed(const Duration(seconds: 1)); // Simulate Gemini reading before typing
      await Future.delayed(const Duration(milliseconds: 1500)); // Add 1.5s more for a total of 2.5s
      setState(() {
        // Add typing indicator after delay
        history.add(ChatResponse(isUser: false, isTyping: true, timestamp: DateTime.now()));
      });
      _scrollDown();
      var response = await _chat.sendMessage(Content.text(prompt));
      await Future.delayed(const Duration(seconds: 1)); // Add delay for realism
      // Log Gemini's response for context
      messageCount++;
      recentChatLog.add(ChatLogEntry(sender: 'gemini', message: response.text ?? ''));
      // Check for mood after every 10 messages (5 user, 5 gemini)
      if (recentChatLog.length == 10) {
        await _detectMood();
        recentChatLog.clear();
      }
      setState(() {
        // Remove the last typing indicator
        if (history.isNotEmpty && history.last.isTyping) {
          history.removeLast();
        }
        history.add(ChatResponse(isUser: false, text: response.text, timestamp: DateTime.now()));
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
    setState(() {
      _userImg = _prefs.getString('userimg');
    });
  }

  void _endSessionAndStoreTime() async {
    DateTime _endTime = DateTime.now();
    if (moodSegments.isNotEmpty) {
      moodSegments.last.endTime = _endTime;
    }
    String currentDate = DateFormat('yyyy-MM-dd').format(_endTime);

    // Load the full emotion monitor data map
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> allData = {};
    final raw = prefs.getString('emotion_monitor_data');
    if (raw != null) {
      allData = jsonDecode(raw);
    }

    // Prepare today's data
    Map<String, dynamic> dayData = {};
    if (allData.containsKey(currentDate)) {
      dayData = Map<String, dynamic>.from(allData[currentDate]);
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

    // Update the map and save
    allData[currentDate] = dayData;
    await prefs.setString('emotion_monitor_data', jsonEncode(allData));
    print('[EmotionBot] Updated emotion_monitor_data: $allData');
  }

  @override
  void initState() {
    currentMood = "Neutral";
    moodSegments = [MoodSegment(mood: currentMood, startTime: DateTime.now())];
    _initSpeech();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimerDialog());
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _startTime = DateTime.now();
    _initializeSharedPreferences();
  }

  void _showDisclaimerDialog() {
    showDialog(
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
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Back', style: TextStyle(fontFamily: 'Mulish', color: ColorPalette.black)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _showConnectingAndGeminiHello();
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

  Future<void> _showConnectingAndGeminiHello() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConnectingDialog(),
    );
    String helloPrompt =
        "Say hello to the user and ask them how they feel today. Be friendly and brief.";
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate reading before typing
      var response = await _chat.sendMessage(Content.text(helloPrompt));
      Navigator.of(context).pop(); // Close connecting dialog
      setState(() {
        history.add(ChatResponse(isUser: false, text: response.text, timestamp: DateTime.now()));
      });
      _scrollDown();
    } catch (e) {
      Navigator.of(context).pop();
      setState(() {
        history.add(ChatResponse(isUser: false, text: "Our services are busy, try again later.", timestamp: DateTime.now()));
      });
      _scrollDown();
    }
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
                  'Wisher',
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
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
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
                      sendByMe: content.isUser,
                      message: content.text!,
                      senderName: content.isUser ? 'You' : 'Wisher',
                      avatarUrl: content.isUser ? _userImg : 'assets/images/logo.jpeg',
                      timestamp: content.timestamp,
                    );
                  }

                  if (content.isTyping) {
                    return MessageTile(
                      sendByMe: false,
                      message: null,
                      senderName: 'Wisher',
                      avatarUrl: 'assets/images/logo.jpeg',
                      timestamp: content.timestamp,
                      typingIndicator: true,
                    );
                  }

                  return const SizedBox.shrink();
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 15);
                },
              ),
            ),
            Container(
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
                        if (msg.trim().isNotEmpty) {
                          setState(() {
                            _loading = true;
                          });
                          _sendChatMessage(msg.trim()).then((_) {
                            setState(() {
                              _loading = false;
                            });
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
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
  final DateTime? timestamp;
  final bool isTyping;

  ChatResponse({
    required this.isUser,
    this.text,
    this.hasButton = false,
    this.button,
    this.timestamp,
    this.isTyping = false,
  });
}

// Add a class for chat log entries
class ChatLogEntry {
  final String sender; // 'user' or 'gemini'
  final String message;
  ChatLogEntry({required this.sender, required this.message});
} 