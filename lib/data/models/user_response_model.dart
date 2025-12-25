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
  final int points;
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
    required this.points,
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
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatar: json['avatar'],
      bio: json['bio'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      points: json['points'] ?? 0,
      itemsShared: json['itemsShared'] ?? 0,
      itemsReceived: json['itemsReceived'] ?? 0,
      verified: json['verified'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
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
      'points': points,
      'itemsShared': itemsShared,
      'itemsReceived': itemsReceived,
      'verified': verified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
