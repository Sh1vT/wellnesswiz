import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/post_tile.dart';
import '../models/post_model.dart';
import 'create_post_widget.dart';

class FeedTabContent extends StatelessWidget {
  const FeedTabContent({Key? key}) : super(key: key);

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
    return FutureBuilder<List<String>>(
      future: _getFollowedUserIds(),
      builder: (context, idSnap) {
        if (!idSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ids = idSnap.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('authorId', whereIn: ids)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            List<Widget> children = [
              const SizedBox(height: 16),
              const CreatePostWidget(),
            ];
            if (!snapshot.hasData) {
              children.add(const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ));
            } else {
              final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
              if (posts.isEmpty) {
                children.add(const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No posts yet.')),
                ));
              } else {
                children.addAll(posts.map((post) => PostTile(post: post)));
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
          },
        );
      },
    );
  }
} 