import 'package:flutter/material.dart';
import '../models/chatroom_model.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'achievement_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/mental_peace/content/widgets/chatroom_screen.dart';

class SocialSection extends StatefulWidget {
  const SocialSection({super.key});

  @override
  State<SocialSection> createState() => _SocialSectionState();
}

class _SocialSectionState extends State<SocialSection> {
  int selectedTab = 0; // 0 = Feed, 1 = Chatrooms
  List<ChatroomModel> popularChatrooms = [];
  List<ChatroomModel> joinedChatrooms = [];

  @override
  void initState() {
    super.initState();
    _loadChatrooms();
  }

  Future<void> _loadChatrooms() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snapshot = await FirebaseFirestore.instance.collection('chatrooms').get();
    final allRooms = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ChatroomModel.fromFirestore(data, doc.id);
    }).toList();
    setState(() {
      popularChatrooms = List<ChatroomModel>.from(allRooms);
      joinedChatrooms = allRooms.where((room) => room.participants.contains(userId)).toList();
      popularChatrooms.sort((a, b) => b.popularity.compareTo(a.popularity));
      if (popularChatrooms.length > 10) popularChatrooms = popularChatrooms.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 8, right: 0, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade800, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
            ),
            // Title Row (like ChatPage)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Social",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                        fontSize: 40,
                        color: Color.fromARGB(255, 106, 172, 67)),
                  ),
                  Text(
                    " Section",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                        fontSize: 40,
                        color: const Color.fromRGBO(97, 97, 97, 1)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Achievements Banner (horizontal scroll, from Firestore)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final cardWidth = screenWidth * 0.7; // 70% of screen width
                final cardHeight = cardWidth / 16 * 9 + 60; // 16:9 image + text area
                final bannerHeight = cardHeight + 16; // add some vertical margin
                return SizedBox(
                  height: bannerHeight,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('achievements')
                        .orderBy('likeCount', descending: true)
                        .orderBy('timestamp', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(child: Text('No achievements yet!'));
                      }
                      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                      final cards = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return AchievementCard(
                          imageUrl: data['imageUrl'] ?? '',
                          title: data['title'] ?? '',
                          caption: data['caption'] ?? '',
                          name: data['name'] ?? 'User',
                          likeCount: data['likeCount'] ?? 0,
                          likedBy: List<String>.from(data['likedBy'] ?? []),
                          achievementId: doc.id,
                          currentUserId: currentUserId,
                          width: cardWidth,
                          height: cardHeight,
                        );
                      }).toList();
                      return AutoScrollingAchievementsBanner(cards: cards);
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            // Feed/Chatrooms Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('Feed'),
                    selected: selectedTab == 0,
                    onSelected: (_) => setState(() => selectedTab = 0),
                    selectedColor: Color.fromARGB(255, 106, 172, 67),
                    labelStyle: TextStyle(
                      color: selectedTab == 0 ? Colors.white : Colors.black,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  SizedBox(width: 12),
                  ChoiceChip(
                    label: Text('Chatrooms'),
                    selected: selectedTab == 1,
                    onSelected: (_) => setState(() => selectedTab = 1),
                    selectedColor: Color.fromARGB(255, 106, 172, 67),
                    labelStyle: TextStyle(
                      color: selectedTab == 1 ? Colors.white : Colors.black,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Main Content
            SizedBox(
              height: 500, // or use MediaQuery for dynamic height
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('chatrooms').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final allRooms = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ChatroomModel.fromFirestore(data, doc.id);
                    }).toList();
                    List<ChatroomModel> popularChatrooms = List<ChatroomModel>.from(allRooms);
                    List<ChatroomModel> joinedChatrooms = allRooms.where((room) => room.participants.contains(userId)).toList();
                    popularChatrooms.sort((a, b) => b.popularity.compareTo(a.popularity));
                    if (popularChatrooms.length > 10) popularChatrooms = popularChatrooms.take(10).toList();
                    return selectedTab == 0
                        ? _FeedSection()
                        : _ChatroomsSection(
                            popularChatrooms: popularChatrooms,
                            joinedChatrooms: joinedChatrooms,
                          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement feed list
    return Center(child: Text('Feed coming soon!'));
  }
}

class _ChatroomsSection extends StatelessWidget {
  final List<ChatroomModel> popularChatrooms;
  final List<ChatroomModel> joinedChatrooms;
  const _ChatroomsSection({required this.popularChatrooms, required this.joinedChatrooms});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popular Chatrooms (chips)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text('Popular Chatrooms', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularChatrooms.length,
            separatorBuilder: (_, __) => SizedBox(width: 8),
            itemBuilder: (context, i) => _ChatroomChip(chatroom: popularChatrooms[i]),
          ),
        ),
        SizedBox(height: 16),
        // Joined Chatrooms (list)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text('Your Chatrooms', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: joinedChatrooms.length,
            itemBuilder: (context, i) => _JoinedChatroomTile(chatroom: joinedChatrooms[i]),
          ),
        ),
      ],
    );
  }
}

class _ChatroomChip extends StatelessWidget {
  final ChatroomModel chatroom;
  const _ChatroomChip({required this.chatroom});

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
              backgroundImage: chatroom.imageUrl != null && chatroom.imageUrl.isNotEmpty
                  ? NetworkImage(chatroom.imageUrl)
                  : null,
              child: (chatroom.imageUrl == null || chatroom.imageUrl.isEmpty)
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
                      '${chatroom.memberCount ?? chatroom.participants.length} members',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Mulish'),
                    ),
                  ],
                ),
                if (chatroom.theme != null && chatroom.theme.isNotEmpty) ...[
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

class _JoinedChatroomTile extends StatelessWidget {
  final ChatroomModel chatroom;
  const _JoinedChatroomTile({required this.chatroom});

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
                final data = docs.first.data() as Map<String, dynamic>;
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

class AutoScrollingAchievementsBanner extends StatefulWidget {
  final List<Widget> cards;
  const AutoScrollingAchievementsBanner({required this.cards, Key? key}) : super(key: key);

  @override
  State<AutoScrollingAchievementsBanner> createState() => _AutoScrollingAchievementsBannerState();
}

class _AutoScrollingAchievementsBannerState extends State<AutoScrollingAchievementsBanner> with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 60), // Faster speed
    )..addListener(_scroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.repeat();
    });
  }

  void _scroll() {
    if (!_controller.hasClients) return;
    final maxScroll = _controller.position.maxScrollExtent;
    final value = _animationController.value;
    _controller.jumpTo(value * maxScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate the list for seamless looping
    final cards = [...widget.cards, ...widget.cards];
    return ListView.builder(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index % widget.cards.length],
    );
  }
} 