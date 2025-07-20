import 'package:cloud_firestore/cloud_firestore.dart';
import '../mental_peace/content/models/thought.dart';

class ThoughtUploader {
  /// Uploads a list of Thought objects to the 'thoughts' collection in Firestore.
  static Future<void> uploadThoughts(List<Thought> thoughts) async {
    try {
    final collection = FirebaseFirestore.instance.collection('thoughts');
    for (final thought in thoughts) {
      await collection.add({
        'image': thought.image,
        'quote': thought.quote,
        'speaker': thought.speaker,
      });
      }
      print('Thoughts uploaded successfully');
    } catch (e) {
      print('Failed to upload thoughts: $e');
      // Don't rethrow the error to prevent app crashes
    }
  }

  /// Sample thoughts for uploading
  static List<Thought> sampleThoughts = [
    Thought(
      id: '',
      image: 'https://img.freepik.com/premium-photo/woman-stands-sky-mountain-view-sun-light_41762-286.jpg',
      quote: 'The only way to do great work is to love what you do.',
      speaker: 'Steve Jobs',
    ),
    Thought(
      id: '',
      image: 'https://thumbs.dreamstime.com/b/peaceful-nature-vintage-background-bench-park-42115401.jpg',
      quote: 'Life is what happens when you\'re busy making other plans.',
      speaker: 'John Lennon',
    ),
    Thought(
      id: '',
      image: 'https://static.vecteezy.com/system/resources/thumbnails/048/120/779/small_2x/peaceful-forest-lake-surrounded-by-misty-trees-reflecting-in-calm-water-serene-nature-scene-tranquility-concept-photo.jpg',
      quote: 'The future belongs to those who believe in the beauty of their dreams.',
      speaker: 'Eleanor Roosevelt',
    ),
  ];
} 