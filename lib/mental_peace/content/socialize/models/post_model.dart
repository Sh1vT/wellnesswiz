import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorHandle;
  final String authorName;
  final String authorPhoto;
  final String content;
  final String imageUrl;
  final Timestamp timestamp;
  final int likeCount;
  final int commentCount;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorHandle,
    required this.authorName,
    required this.authorPhoto,
    required this.content,
    required this.imageUrl,
    required this.timestamp,
    required this.likeCount,
    required this.commentCount,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorHandle: data['authorHandle'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhoto: data['authorPhoto'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorHandle': authorHandle,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }
} 