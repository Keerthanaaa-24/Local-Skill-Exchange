class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final bool isGuest;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.isGuest = false,
  });

  factory User.fromJson(Map<String, dynamic> json, {bool isGuest = false}) {
    final emailVal = json['email']?.toString() ?? '';
    final guestFlag = isGuest || 
        json['is_guest'] == true || 
        emailVal.toLowerCase().contains('guest_user@localskillexchange.internal');
        
    return User(
      id: json['id']?.toString() ?? '',
      email: emailVal,
      name: json['name'] ?? '',
      profileImageUrl: json['profile_image_url'] ?? json['avatar_url'],
      isGuest: guestFlag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image_url': profileImageUrl,
      'is_guest': isGuest,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    bool? isGuest,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;
  final bool isGuest;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.isGuest = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final guestFlag = json['is_guest'] == true;
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: User.fromJson(json['user'] ?? {}, isGuest: guestFlag),
      isGuest: guestFlag,
    );
  }
}
