class ChatroomModel {
  final String id;
  final String name;
  final List<String> participants;
  final int popularity;
  final String imageUrl;
  final int memberCount;
  final String theme;
  final String description;

  ChatroomModel({
    required this.id,
    required this.name,
    required this.participants,
    required this.popularity,
    required this.imageUrl,
    required this.memberCount,
    required this.theme,
    required this.description,
  });

  factory ChatroomModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatroomModel(
      id: id,
      name: data['name'] ?? data['topic'] ?? '',
      participants: List<String>.from(data['members'] ?? data['participants'] ?? []),
      popularity: data['popularity'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      memberCount: data['memberCount'] ?? (data['members']?.length ?? 0),
      theme: data['theme'] ?? '',
      description: data['description'] ?? '',
    );
  }
} 