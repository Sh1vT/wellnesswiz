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
  final String roomId;
  ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  late final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  String? _username;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _initializeSharedPreferences();
    _addUserToChatroom();
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = _prefs.getString('username') ?? 'User';
    });
  }

  Future<void> _addUserToChatroom() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final docRef = _firestore.collection('chatrooms').doc(widget.roomId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final List members = data['members'] ?? [];
    if (!members.contains(userId)) {
      await docRef.update({
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': (data['memberCount'] ?? members.length) + 1,
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

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
    });

    try {
      await _firestore
          .collection('chatrooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'senderId': _auth.currentUser?.uid,
        'senderName': _username ?? 'User',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
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
        title: const Text('Chatroom'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
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
                    senderId: doc['senderId'],
                    senderName: doc['senderName'] ?? 'User',
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
                      senderName: content.senderName,
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
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
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
  const MessageTile({
    super.key,
    required this.sendByMe,
    required this.message,
    required this.senderName,
  });

  final bool sendByMe;
  final String message;
  final String senderName;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bgColor = sendByMe
        ? Colors.green.shade400
        : Colors.primaries[senderName.hashCode % Colors.primaries.length].shade200;
    final textColor = sendByMe ? Colors.white : Colors.black;
    return Column(
      crossAxisAlignment:
          sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          sendByMe ? 'You' : senderName,
          style: TextStyle(fontSize: 11.5, color: bgColor, fontWeight: FontWeight.bold),
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
                color: bgColor,
              ),
              child: Text(
                message,
                style: TextStyle(fontSize: 14, color: textColor),
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
  final String senderId;
  final String senderName;

  ChatMessage({
    required this.isUser,
    required this.message,
    required this.senderId,
    required this.senderName,
  });
} 