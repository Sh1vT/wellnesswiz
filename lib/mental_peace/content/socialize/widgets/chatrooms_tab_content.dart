import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/chatroom_chip.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/joined_chatroom_tile.dart';
import '../models/chatroom_model.dart';
import 'chatroom_screen.dart';

class ChatroomsTabContent extends StatelessWidget {
  const ChatroomsTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chatrooms').snapshots(),
      builder: (context, snapshot) {
        List<Widget> children = [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text('Popular Chatrooms', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ];
        if (!snapshot.hasData) {
          children.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ));
        } else {
          final allRooms = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ChatroomModel.fromFirestore(data, doc.id);
          }).toList();
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          final popularChatrooms = List<ChatroomModel>.from(allRooms);
          final joinedChatrooms = allRooms.where((room) => room.participants.contains(userId)).toList();
          popularChatrooms.sort((a, b) => b.popularity.compareTo(a.popularity));
          if (popularChatrooms.length > 10) popularChatrooms.removeRange(10, popularChatrooms.length);
          children.add(
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularChatrooms.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, i) => ChatroomChip(chatroom: popularChatrooms[i]),
              ),
            ),
          );
          children.add(const SizedBox(height: 16));
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('Your Chatrooms', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          );
          if (joinedChatrooms.isEmpty) {
            children.add(const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('You have not joined any chatrooms.')),
            ));
          } else {
            children.addAll(joinedChatrooms.map((chatroom) => JoinedChatroomTile(chatroom: chatroom)));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
} 