import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../mental_peace/content/models/exercise_music.dart';

class ExerciseMusicService {
  static List<ExerciseMusic>? _cachedMusics;

  /// Fetch from Firestore and return list. Fallback to defaults if needed.
  static Future<List<ExerciseMusic>> fetchMusics() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('exercises').get();
      final musics = snapshot.docs.map((doc) => ExerciseMusic.fromFirestore(doc.data(), doc.id)).toList();
      if (musics.isNotEmpty) {
        _cachedMusics = musics;
        return musics;
      }
    } catch (_) {}
    _cachedMusics = ExerciseMusic.defaultList;
    return ExerciseMusic.defaultList;
  }

  /// Get cached musics without fetching again
  static List<ExerciseMusic> getCachedMusics() {
    return _cachedMusics ?? ExerciseMusic.defaultList;
  }

  /// Get cached file for music URL (handles both HTTP and assets)
  static Future<File?> getCachedMusic(String musicUrl) async {
    if (musicUrl.startsWith('http')) {
      try {
        return await DefaultCacheManager().getSingleFile(musicUrl);
      } catch (_) {
        return null;
      }
    } else {
      // For asset paths, return null (use asset directly)
      return null;
    }
  }

  /// Check if music is a remote URL
  static bool isRemoteMusic(String musicUrl) {
    return musicUrl.startsWith('http');
  }
} 