class SkillModel {
  final int id;
  final String title;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final int ownerId;
  final String ownerName;
  final String? ownerProfileImage;
  final String? imageUrl;
  final int credits;
  final double rating;
  final int reviewCount;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? availability;
  final String? experienceLevel;
  final List<String> tags;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SkillModel({
    required this.id,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName,
    required this.ownerId,
    required this.ownerName,
    this.ownerProfileImage,
    this.imageUrl,
    this.credits = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.location,
    this.latitude,
    this.longitude,
    this.availability,
    this.experienceLevel,
    this.tags = const [],
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['title'] ?? json['name'] ?? '';
    final rawCat = json['category_name'] ?? json['category'] ?? 'General';

    return SkillModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: rawName.toString(),
      description: (json['description'] != null && json['description'].toString().isNotEmpty)
          ? json['description'].toString()
          : 'Learn $rawName with local peer exchange and mentorship.',
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: rawCat.toString(),
      ownerId: json['owner_id'] is int ? json['owner_id'] : int.tryParse(json['owner_id']?.toString() ?? '') ?? 1,
      ownerName: json['owner_name'] ?? 'Local Mentor',
      ownerProfileImage: json['owner_profile_image'] ?? 'https://i.pravatar.cc/150',
      imageUrl: json['image_url'] ?? 'https://picsum.photos/seed/${json['id'] ?? 1}/400/300',
      credits: json['credits'] is int ? json['credits'] : int.tryParse(json['credits']?.toString() ?? '') ?? 10,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? '') ?? 5.0,
      reviewCount: json['review_count'] is int ? json['review_count'] : int.tryParse(json['review_count']?.toString() ?? '') ?? 10,
      location: json['location'] ?? 'Online / Local',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? '') ?? 12.9716,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? '') ?? 77.5946,
      availability: json['availability'] ?? 'Flexible',
      experienceLevel: json['experience_level'] ?? 'Intermediate',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [rawCat.toString()],
      isAvailable: json['is_available'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_profile_image': ownerProfileImage,
      'image_url': imageUrl,
      'credits': credits,
      'rating': rating,
      'review_count': reviewCount,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'availability': availability,
      'experience_level': experienceLevel,
      'tags': tags,
      'is_available': isAvailable,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SkillModel copyWith({
    int? id,
    String? title,
    String? description,
    int? categoryId,
    String? categoryName,
    int? ownerId,
    String? ownerName,
    String? ownerProfileImage,
    String? imageUrl,
    int? credits,
    double? rating,
    int? reviewCount,
    String? location,
    double? latitude,
    double? longitude,
    String? availability,
    String? experienceLevel,
    List<String>? tags,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerProfileImage: ownerProfileImage ?? this.ownerProfileImage,
      imageUrl: imageUrl ?? this.imageUrl,
      credits: credits ?? this.credits,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availability: availability ?? this.availability,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      tags: tags ?? this.tags,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
