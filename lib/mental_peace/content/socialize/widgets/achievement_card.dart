import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String caption;
  final String name; // changed from username
  final int likeCount;
  final List<String> likedBy;
  final String achievementId;
  final String currentUserId;
  final double? width;
  final double? height;
  const AchievementCard({super.key, 
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.name, // changed from username
    required this.likeCount,
    required this.likedBy,
    required this.achievementId,
    required this.currentUserId,
    this.width,
    this.height,
  });

  void _toggleLike(BuildContext context) async {
    final docRef = FirebaseFirestore.instance.collection('achievements').doc(achievementId);
    final isLiked = likedBy.contains(currentUserId);
    await docRef.update({
      'likeCount': FieldValue.increment(isLiked ? -1 : 1),
      'likedBy': isLiked
          ? FieldValue.arrayRemove([currentUserId])
          : FieldValue.arrayUnion([currentUserId]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = likedBy.contains(currentUserId);
    return GestureDetector(
      onDoubleTap: () => _toggleLike(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width ?? 270,
            minWidth: width ?? 0,
            minHeight: height ?? 220,
            maxHeight: height ?? 320,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade300,
                            child: Icon(Icons.image, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        color: Colors.grey.shade800,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.green.shade300,
                                fontFamily: 'Mulish',
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Name flair at top left
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      name.split(' ').first, // First name
                      style: TextStyle(
                        color: Color.fromARGB(255, 106, 172, 67),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Mulish',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                // Like button and count at top right, styled like the name flair
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$likeCount',
                          style: TextStyle(
                            color: Color.fromARGB(255, 106, 172, 67),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 2),
                        GestureDetector(
                          onTap: () => _toggleLike(context),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Color.fromARGB(255, 106, 172, 67) : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 