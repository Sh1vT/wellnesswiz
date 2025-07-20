import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/utils/message_tile.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

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
  String? _userImg;
  Map<String, dynamic>? _chatroomData;
  final Map<String, String?> _userAvatars = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _auth = FirebaseAuth.instance;
    _initializeSharedPreferences();
    _addUserToChatroom();
    _fetchChatroomInfo();
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = _prefs.getString('username') ?? 'User';
      _userImg = _prefs.getString('userimg');
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

  Future<void> _fetchChatroomInfo() async {
    final doc = await _firestore.collection('chatrooms').doc(widget.roomId).get();
    if (doc.exists) {
      setState(() {
        _chatroomData = doc.data();
      });
    }
  }

  Future<void> _fetchUserAvatar(String uid) async {
    if (_userAvatars.containsKey(uid)) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data['photoURL'] != null && data['photoURL'].toString().isNotEmpty) {
        setState(() {
          _userAvatars[uid] = data['photoURL'];
        });
      } else {
        setState(() {
          _userAvatars[uid] = null;
        });
      }
    } catch (e) {
      setState(() {
        _userAvatars[uid] = null;
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
    final themeGreen = const Color.fromARGB(255, 106, 172, 67);
    final themeGray = const Color.fromRGBO(97, 97, 97, 1);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
              if (_chatroomData != null && (_chatroomData!['imageUrl'] ?? '').isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(_chatroomData!['imageUrl']),
                  backgroundColor: Colors.grey.shade200,
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.group, color: themeGreen, size: 28),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _chatroomData != null ? (_chatroomData!['name'] ?? 'Chatroom') : 'Chatroom',
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: themeGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_chatroomData != null && (_chatroomData!['theme'] ?? '').isNotEmpty)
                      Text(
                        _chatroomData!['theme'],
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
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
              child: StreamBuilder<QuerySnapshot>(
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
                    final data = doc.data() as Map<String, dynamic>;
                    return ChatMessage(
                      isUser: data['senderId'] == _auth.currentUser?.uid,
                      message: data['message'],
                      senderId: data['senderId'],
                      senderName: data['senderName'] ?? 'User',
                      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
                    );
                  }).toList();
                  if (snapshot.data!.docs.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                    itemCount: chatMessages.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      var content = chatMessages[index];
                      // Fetch avatar for other users if not cached
                      if (!content.isUser && !_userAvatars.containsKey(content.senderId)) {
                        _fetchUserAvatar(content.senderId);
                      }
                      final avatarUrl = content.isUser
                        ? _userImg
                        : _userAvatars[content.senderId];
                      return MessageTile(
                        sendByMe: content.isUser,
                        message: content.message,
                        senderName: content.senderName,
                        senderId: content.senderId,
                        timestamp: content.timestamp,
                        avatarUrl: avatarUrl ?? (_chatroomData != null ? _chatroomData!['imageUrl'] : null),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                  );
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
                      cursorColor: themeGreen,
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
                        if (msg.trim().isNotEmpty) _sendMessage(msg.trim());
                      },
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
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 120),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeGreen,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.send_rounded, color: Colors.white, size: 26),
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

class ChatMessage {
  final bool isUser;
  final String message;
  final String senderId;
  final String senderName;
  final DateTime? timestamp;

  ChatMessage({
    required this.isUser,
    required this.message,
    required this.senderId,
    required this.senderName,
    this.timestamp,
  });
} 