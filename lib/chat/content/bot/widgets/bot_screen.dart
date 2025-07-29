import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wellwiz/chat/content/alerts/widgets/sos_alert_button.dart';
import 'package:wellwiz/secrets.dart';
import 'package:wellwiz/doctor/content/prescriptions/models/prescription.dart';
import 'package:wellwiz/utils/message_tile.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/chat/content/bot/widgets/connecting_dialog.dart';
import 'dart:core';
import 'package:another_telephony/telephony.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
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

  // Remove Firestore chat history sync and make chat history local-only
  // Remove _saveChatHistory, _loadChatHistory, _uploadBatchToFirestore, _syncUnsyncedMessages, and all Firestore chat history logic
  // Add local-only chat history save/load

  static const String _chatHistoryKey = 'local_chat_history';

  Future<void> _saveChatHistoryLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = history.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList(_chatHistoryKey, encoded);
  }

  Future<void> _loadChatHistoryLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = prefs.getStringList(_chatHistoryKey) ?? [];
    setState(() {
      history = encoded.map((e) => ChatResponse.fromJson(jsonDecode(e))).toList();
    });
      _scrollDown();
  }

  // Replace all calls to Firestore chat history methods with local ones
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await _showDisclaimerDialog();
      if (allowed == true) {
        await _showConnectingAndGeminiHello();
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    });
    _model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: _apiKey,
        safetySettings: safetysettings);
    _chat = _model.startChat();
    _loadChatHistoryLocally();
    _getUserInfo();
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
        "Say hello to the user and inform them you are an AI assistant here to help with general queries. Be friendly and brief.";
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
          'This is just an AI assistant powered by Gemini API. It cannot replace professional advice. Use it as an assistant, not for critical decisions.',
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
    final prefs = await SharedPreferences.getInstance();
    final userimgUrl = prefs.getString('profilePicUrl');
    if (userimgUrl != null && userimgUrl.isNotEmpty) {
      setState(() {
        this.userimgUrl = userimgUrl;
      });
    }
  }

  void _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
      userimg = prefs.getString('userimg') ?? '';
    });
  }

  @override
  void dispose() {
    _saveChatHistoryLocally();
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
    // final User? user = _auth.currentUser; // Removed
    // if (user == null) return; // Removed
    // WriteBatch batch = _firestore.batch(); // Removed
    // final chats = _firestore.collection('users').doc(user.uid).collection('chats'); // Removed
    for (String msgJson in cached) {
      final msg = ChatResponse.fromJson(jsonDecode(msgJson));
      // batch.set(chats.doc(), msg.toFirestoreMap()); // Removed
    }
    // await batch.commit(); // Removed
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

  // Remove: void _initSpeech() async {
  // Remove: _speechEnabled = await _speechToText.initialize();
  // Remove: setState(() {});
  // }

  Future<void> _extractAndSaveTrait(String message) async {
    final traitPatterns = [
      RegExp(r"\bI am [^.?!]*[.?!]?", caseSensitive: false),
      RegExp(r"\bI have [^.?!]*[.?!]?", caseSensitive: false),
      RegExp(r"\bMy [^.?!]*[.?!]?", caseSensitive: false),
      RegExp(r"doctor said [^.?!]*[.?!]?", caseSensitive: false),
    ];
    final traits = <String>[];
    for (final pattern in traitPatterns) {
      final matches = pattern.allMatches(message);
      for (final match in matches) {
        traits.add(match.group(0)!.trim());
      }
    }
    if (traits.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    String profRaw = prefs.getString('prof') ?? '{}';
    Map<String, String> profileMap = {};
    try {
      profileMap = Map<String, String>.from(jsonDecode(profRaw));
    } catch (e) {
      // Handle parsing error silently
    }
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    for (final trait in traits) {
      profileMap[timestamp] = trait;
    }
    await prefs.setString('prof', jsonEncode(profileMap));
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;
    await _extractAndSaveTrait(message);
    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
    });
    await _addMessage(ChatResponse(isUser: true, text: message, timestamp: DateTime.now()));
    await Future.delayed(const Duration(milliseconds: 2500)); // Simulate Gemini reading before typing
    await _addMessage(ChatResponse(isUser: false, isTyping: true, timestamp: DateTime.now()));
    _scrollDown();
    try {
      // Load traits from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String profRaw = prefs.getString('prof') ?? '{}';
      Map<String, String> profileMap = {};
      try {
        profileMap = Map<String, String>.from(jsonDecode(profRaw));
      } catch (_) {}
      String traitsText = profileMap.isNotEmpty
        ? profileMap.values.join(' | ')
        : 'None';
      String prompt =
        "User profile traits: $traitsText\nUser message: $message";
      var response = await _chat.sendMessage(Content.text(prompt));
      await Future.delayed(const Duration(seconds: 1)); // Add delay for realism
      setState(() {
        // Remove the last typing indicator
        if (history.isNotEmpty && history.last.isTyping) {
          history.removeLast();
        }
        _addMessage(ChatResponse(isUser: false, text: response.text, timestamp: DateTime.now()));
        _loading = false;
      });
      _scrollDown();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError(e.toString());
    }
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
    'isTyping': isTyping,
  };

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    isUser: json['isUser'] as bool? ?? false,
    text: json['text'] as String?,
    timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
  );
} 