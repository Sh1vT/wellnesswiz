import 'package:flutter/material.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/chatroom_screen.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/chatrooms_tab_content.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/comment_sheet.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/feed_tab_content.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/search_tab_content.dart';
import 'package:wellwiz/utils/color_palette.dart';
import '../models/chatroom_model.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'achievement_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/user_search_section.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/create_post_widget.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/feed_widget.dart';
import '../models/post_model.dart';

class SocialSection extends StatefulWidget {
  const SocialSection({super.key});

  @override
  State<SocialSection> createState() => _SocialSectionState();
}

class _SocialSectionState extends State<SocialSection> {
  int selectedTab = 0; // 0 = Feed, 1 = Chatrooms, 2 = Search
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

  Future<List<String>> _getFollowedUserIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final followingSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .get();
    final ids = followingSnap.docs.map((doc) => doc.id).toList();
    ids.add(user.uid);
    return ids.length > 10 ? ids.sublist(0, 10) : ids;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Achievements Banner (always at top)
    final achievementsBanner = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final cardWidth = screenWidth * 0.7;
          final cardHeight = cardWidth / 16 * 9 + 60;
          final bannerHeight = cardHeight + 16;
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
    );

    // Chips (always below achievements)
    final chipsRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: Text('Feed', style: TextStyle(
              color: selectedTab == 0 ? Colors.white : ColorPalette.black,
              fontFamily: 'Mulish',
            )),
            selected: selectedTab == 0,
            onSelected: (_) => setState(() => selectedTab = 0),
            selectedColor: ColorPalette.green,
            labelStyle: TextStyle(
              color: selectedTab == 0 ? Colors.white : ColorPalette.black,
              fontFamily: 'Mulish',
            ),
          ),
          SizedBox(width: 12),
          ChoiceChip(
            label: Text('Chatrooms', style: TextStyle(
              color: selectedTab == 1 ? Colors.white : ColorPalette.black,
              fontFamily: 'Mulish',
            )),
            selected: selectedTab == 1,
            onSelected: (_) => setState(() => selectedTab = 1),
            selectedColor: ColorPalette.green,
            labelStyle: TextStyle(
              color: selectedTab == 1 ? Colors.white : ColorPalette.black,
              fontFamily: 'Mulish',
            ),
          ),
          SizedBox(width: 12),
          ChoiceChip(
            label: Text('Search', style: TextStyle(
              color: selectedTab == 2 ? Colors.white : ColorPalette.black,
              fontFamily: 'Mulish',
            )),
            selected: selectedTab == 2,
            onSelected: (_) => setState(() => selectedTab = 2),
            selectedColor: ColorPalette.green,
            labelStyle: TextStyle(
              color: selectedTab == 2 ? Colors.white : ColorPalette.black,
              fontFamily: 'Mulish',
            ),
          ),
        ],
      ),
    );

    // Title Row (always at top)
    final titleRow = Padding(
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
    );

    // Back button (always at top)
    final backButton = Padding(
      padding: const EdgeInsets.only(left: 0, top: 8, right: 0, bottom: 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade800, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
    );

    // Main content for each tab
    Widget tabContent;
    if (selectedTab == 0) {
      tabContent = const FeedTabContent();
    } else if (selectedTab == 1) {
      tabContent = const ChatroomsTabContent();
    } else if (selectedTab == 2) {
      tabContent = const SearchTabContent();
    } else {
      tabContent = const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: backButton,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: titleRow,
            ),
            const SizedBox(height: 20),
            achievementsBanner,
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: chipsRow,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: tabContent,
            ),
          ],
        ),
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
