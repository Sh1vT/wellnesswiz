import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadSampleChatrooms() async {
  final chatrooms = [
    {
      'name': 'Anxiety Support',
      'description': 'A safe space to talk about anxiety and coping strategies.',
      'theme': 'Anxiety',
      'imageUrl': 'https://example.com/anxiety.png',
      'createdAt': DateTime.now(),
      'createdBy': 'user1',
      'members': ['user1', 'user2'],
      'memberCount': 2,
      'popularity': 12,
      'isPublic': true,
      'invited': [],
    },
    {
      'name': 'Fitness Buddies',
      'description': 'Share your workouts and motivate each other.',
      'theme': 'Fitness',
      'imageUrl': 'https://example.com/fitness.png',
      'createdAt': DateTime.now(),
      'createdBy': 'user2',
      'members': ['user2', 'user3', 'user4'],
      'memberCount': 3,
      'popularity': 8,
      'isPublic': true,
      'invited': [],
    },
    {
      'name': 'Mindfulness & Meditation',
      'description': 'Discuss meditation techniques and mindfulness.',
      'theme': 'Mindfulness',
      'imageUrl': 'https://example.com/mindfulness.png',
      'createdAt': DateTime.now(),
      'createdBy': 'user3',
      'members': ['user3'],
      'memberCount': 1,
      'popularity': 5,
      'isPublic': true,
      'invited': [],
    },
    {
      'name': 'General Wellness',
      'description': 'Talk about anything related to health and well-being.',
      'theme': 'Wellness',
      'imageUrl': 'https://example.com/wellness.png',
      'createdAt': DateTime.now(),
      'createdBy': 'user4',
      'members': ['user4', 'user5'],
      'memberCount': 2,
      'popularity': 10,
      'isPublic': true,
      'invited': [],
    },
    {
      'name': 'Sleep Support',
      'description': 'Tips and support for better sleep.',
      'theme': 'Sleep',
      'imageUrl': 'https://example.com/sleep.png',
      'createdAt': DateTime.now(),
      'createdBy': 'user5',
      'members': ['user5'],
      'memberCount': 1,
      'popularity': 3,
      'isPublic': true,
      'invited': [],
    },
  ];

  final ref = FirebaseFirestore.instance.collection('chatrooms');
  for (final room in chatrooms) {
    await ref.add(room);
  }
  print('Sample chatrooms uploaded!');
} 