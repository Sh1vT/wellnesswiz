import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'comment_sheet.dart';

class FeedWidget extends StatelessWidget {
  const FeedWidget({super.key});

  Future<List<String>> _getFollowedUserIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final followingSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .get();
    final ids = followingSnap.docs.map((doc) => doc.id).toList();
    ids.add(user.uid); // Include own posts
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getFollowedUserIds(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final followedIds = snapshot.data!;
        if (followedIds.isEmpty) {
          return const Center(child: Text('No posts to show. Follow users to see their posts!'));
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('authorId', whereIn: followedIds.length > 10 ? followedIds.sublist(0, 10) : followedIds)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, postSnap) {
            if (!postSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final posts = postSnap.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
            if (posts.isEmpty) {
              return const Center(child: Text('No posts yet.'));
            }
            return ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _PostTile(post: posts[i]),
            );
          },
        );
      },
    );
  }
}

class _PostTile extends StatelessWidget {
  final PostModel post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                post.authorPhoto.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(post.authorPhoto))
                    : const CircleAvatar(child: Icon(Icons.account_circle)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish')),
                    Text('@${post.authorHandle}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Mulish', fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(post.content, style: const TextStyle(fontSize: 16)),
            ],
            if (post.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post.imageUrl, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _LikeButton(postId: post.id),
                const SizedBox(width: 8),
                Text('${post.likeCount}', style: const TextStyle(fontFamily: 'Mulish')),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      builder: (context) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: CommentSheet(postId: post.id, initialCount: post.commentCount),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.comment, color: Colors.grey.shade600, size: 22),
                      const SizedBox(width: 8),
                      Text('${post.commentCount}', style: const TextStyle(fontFamily: 'Mulish')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _LikeButton extends StatefulWidget {
  final String postId;
  const _LikeButton({required this.postId});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool _liked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(user.uid)
        .get();
    setState(() {
      _liked = doc.exists;
      _loading = false;
    });
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final likeRef = postRef.collection('likes').doc(user.uid);
    if (_liked) {
      await likeRef.delete();
      await postRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp(), 'userId': user.uid});
      await postRef.update({'likeCount': FieldValue.increment(1)});
    }
    setState(() {
      _liked = !_liked;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.red : Colors.grey.shade600),
      onPressed: _loading ? null : _toggleLike,
      tooltip: _liked ? 'Unlike' : 'Like',
    );
  }
} 