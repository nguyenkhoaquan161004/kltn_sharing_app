class UserDto {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? bio;
  final String? phoneNumber;
  final String? address;
  final int? trustScore; // Điểm uy tín từ API - nullable
  final int itemsShared;
  final int itemsReceived;
  final bool verified;
  final DateTime createdAt;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.bio,
    this.phoneNumber,
    this.address,
    this.trustScore,
    required this.itemsShared,
    required this.itemsReceived,
    required this.verified,
    required this.createdAt,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? username;
  }

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] ?? json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      avatar: json['avatar'] ?? json['avatarUrl'] ?? json['avatar_url'],
      bio: json['bio'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      address: json['address'],
      trustScore:
          (json['trustScore'] as int?) ?? (json['trust_score'] as int?) ?? 0,
      itemsShared: json['itemsShared'] ?? json['items_shared'] ?? 0,
      itemsReceived: json['itemsReceived'] ?? json['items_received'] ?? 0,
      verified: json['verified'] ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatar,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'address': address,
      'trustScore': trustScore,
      'itemsShared': itemsShared,
      'itemsReceived': itemsReceived,
      'verified': verified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
