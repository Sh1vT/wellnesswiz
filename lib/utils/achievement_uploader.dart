import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadSampleAchievements() async {
  final achievements = [
    {
      'userId': 'user1',
      'name': 'Priya Sharma',
      'imageUrl': 'https://as1.ftcdn.net/v2/jpg/01/43/11/00/1000_F_143110026_C4EmjmmVVYlcXpTtmCwil5Xv0wSfVCrY.jpg',
      'title': 'Completed 5K Run!',
      'caption': 'Felt amazing to finish my first 5K.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'run',
      'likeCount': 4,
      'likedBy': ['u2','u5','u3','u4'],
    },
    {
      'userId': 'user2',
      'name': 'Amit',
      'imageUrl': 'https://as1.ftcdn.net/v2/jpg/01/43/11/00/1000_F_143110026_C4EmjmmVVYlcXpTtmCwil5Xv0wSfVCrY.jpg',
      'title': '7-Day Meditation Streak',
      'caption': 'Mindfulness is becoming a habit.',
      'timestamp': DateTime.now().millisecondsSinceEpoch + 1000,
      'type': 'meditation',
      'likeCount': 4,
      'likedBy': ['u2','u5','u3','u4'],
    },
    {
      'userId': 'user3',
      'name': 'Sara',
      'imageUrl': 'https://as1.ftcdn.net/v2/jpg/01/43/11/00/1000_F_143110026_C4EmjmmVVYlcXpTtmCwil5Xv0wSfVCrY.jpg',
      'title': 'Lost 2kg in a Month',
      'caption': 'Small steps, big results!',
      'timestamp': DateTime.now().millisecondsSinceEpoch + 2000,
      'type': 'weight_loss',
      'likeCount': 1,
      'likedBy': ['u2'],
    },
    {
      'userId': 'user4',
      'name': 'John',
      'imageUrl': 'https://as1.ftcdn.net/v2/jpg/01/43/11/00/1000_F_143110026_C4EmjmmVVYlcXpTtmCwil5Xv0wSfVCrY.jpg',
      'title': 'Shared My Story',
      'caption': 'Hope this inspires someone else.',
      'timestamp': DateTime.now().millisecondsSinceEpoch + 3000,
      'type': 'story',
      'likeCount': 2,
      'likedBy': ['u2','u5'],
    },
    {
      'userId': 'user5',
      'name': 'Meera',
      'imageUrl': 'https://as1.ftcdn.net/v2/jpg/01/43/11/00/1000_F_143110026_C4EmjmmVVYlcXpTtmCwil5Xv0wSfVCrY.jpg',
      'title': 'Helped a Friend',
      'caption': 'Supporting each other is what matters.',
      'timestamp': DateTime.now().millisecondsSinceEpoch + 4000,
      'type': 'support',
      'likeCount': 5,
      'likedBy': ['u2','u5','u3','u4','u6'],
    },
  ];

  final achievementsRef = FirebaseFirestore.instance.collection('achievements');
  for (final achievement in achievements) {
    await achievementsRef.add(achievement);
  }
  print('Sample achievements uploaded!');
} 