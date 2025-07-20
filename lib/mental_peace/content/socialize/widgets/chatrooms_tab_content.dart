import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/chatroom_chip.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/joined_chatroom_tile.dart';
import '../models/chatroom_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:wellwiz/secrets.dart';

// Shimmer card for loading state
class _ShimmerChatroomCard extends StatefulWidget {
  @override
  State<_ShimmerChatroomCard> createState() => _ShimmerChatroomCardState();
}

class _ShimmerChatroomCardState extends State<_ShimmerChatroomCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
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
                backgroundColor: Colors.grey.shade400,
                radius: 22,
                child: Icon(Icons.group, color: Colors.grey.shade500, size: 24),
              ),
              title: Container(
                height: 16,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 6),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, size: 15, color: Colors.grey.shade500),
                      SizedBox(width: 3),
                      Container(
                        height: 12,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.label, size: 13, color: Colors.grey.shade500),
                      SizedBox(width: 2),
                      Container(
                        height: 10,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade500),
            ),
          ),
        );
      },
    );
  }
}

class ChatroomsTabContent extends StatelessWidget {
  const ChatroomsTabContent({super.key});

  static Future<List<ChatroomModel>> getUserActiveChatrooms(List<ChatroomModel> joinedChatrooms, String userId) async {
    List<ChatroomModel> result = [];
    for (final room in joinedChatrooms) {
      // Always include if user is creator
      if (room.createdBy == userId) {
        result.add(room);
        continue;
      }
      // Otherwise, only if user has sent a message
      final messages = await FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(room.id)
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .limit(1)
          .get();
      if (messages.docs.isNotEmpty) {
        result.add(room);
      }
    }
    return result;
  }

  Widget _shimmeringChatroomList() {
    // Fallback shimmer using AnimatedContainer and Opacity
    return Column(
      children: List.generate(3, (i) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _ShimmerChatroomCard(),
        ),
      ),
    );
  }

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
          children.add(const SizedBox(height: 8));
          children.add(
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  label: const Text(
                    '+ Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Color.fromARGB(255, 106, 172, 67),
                  onPressed: () async {
                    final nameController = TextEditingController();
                    final themeController = TextEditingController();
                    File? imageFile;
                    String? imageUrl;
                    bool uploading = false;
                    await showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) {
                          Future<void> pickImage() async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (picked != null) {
                              setState(() { imageFile = File(picked.path); });
                            }
                          }
                          Future<void> uploadImage() async {
                            if (imageFile == null) return;
                            setState(() { uploading = true; });
                            final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
                            final req = http.MultipartRequest('POST', uri)
                              ..fields['upload_preset'] = cloudinaryUploadPreset
                              ..files.add(await http.MultipartFile.fromPath('file', imageFile!.path));
                            final res = await req.send();
                            if (res.statusCode == 200) {
                              final body = await res.stream.bytesToString();
                              final url = RegExp(r'"url":"(.*?)"').firstMatch(body)?.group(1)?.replaceAll(r'\/', '/');
                              setState(() { imageUrl = url; });
                            }
                            setState(() { uploading = false; });
                          }
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Text('Create Chatroom', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: pickImage,
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade400),
                                      ),
                                      child: imageFile != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(imageFile!, fit: BoxFit.cover, width: 90, height: 90),
                                            )
                                          : Icon(Icons.add_a_photo, color: Colors.grey.shade500, size: 36),
                                    ),
                                  ),
                                  if (imageFile != null && imageUrl == null && !uploading)
                                    TextButton.icon(
                                      onPressed: uploadImage,
                                      icon: Icon(Icons.cloud_upload, color: Color.fromARGB(255, 106, 172, 67)),
                                      label: Text('Upload Image', style: TextStyle(fontFamily: 'Mulish', color: Color.fromARGB(255, 106, 172, 67))),
                                    ),
                                  if (uploading)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  if (imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text('Image uploaded!', style: TextStyle(color: Colors.green, fontFamily: 'Mulish')),
                                    ),
                                  TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(labelText: 'Chatroom Name', labelStyle: TextStyle(fontFamily: 'Mulish')),
                                    style: const TextStyle(fontFamily: 'Mulish'),
                                  ),
                                  TextField(
                                    controller: themeController,
                                    decoration: const InputDecoration(labelText: 'Theme (optional)', labelStyle: TextStyle(fontFamily: 'Mulish')),
                                    style: const TextStyle(fontFamily: 'Mulish'),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish', color: Color.fromARGB(255, 97, 97, 97))),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Color.fromARGB(255, 106, 172, 67),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Create', style: TextStyle(color: Colors.white, fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final theme = themeController.text.trim();
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (name.isNotEmpty && user != null) {
                                    String finalImageUrl = imageUrl ?? '';
                                    if (imageFile != null && imageUrl == null) {
                                      await uploadImage();
                                      finalImageUrl = imageUrl ?? '';
                                    }
                                    await FirebaseFirestore.instance.collection('chatrooms').add({
                                      'name': name,
                                      'theme': theme,
                                      'createdBy': user.uid,
                                      'participants': [user.uid],
                                      'memberCount': 1,
                                      'popularity': 0,
                                      'imageUrl': finalImageUrl,
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          );
          children.add(
            FutureBuilder<List<ChatroomModel>>(
              future: ChatroomsTabContent.getUserActiveChatrooms(joinedChatrooms, userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: _shimmeringChatroomList(),
                  );
                }
                final activeChatrooms = snapshot.data!;
                if (activeChatrooms.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('You have not joined any chatrooms.')),
                  );
                }
                return Column(
                  children: activeChatrooms.map((chatroom) => JoinedChatroomTile(chatroom: chatroom)).toList(),
                );
              },
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
} 