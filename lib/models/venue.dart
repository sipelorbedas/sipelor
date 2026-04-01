/// Venue model for sports venue/location
class Venue {
  final String id;
  final String name;
  final String? venueType; // Futsal, Badminton, Basketball, Volleyball, etc.
  final String? description;
  final String address;
  final String city;
  final String? imageUrl;
  final double rating;
  final int totalReviews;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Venue({
    required this.id,
    required this.name,
    this.venueType,
    this.description,
    required this.address,
    required this.city,
    this.imageUrl,
    required this.rating,
    required this.totalReviews,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      venueType: json['venue_type'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      imageUrl: json['image_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'venue_type': venueType,
      'description': description,
      'address': address,
      'city': city,
      'image_url': imageUrl,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
