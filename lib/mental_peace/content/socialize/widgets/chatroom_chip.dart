import 'package:flutter/material.dart';
import '../models/chatroom_model.dart';
import 'chatroom_screen.dart';

class ChatroomChip extends StatelessWidget {
  final ChatroomModel chatroom;
  const ChatroomChip({required this.chatroom, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(roomId: chatroom.id),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: chatroom.imageUrl.isNotEmpty
                  ? NetworkImage(chatroom.imageUrl)
                  : null,
              child: (chatroom.imageUrl.isEmpty)
                  ? Icon(Icons.chat_bubble_outline, color: Color.fromARGB(255, 106, 172, 67), size: 22)
                  : null,
              onBackgroundImageError: (_, __) {},
            ),
            SizedBox(width: 12),
            // Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatroom.name,
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color.fromARGB(255, 106, 172, 67),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.group, size: 15, color: Colors.grey.shade600),
                    SizedBox(width: 3),
                    Text(
                      '${chatroom.memberCount ?? chatroom.members.length} members',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Mulish'),
                    ),
                  ],
                ),
                if (chatroom.theme.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.label, size: 13, color: Colors.grey.shade400),
                      SizedBox(width: 2),
                      Text(
                        chatroom.theme,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'Mulish'),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
} 