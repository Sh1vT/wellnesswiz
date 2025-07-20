class Thought {
  final String id;
  final String image;
  final String quote;
  final String speaker;

  Thought({
    required this.id,
    required this.image,
    required this.quote,
    required this.speaker,
  });

  factory Thought.fromFirestore(Map<String, dynamic> data, String id) {
    return Thought(
      id: id,
      image: data['image'] ?? 'assets/thought/0.png',
      quote: data['quote'] ?? 'Stay positive!',
      speaker: data['speaker'] ?? 'Unknown',
    );
  }

  static List<Thought> defaultList = [
    Thought(
      id: 'default1',
      image: 'assets/thought/0.png',
      quote: 'Stay positive!',
      speaker: 'Unknown',
    ),
    // Add more default thoughts as needed
  ];
} 