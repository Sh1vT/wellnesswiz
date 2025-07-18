import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'comment_sheet.dart';

class PostTile extends StatelessWidget {
  final PostModel post;
  const PostTile({required this.post, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
              Text(post.content, style: const TextStyle(fontSize: 16, fontFamily: 'Mulish')),
            ],
            if (post.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
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
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
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