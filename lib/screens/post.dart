class Post {
  final int id;
  final int userId; // Changed to int
  final String description;
  final String imagePath;
  final DateTime createdAt;
  final String fullName; // Added for full name
  final String? profileImage; // Added for profile image
  final double? latitude; // Added for latitude
  final double? longitude; // Added for longitude
  final bool isLiked; // Added for like status
  final bool isSaved; // Added for saved status
  final int totalLikes; // Added for total likes

  Post({
    required this.id,
    required this.userId, // Changed to int
    required this.description,
    required this.imagePath,
    required this.createdAt,
    required this.fullName, // Added to constructor
    this.profileImage, // Added to constructor
    this.latitude, // Added to constructor
    this.longitude, // Added to constructor
    required this.isLiked, // Added to constructor
    required this.isSaved, // Added to constructor
    required this.totalLikes, // Added to constructor
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'], // No change needed here
      description: json['description'],
      imagePath: json['image_path'],
      createdAt: DateTime.parse(json['created_at']),
      fullName: json['full_name'], // Added full name
      profileImage: json['profile_image'], // Added profile image
      latitude: json['latitude'], // Added latitude
      longitude: json['longitude'], // Added longitude
      isLiked: json['is_liked'] ?? false, // Added isLiked
      isSaved: json['is_saved'] ?? false, // Added isSaved
      totalLikes: json['total_likes'] ?? 0, // Added totalLikes
    );
  }
}
