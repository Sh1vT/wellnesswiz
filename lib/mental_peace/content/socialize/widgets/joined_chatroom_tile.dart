import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chatroom_model.dart';
import 'chatroom_screen.dart';

class JoinedChatroomTile extends StatelessWidget {
  final ChatroomModel chatroom;
  const JoinedChatroomTile({required this.chatroom, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: Color.fromARGB(255, 106, 172, 67),
            width: 6,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          backgroundImage: chatroom.imageUrl.isNotEmpty ? NetworkImage(chatroom.imageUrl) : null,
          child: chatroom.imageUrl.isEmpty
              ? Icon(Icons.group, color: Color.fromARGB(255, 106, 172, 67))
              : null,
        ),
        title: Text(
          chatroom.name,
          style: TextStyle(
            fontFamily: 'Mulish',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color.fromARGB(255, 106, 172, 67),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, size: 15, color: Colors.grey.shade600),
                SizedBox(width: 3),
                Text(
                  '${chatroom.memberCount} members',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Mulish'),
                ),
                if (chatroom.theme.isNotEmpty) ...[
                  SizedBox(width: 10),
                  Icon(Icons.label, size: 13, color: Colors.grey.shade400),
                  SizedBox(width: 2),
                  Text(
                    chatroom.theme,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'Mulish'),
                  ),
                ]
              ],
            ),
            SizedBox(height: 4),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chatrooms')
                  .doc(chatroom.id)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox();
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Text('No messages yet', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Mulish'));
                }
                final data = docs.first.data();
                final sender = data['senderName'] ?? 'User';
                final message = data['message'] ?? '';
                return Text(
                  '$sender: $message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontFamily: 'Mulish'),
                );
              },
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(roomId: chatroom.id),
            ),
          );
        },
      ),
    );
  }
} 