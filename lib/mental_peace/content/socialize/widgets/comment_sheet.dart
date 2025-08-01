import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../../../../utils/profanity_filter_util.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  final int initialCount;
  const CommentSheet({super.key, required this.postId, this.initialCount = 0});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  String? _errorMessage; // Add this for error display

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;
    
    final content = _controller.text.trim();
    
    // Check for profanity
    if (ProfanityFilterUtil.hasProfanity(content)) {
      setState(() {
        _errorMessage = ProfanityFilterUtil.getProfanityMessage();
      });
      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
      return;
    }
    
    setState(() => _sending = true);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final comment = CommentModel(
      id: '',
      postId: widget.postId,
      authorId: user.uid,
      authorName: userDoc['name'] ?? '',
      authorPhoto: user.photoURL ?? '',
      content: content,
      timestamp: Timestamp.now(),
    );
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add(comment.toMap());
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'commentCount': FieldValue.increment(1)});
    _controller.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('Comments', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          // Error message display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontFamily: 'Mulish',
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!.docs
                    .map((doc) => CommentModel.fromFirestore(doc, widget.postId))
                    .toList();
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }
                return ListView.separated(
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, i) {
                    final c = comments[i];
                    return ListTile(
                      leading: c.authorPhoto.isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(c.authorPhoto))
                          : const CircleAvatar(child: Icon(Icons.account_circle)),
                      title: Text(c.authorName, style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
                      subtitle: Text(c.content, style: const TextStyle(fontFamily: 'Mulish')),
                      trailing: Text(_formatTimestamp(c.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Color.fromARGB(255, 106, 172, 67)),
                onPressed: _sending ? null : _addComment,
              ),
            ],
          ),
        ],
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