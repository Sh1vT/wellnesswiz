import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'image_upload_util.dart';

class CreatePostWidget extends StatefulWidget {
  const CreatePostWidget({super.key});

  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final TextEditingController _contentController = TextEditingController();
  String? _imageUrl;
  bool _uploading = false;
  String? _error;

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await pickAndUploadImage();
    setState(() {
      _imageUrl = url;
      _uploading = false;
      if (url == null) _error = 'Image upload failed.';
    });
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _uploading = true; _error = null; });
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final post = PostModel(
        id: '',
        authorId: user.uid,
        authorHandle: userDoc['handle'] ?? '',
        authorName: userDoc['name'] ?? '',
        authorPhoto: user.photoURL ?? '',
        content: _contentController.text.trim(),
        imageUrl: _imageUrl ?? '',
        timestamp: Timestamp.now(),
        likeCount: 0,
        commentCount: 0,
      );
      await FirebaseFirestore.instance.collection('posts').add(post.toMap());
      setState(() {
        _contentController.clear();
        _imageUrl = null;
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created!')));
    } catch (e) {
      setState(() { _error = 'Failed to create post.'; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_imageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageUrl = null),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color.fromARGB(255, 106, 172, 67)),
                  onPressed: _uploading ? null : _pickImage,
                  tooltip: 'Add Image',
                ),
                if (_uploading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 106, 172, 67), // App green
                    foregroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_contentController.text.trim().isEmpty && _imageUrl == null) || _uploading
                      ? null
                      : _createPost,
                  child: Text('Post'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
} 