class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final int credits;
  final double rating;
  final int reviewCount;
  final List<String> skills;
  final List<String> wantedSkills;
  final double? lat;
  final double? lng;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.phone,
    this.profileImageUrl,
    this.credits = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.skills = const [],
    this.wantedSkills = const [],
    this.lat,
    this.lng,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> parseSkills(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) {
          if (e is Map && e['skill'] != null && e['skill']['name'] != null) {
            return e['skill']['name'].toString();
          }
          return e.toString();
        }).toList();
      }
      return [];
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? json['title'],
      phone: json['phone'],
      profileImageUrl: json['profile_image_url'] ?? json['avatar_url'],
      credits: json['credits'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? json['reviews'] ?? 0,
      skills: parseSkills(json['skills'] ?? json['skills_offered']),
      wantedSkills: parseSkills(json['wanted_skills'] ?? json['skills_wanted']),
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }
}

class UpdateProfileRequest {
  final String? name;
  final String? bio;
  final String? phone;
  final String? avatarUrl;
  final List<String>? skills;
  final List<String>? wantedSkills;
  final double? lat;
  final double? lng;

  UpdateProfileRequest({
    this.name,
    this.bio,
    this.phone,
    this.avatarUrl,
    this.skills,
    this.wantedSkills,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (bio != null) {
      map['bio'] = bio;
      map['title'] = bio;
    }
    if (phone != null) map['phone'] = phone;
    if (avatarUrl != null) {
      map['avatar_url'] = avatarUrl;
      map['profile_image_url'] = avatarUrl;
    }
    if (skills != null) map['skills'] = skills;
    if (wantedSkills != null) map['wanted_skills'] = wantedSkills;
    if (lat != null) map['lat'] = lat;
    if (lng != null) map['lng'] = lng;
    return map;
  }
}

class UpdateProfileResponse {
  final UserProfile profile;
  final String message;

  UpdateProfileResponse({
    required this.profile,
    required this.message,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      profile: UserProfile.fromJson(json['profile'] ?? {}),
      message: json['message'] ?? 'Profile updated successfully',
    );
  }
}
