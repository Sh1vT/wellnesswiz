import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/mental_peace/content/socialize/widgets/post_tile.dart';
import '../models/post_model.dart';
import 'create_post_widget.dart';

class FeedTabContent extends StatelessWidget {
  const FeedTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
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
  }
} 