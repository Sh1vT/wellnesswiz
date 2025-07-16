import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  const LikeButton({required this.postId, Key? key}) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
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