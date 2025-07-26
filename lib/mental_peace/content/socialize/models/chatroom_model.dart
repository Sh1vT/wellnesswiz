class ChatroomModel {
  final String id;
  final String name;
  final List<String> members;
  final int popularity;
  final String imageUrl;
  final int memberCount;
  final String theme;
  final String description;
  final String createdBy;

  ChatroomModel({
    required this.id,
    required this.name,
    required this.members,
    required this.popularity,
    required this.imageUrl,
    required this.memberCount,
    required this.theme,
    required this.description,
    required this.createdBy,
  });

  factory ChatroomModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatroomModel(
      id: id,
      name: data['name'] ?? data['topic'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      popularity: data['popularity'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      memberCount: data['memberCount'] ?? (data['members']?.length ?? 0),
      theme: data['theme'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }
} 