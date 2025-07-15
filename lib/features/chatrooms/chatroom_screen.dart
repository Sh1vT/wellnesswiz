import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wellwiz/secrets.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId; // Add roomId to the constructor
  ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final safetysettings = [
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  ];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  late final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  late final ChatSession _chat;
  static const _apiKey = geminikey;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _initializeSharedPreferences();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      safetySettings: safetysettings,
    );
    _chat = _model.startChat();
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
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

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return; // Do nothing if the message is empty
    }

    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
    });

    // Check if the message starts with /wiz
    bool isGeminiCommand = message.startsWith('/wiz');

    // Prepare the prompt for the Gemini model

    // Check if the message is targeted to Gemini
    if (isGeminiCommand) {
      // Send the message to the Gemini model
      String promptforGemini = """You are being used as a mental health chatbot for demonstration purposes and not commercially or professionally.
      The user has entered this message: $message. Respond to that message. 
      """;
      var response = await _chat.sendMessage(Content.text(message));
      print("Response : " + response.text!);

      // if (response.text!.trim().toLowerCase() == "no" ||
      //     response.text!.trim().toLowerCase() == "no.") {
      //   setState(() {
      //     _loading = false;
      //   });
      //   return; // If the response is "no", don't save the message
      // }

      // Save the user's message and Gemini's response to Firestore
      try {
        // Save user's message to Firestore
        await _firestore
            .collection('chatrooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'senderId': _auth.currentUser?.uid,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Save Gemini's response to Firestore
        await _firestore
            .collection('chatrooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'senderId': 'gemini',
          'message': response.text!,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _loading = false;
        });

        _scrollDown(); // Automatically scroll down after sending a message
      } catch (e) {
        setState(() {
          _loading = false;
        });
        _showError(e.toString());
      }
    } else {
      String prompt =
          """You are being used as a mental health chatbot for demonstration purposes and not commercially or professionally.
      Currently you are employed as a gateway inside a chatroom. The user is going to enter their message.
      Their message starts now : $message. The message has ended.
      Bear in mind that this chatbot application was designed for people to seek mental help and reduce strain of their daily lives, so you can allow mild political discussions or darker themed jokes and gags.
      However you cannot allow some user to demean others. They might demean themselves, allow that because the other users will only help them feel better. You can also allow mild usage of swears.
      Hence, If you think the message by user is insensitive and may harm other users in the chatroom mentally then respond with the plain text of "no" and nothing else.
      If the message is targeted to you, which is decided if the message starts with "/wiz", then reply to that message.
      If the message is well and good and not targeted to you (not starting with "/wiz") either but others in the chatroom then reply with plain text of "someone" and nothing else.
      """;
      var response = await _chat.sendMessage(Content.text(prompt));
      print(response.text!);
      if (response.text!.trim().toLowerCase() == "no" ||
          response.text!.trim().toLowerCase() == "no.") {
        setState(() {
          _loading = false;
        });
        return; // If the response is "no", don't save the message
      }

      // Handle the case where the message is not targeting Gemini

      if (response.text!.trim().toLowerCase() == "someone" ||
          response.text!.trim().toLowerCase() == "someone.") {
        try {
          // Save the user's message to Firestore
          await _firestore
              .collection('chatrooms')
              .doc(widget.roomId)
              .collection('messages')
              .add({
            'senderId': _auth.currentUser?.uid,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _loading = false;
          });

          _scrollDown(); // Automatically scroll down after sending a message
        } catch (e) {
          setState(() {
            _loading = false;
          });
          _showError(e.toString());
        }
      }
    }
  }

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
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anonymous Chatroom'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // StreamBuilder for real-time updates
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatrooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<ChatMessage> chatMessages = snapshot.data!.docs.map((doc) {
                  return ChatMessage(
                    isUser: doc['senderId'] == _auth.currentUser?.uid,
                    message: doc['message'],
                    senderId: doc['senderId'], // Include senderId here
                  );
                }).toList();

                if (snapshot.data!.docs.isNotEmpty) {
                  _scrollDown();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
                  itemCount: chatMessages.length,
                  controller: _scrollController,
                  itemBuilder: (context, index) {
                    var content = chatMessages[index];
                    return MessageTile(
                      sendByMe: content.isUser,
                      message: content.message,
                      isGemini: content.senderId ==
                          'gemini', // Check if the sender is Gemini
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 15);
                  },
                );
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
                            hintText: 'Enter your message...',
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
                      onTap: () {
                        final message = _textController.text.trim();
                        if (message.isNotEmpty) {
                          _sendMessage(message);
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
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

class MessageTile extends StatelessWidget {
  const MessageTile(
      {super.key,
      required this.sendByMe,
      required this.message,
      required this.isGemini});

  final bool sendByMe;
  final String message;
  final bool isGemini; // Add this parameter

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment:
          sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isGemini ? 'Wizard' : (sendByMe ? 'You' : 'Anonymous'),
          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: size.width / 1.7,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: sendByMe
                      ? const Radius.circular(12)
                      : const Radius.circular(4),
                  bottomRight: sendByMe
                      ? const Radius.circular(4)
                      : const Radius.circular(12),
                ),
                color: isGemini
                    ? Colors.grey.shade200 // Different color for Gemini
                    : (sendByMe ? Colors.green.shade400 : Colors.grey.shade200),
              ),
              child: MarkdownBody(
                data: message,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                      fontSize: 14,
                      color: isGemini
                          ? Colors.black
                          : (sendByMe ? Colors.white : Colors.black)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatMessage {
  final bool isUser;
  final String message;
  final String senderId; // Add senderId field

  ChatMessage(
      {required this.isUser, required this.message, required this.senderId});
}
