import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../mental_peace/content/models/thought.dart';

class ThoughtService {
  static List<Thought>? _cachedThoughts;

  /// Fetch from Firestore and return list. Fallback to defaults if needed.
  static Future<List<Thought>> fetchThoughts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('thoughts').get();
      final thoughts = snapshot.docs.map((doc) => Thought.fromFirestore(doc.data(), doc.id)).toList();
      if (thoughts.isNotEmpty) {
        _cachedThoughts = thoughts;
        return thoughts;
      }
    } catch (_) {}
    _cachedThoughts = Thought.defaultList;
    return Thought.defaultList;
  }

  /// Get cached thoughts without fetching again
  static List<Thought> getCachedThoughts() {
    return _cachedThoughts ?? Thought.defaultList;
  }

  /// Get cached file for image URL (handles both HTTP and assets)
  static Future<File?> getCachedImage(String imageUrl) async {
    if (imageUrl.startsWith('http')) {
      try {
        return await DefaultCacheManager().getSingleFile(imageUrl);
      } catch (_) {
        return null;
      }
    } else {
      // For asset paths, return null (use Image.asset directly)
      return null;
    }
  }

  /// Check if image is a remote URL
  static bool isRemoteImage(String imageUrl) {
    return imageUrl.startsWith('http');
  }
} 