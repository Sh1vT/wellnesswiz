import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/chatrooms/chatroom_screen.dart';

class ChatRoomSelectionScreen extends StatefulWidget {
  const ChatRoomSelectionScreen({super.key});

  @override
  _ChatRoomSelectionScreenState createState() =>
      _ChatRoomSelectionScreenState();
}

class _ChatRoomSelectionScreenState extends State<ChatRoomSelectionScreen> {
  List<DocumentSnapshot> chatRooms = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";

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
    fetchChatRooms();
    _getUserInfo();
  }

  // Fetch existing chat rooms from Firestore
  void fetchChatRooms() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('chat_rooms').get();
    setState(() {
      chatRooms = snapshot.docs;
    });
  }

  // Create a new chat room with a user-entered topic
  void createNewChatRoom() async {
    TextEditingController topicController = TextEditingController();

    // Show a dialog to enter the topic
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Chat Room Topic'),
        content: TextField(
          controller: topicController,
          decoration: InputDecoration(hintText: 'Chat Room Topic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              String topic = topicController.text.trim();
              if (topic.isNotEmpty) {
                // Create the chat room with the entered topic and empty participants list
                DocumentReference newRoom = await FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .add({
                  'topic': topic,
                  'created_at': FieldValue.serverTimestamp(),
                  'participants': [],
                });

                Navigator.pop(context); // Close dialog

                // Navigate to the new chat room
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(roomId: newRoom.id),
                  ),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
            )),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Chat",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromRGBO(106, 172, 67, 1)),
              ),
              Text(
                " Rooms",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          chatRooms.isEmpty
              ? Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(
                          16), // Added padding for better spacing
                      height: 160, // Adjusted height for better layout
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.shade100,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center the contents vertically
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Center the contents horizontally
                        children: [
                          const Text(
                            'No chatrooms found.',
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: 14, // Adjusted text size
                            ),
                            textAlign:
                                TextAlign.center, // Align text to the center
                          ),
                          const Text(
                            'Create One!',
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: 20, // Adjusted text size
                            ),
                            textAlign:
                                TextAlign.center, // Align text to the center
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: chatRooms.length,
                    itemBuilder: (context, index) {
                      var room = chatRooms[index];
                      String topic = room['topic'] ??
                          'Anonymous Room'; // Fallback if topic is missing
                      return Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12)),
                        margin:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        padding: EdgeInsets.all(8),
                        child: ListTile(
                          trailing: Icon(
                            Icons.arrow_right_rounded,
                            size: 30,
                          ),
                          leading: Icon(
                            Icons.chat,
                            size: 30,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Anonymous Room',
                                style: TextStyle(fontSize: 18),
                              ),
                              Row(children: [
                                Text(
                                  "Topic: ",
                                  style: TextStyle(
                                      color: Color.fromRGBO(106, 172, 67, 1),
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  topic,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                )
                              ]),
                            ],
                          ),
                          onTap: () {
                            // Navigate to the selected chat room
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoomScreen(roomId: room.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromRGBO(106, 172, 67, 1),
          onPressed: createNewChatRoom,
          child: Icon(
            color: Colors.grey.shade200,
            Icons.add_box_outlined,
            size: 30,
          )),
    );
  }
}
