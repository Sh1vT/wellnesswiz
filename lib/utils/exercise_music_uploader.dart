import 'package:cloud_firestore/cloud_firestore.dart';
import '../mental_peace/content/models/exercise_music.dart';

class ExerciseMusicUploader {
  /// Uploads a list of ExerciseMusic objects to the 'exercises' collection in Firestore.
  static Future<void> uploadMusics(List<ExerciseMusic> musics) async {
    try {
    final collection = FirebaseFirestore.instance.collection('exercises');
    for (final music in musics) {
      await collection.add({
        'url': music.url,
      });
      }
      print('Exercise music uploaded successfully');
    } catch (e) {
      print('Failed to upload exercise music: $e');
      // Don't rethrow the error to prevent app crashes
    }
  }

  /// Sample exercise music for uploading
  static List<ExerciseMusic> sampleMusics = [
    ExerciseMusic(
      id: '123',
      url: 'https://aac.saavncdn.com/415/28fea4b0a1ca15f9ec4c74aa76548594_160.mp4',
    ),
    ExerciseMusic(
      id: '456',
      url: 'https://aac.saavncdn.com/510/f0e26aa3fc1e9f278279f17adb120a6f_sar_160.mp4',
    ),
    ExerciseMusic(
      id: '789',
      url: 'https://aac.saavncdn.com/157/14b9c16b6db0d53268d4be9b9385c4c8_sar_160.mp4',
    ),
  ];
} 