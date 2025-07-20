class ExerciseMusic {
  final String id;
  final String url;

  ExerciseMusic({required this.id, required this.url});

  factory ExerciseMusic.fromFirestore(Map<String, dynamic> data, String id) {
    return ExerciseMusic(
      id: id,
      url: data['url'] ?? '',
    );
  }

  static List<ExerciseMusic> defaultList = [
    ExerciseMusic(id: 'default1', url: 'assets/music/1.mp3'),
    // Add more local assets or fallback URLs as needed
  ];
} 