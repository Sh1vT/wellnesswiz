class HospitalRating {
  final String userId;
  final String userName;
  final double rating;
  final String review;
  final DateTime timestamp;

  HospitalRating({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.review,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'review': review,
    'timestamp': timestamp.toIso8601String(),
  };

  static HospitalRating fromJson(Map<String, dynamic> json) => HospitalRating(
    userId: json['userId'],
    userName: json['userName'] ?? '',
    rating: (json['rating'] as num).toDouble(),
    review: json['review'],
    timestamp: DateTime.parse(json['timestamp']),
  );
} 