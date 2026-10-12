class User {
  final String id;
  final String name;
  final String title;
  final String avatarUrl;
  final double rating;
  final int reviews;
  final int xp;
  final int credits;
  final int streakDays;
  final List<String> badges;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final double distanceKm;
  final bool isOnline;
  final double? lat;
  final double? lng;

  User({
    required this.id,
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.rating,
    required this.reviews,
    required this.xp,
    required this.credits,
    required this.streakDays,
    required this.badges,
    required this.skillsOffered,
    required this.skillsWanted,
    required this.distanceKm,
    required this.isOnline,
    this.lat,
    this.lng,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      title: json['title'] ?? 'Aspiring Creator',
      avatarUrl: json['avatar_url'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      xp: json['xp'] ?? 0,
      credits: json['credits'] ?? 100,
      streakDays: json['streak_days'] ?? 0,
      badges: [],
      skillsOffered: (json['skills_offered'] as List?)
          ?.map((e) => e['skill']['name'] as String)
          .toList() ?? [],
      skillsWanted: (json['skills_wanted'] as List?)
          ?.map((e) => e['skill']['name'] as String)
          .toList() ?? [],
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      isOnline: json['is_online'] ?? false,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }
}
